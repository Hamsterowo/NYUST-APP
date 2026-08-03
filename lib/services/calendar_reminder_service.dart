import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/calendar_event.dart';
import '../utils/calendar_reminder_planner.dart';
import 'api_service.dart';
import 'calendar_cache_service.dart';
import 'calendar_reminder_notification_text.dart';
import 'notification_channel.dart';
import 'notification_payload.dart';
import 'notification_service.dart';
import 'server_time_service.dart';

/// 設定分類訂閱的結果。
enum CalendarReminderResult {
  /// 已套用（開啟或關閉皆是）。
  applied,

  /// 使用者拒絕通知權限，未啟用。
  permissionDenied,
}

/// 行事曆提醒的排程與設定。
///
/// 這一層刻意保持無邏輯：所有判斷（哪些事件要提醒、何時發、內容是什麼）都在
/// [CalendarReminderPlanner]，這裡只負責讀設定、取行事曆、把結果交給通知外掛。
///
/// 排程走**本地預先排程**而不是背景輪詢：行事曆是一年才變一次的靜態資料，用
/// 輪詢去追不會動的東西是錯的抽象，而且 workmanager 在 Android 上的實際延遲
/// 可達數小時，對「早上八點提醒」這種需求沒有意義。
class CalendarReminderService {
  CalendarReminderService._();

  static const _categoriesKey = 'calendar_reminder_categories';
  static const _rulesKey = 'calendar_reminder_rules';
  static const _scheduledIdsKey = 'calendar_reminder_scheduled_ids';
  static const _fingerprintKey = 'calendar_reminder_fingerprint';

  /// 一次最多排入系統的通知數。
  ///
  /// iOS 的待發本地通知上限是 64 則，超過的會被系統默默丟掉；Android 沒有這麼
  /// 硬的限制但 alarm 也不是免費的。取兩者的下限，行為在兩個平台上一致。
  static const int scheduleLimit = 64;

  /// 這個平台是否支援行事曆提醒。
  ///
  /// 依「有沒有本地通知排程」而不是「是不是 Android」判斷 —— iOS 之後上架就
  /// 要用，寫死排除它等於埋一個到時候找不到的開關。
  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  // ---------------------------------------------------------------- 設定

  /// 目前已訂閱的分類。預設全部關閉。
  static Future<Set<ReminderCategory>> loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final names = prefs.getStringList(_categoriesKey) ?? const [];
      return names
          .map(
            (n) =>
                ReminderCategory.values.where((c) => c.name == n).firstOrNull,
          )
          .nonNulls
          .toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveCategories(Set<ReminderCategory> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _categoriesKey,
        categories.map((c) => c.name).toList(),
      );
    } catch (_) {}
  }

  /// 目前的提醒清單。四個分類共用同一組。
  ///
  /// 分類開關已經表達了「我在意什麼」，提醒密度是另一個獨立偏好（「我是健忘的
  /// 人」）；兩者交叉相乘會讓設定成本與狀態複雜度都翻好幾倍，所以不做每分類
  /// 各一組。
  static Future<List<ReminderRule>> loadRules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_rulesKey);
      if (raw == null) return const [ReminderRule.defaultRule];

      return _atLeastOne(
        ReminderRule.normalizeList(
          (jsonDecode(raw) as List).map(
            (e) => ReminderRule.fromJson(e as Map<String, dynamic>),
          ),
        ),
      );
    } catch (_) {
      return const [ReminderRule.defaultRule];
    }
  }

  /// 換掉整份提醒清單並立即重排。
  static Future<void> setRules(
    List<ReminderRule> rules,
    AppLocalizations l10n,
  ) async {
    final normalized = _atLeastOne(ReminderRule.normalizeList(rules));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _rulesKey,
        jsonEncode(normalized.map((r) => r.toJson()).toList()),
      );
    } catch (_) {}
    await reschedule(l10n);
  }

  /// 清單至少保留一筆提醒。
  ///
  /// 空清單的分類開關會全部亮著卻永遠不發通知 —— 那個狀態看起來像壞掉而不像
  /// 設定。要完全靜音就把分類關掉，那才是表達「我不想被提醒」的地方。
  /// 設定頁擋住刪到最後一筆，這裡再擋一次舊資料與程式化呼叫。
  static List<ReminderRule> _atLeastOne(List<ReminderRule> rules) =>
      rules.isEmpty ? const [ReminderRule.defaultRule] : rules;

  // ------------------------------------------------------------ 分類開關

  /// 開啟或關閉一個分類，並立即重排。
  ///
  /// 開啟時會先請求通知權限；被拒則不改變狀態、回傳
  /// [CalendarReminderResult.permissionDenied] 讓呼叫端顯示提示。
  static Future<CalendarReminderResult> setCategoryEnabled(
    ReminderCategory category,
    bool enabled,
    AppLocalizations l10n,
  ) async {
    final current = await loadCategories();

    if (enabled) {
      // 每次開啟都問一次，而不是只問第一次：權限已授予時系統直接回 true、不會
      // 跳任何視窗，但使用者若中途去系統設定關掉通知，這裡才擋得下來 —— 只問
      // 第一次的話，之後開啟的分類會靜靜地排一堆永遠不會出現的通知。
      final granted = await NotificationService().requestPermissions();
      if (!granted) return CalendarReminderResult.permissionDenied;
      // 權限剛拿到就把 channel 建起來，使用者馬上就能在系統通知設定裡找到
      // 「行事曆提醒」並單獨調整它，不必等第一則通知發出。
      await NotificationService().ensureChannel(
        NotificationChannelSpec.calendarReminders(l10n),
      );
    }

    final next = {...current};
    if (enabled) {
      next.add(category);
    } else {
      next.remove(category);
    }
    await _saveCategories(next);
    await reschedule(l10n);

    return CalendarReminderResult.applied;
  }

  // -------------------------------------------------------------- 排程

  /// 依目前設定重排，不論內容有沒有變。設定頁改動後走這一條。
  static Future<void> reschedule(AppLocalizations l10n) async {
    if (!isSupported) return;

    final planned = await _buildPlan(l10n);
    if (planned == null) return; // 取不到行事曆，保留既有排程。
    await _apply(planned, l10n);
  }

  /// 只有在「排出來的東西會不一樣」時才重排。App 進前景時走這一條。
  ///
  /// 行事曆一年才變一次，每次開 App 都把排程翻一遍是白工；而且取消與重新排入
  /// 之間真的有一段空窗，那段時間鬧鐘不在系統裡。所以先比指紋，一樣就不動。
  static Future<void> refreshIfNeeded(AppLocalizations l10n) async {
    if (!isSupported) return;

    final planned = await _buildPlan(l10n);
    if (planned == null) return; // 取不到行事曆，保留既有排程。

    if (await _fingerprint(planned, l10n) == await _loadFingerprint()) return;

    if (kDebugMode) {
      print('CalendarReminderService: schedule changed, reapplying');
    }
    await _apply(planned, l10n);
  }

  /// 算出這一刻該排哪些通知。
  ///
  /// 回傳 `null` 表示**取不到行事曆**（離線、學校網站掛了）—— 那不代表既有的
  /// 提醒不該發，只代表這一趟沒有新資料可以算，呼叫端應該原封不動地放著。
  /// 回傳空清單則是真的沒東西要排（沒訂閱任何分類）。
  static Future<List<PlannedReminder>?> _buildPlan(
    AppLocalizations l10n,
  ) async {
    final categories = await loadCategories();
    if (categories.isEmpty) return const [];

    final events = await _loadClassificationEvents();
    if (events.isEmpty) {
      if (kDebugMode) {
        print(
          'CalendarReminderService: no calendar data, keeping existing schedule',
        );
      }
      return null;
    }

    return CalendarReminderPlanner.plan(
      events: events,
      displayEvents: await _loadDisplayEvents(l10n.localeName),
      categories: categories,
      rules: await loadRules(),
      now: ServerTimeService.instance.now(),
      limit: scheduleLimit,
    );
  }

  /// 把一份規劃結果套進系統：取消舊的、排入新的、記下指紋。
  ///
  /// 取消的是「上次排進去的那些 id」而不是 `cancelAll()` —— 後者會連帶清掉
  /// 成績通知已經顯示在通知欄的內容。
  static Future<void> _apply(
    List<PlannedReminder> planned,
    AppLocalizations l10n,
  ) async {
    await _cancelScheduled();

    // 先記下要排哪些 id，再真的去排：中途被系統砍掉時，已排入的通知仍在追蹤
    // 清單裡、下次還取消得掉。反過來（排完才記）會留下取消不掉的孤兒排程。
    // 排失敗的 id 留在清單裡無害 —— 對沒排程的 id 呼叫 cancel 是 no-op。
    await _saveScheduledIds(planned.map((r) => r.id).toList());

    for (final reminder in planned) {
      try {
        await _schedule(reminder, l10n);
      } catch (e) {
        if (kDebugMode) {
          print('CalendarReminderService: schedule #${reminder.id} failed: $e');
        }
      }
    }

    await _saveFingerprint(await _fingerprint(planned, l10n));

    if (kDebugMode) {
      print('CalendarReminderService: scheduled ${planned.length} reminders');
    }
  }

  /// 「排進系統的東西會長什麼樣」的指紋。
  ///
  /// 指紋算的是**規劃結果**而不是原始輸入。原因是規劃會截斷到 [scheduleLimit]
  /// 則：拿行事曆內容當指紋的話，那 64 則陸續發完之後行事曆並沒有變，指紋也就
  /// 不變，剩下的事件永遠等不到空出來的名額。改用規劃結果，某一則發過去、下一
  /// 則遞補進來時指紋自然就變了。行事曆更新、分類與提醒清單變動也都會反映在
  /// 規劃結果上，不必另外列。
  ///
  /// 另外納入兩個不影響規劃、但影響「排進去的內容」的東西：顯示語言（排進系統
  /// 的是固定字串），以及通知權限（使用者可能剛去系統設定把它打開）。
  static Future<String> _fingerprint(
    List<PlannedReminder> planned,
    AppLocalizations l10n,
  ) async {
    final buffer = StringBuffer()
      ..write(l10n.localeName)
      ..write('|')
      ..write(await NotificationService().areNotificationsEnabled())
      ..write('|');
    for (final reminder in planned) {
      buffer.write(
        '${reminder.id}@${reminder.triggerTime.toIso8601String()}'
        ':${reminder.eventNames.join(',')};',
      );
    }

    // FNV-1a，與通知 id 同一套理由：String.hashCode 不保證跨版本／跨執行穩定，
    // 存起來下次比對就對不上，會變成每次開 App 都重排一輪。
    var hash = 0x811c9dc5;
    for (final unit in buffer.toString().codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  static Future<String?> _loadFingerprint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_fingerprintKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveFingerprint(String fingerprint) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fingerprintKey, fingerprint);
    } catch (_) {}
  }

  static Future<void> _schedule(
    PlannedReminder reminder,
    AppLocalizations l10n,
  ) async {
    final text = ReminderNotificationText.from(reminder, l10n);

    await NotificationService().zonedSchedule(
      id: reminder.id,
      title: text.title,
      body: text.collapsed,
      scheduledDate: reminder.triggerTime,
      channel: NotificationChannelSpec.calendarReminders(l10n),
      styleInformation: BigTextStyleInformation(text.expanded),
      subText: text.lead,
      iosSubtitle: text.lead,
      // 通知本文已經列了那天有什麼，點下去就是想看那天還有別的嗎 —— 帶上事件
      // 日期，讓行事曆直接停在那一天。
      payload: NotificationPayload(
        type: NotificationPayload.typeCalendar,
        date: reminder.eventDate,
      ).encode(),
    );
  }

  // -------------------------------------------------------------- 除錯

  /// 除錯用：依目前設定重算一次規劃結果，不排程、不改動任何狀態。
  ///
  /// 走與正式排程同一條 [_buildPlan]，看到的就是實際會排進去的那一份。
  static Future<List<PlannedReminder>> debugPlan(AppLocalizations l10n) async =>
      await _buildPlan(l10n) ?? const [];

  /// 除錯用：外掛回報的待發通知中，屬於行事曆提醒的那些 id。
  ///
  /// 這是「外掛自己記了什麼」而不是「AlarmManager 裡真的有什麼」 —— 重開機後
  /// 這份清單一定還在，所以它**不能**用來證明開機重排有效。要驗證重開機請用
  /// [debugScheduleTest] 排一則幾分鐘後的提醒，然後立刻重開機等它出現。
  static Future<List<int>> debugPendingIds() async {
    final pending = await NotificationService().pendingRequests();
    return pending
        .map((p) => p.id)
        .where(
          (id) =>
              id & CalendarReminderPlanner.idNamespace ==
              CalendarReminderPlanner.idNamespace,
        )
        .toList();
  }

  /// 除錯用的固定 id，落在行事曆提醒區間的尾端。
  ///
  /// 不進追蹤清單，所以 [reschedule] 不會把它取消掉 —— 重開機驗證要的就是
  /// 「排下去之後不再碰它」。
  static const int debugTestIdMulti =
      CalendarReminderPlanner.idNamespace | 0x0FFFFFFF;
  static const int debugTestIdSingle =
      CalendarReminderPlanner.idNamespace | 0x0FFFFFFE;

  /// 除錯用：[delay] 之後發兩則測試提醒 —— 一則多事件、一則單一事件。
  ///
  /// 刻意走與正式排程同一條 [_schedule]，所以看到的版面就是實際會發出的版面；
  /// 兩則一起發是為了讓「一天多件事」與「一天只有一件事」兩種呈現一次看完。
  static Future<void> debugScheduleTest(
    AppLocalizations l10n,
    Duration delay,
  ) async {
    await NotificationService().ensureChannel(
      NotificationChannelSpec.calendarReminders(l10n),
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await _schedule(
      PlannedReminder(
        id: debugTestIdMulti,
        triggerTime: now.add(delay),
        eventDate: today.add(const Duration(days: 1)),
        daysBefore: 1,
        eventNames: const ['上課開始', '第1學期開始', '全校加退選開始'],
      ),
      l10n,
    );
    await _schedule(
      PlannedReminder(
        id: debugTestIdSingle,
        triggerTime: now.add(delay + const Duration(seconds: 2)),
        eventDate: today.add(const Duration(days: 3)),
        daysBefore: 3,
        eventNames: const ['期中考開始'],
      ),
      l10n,
    );
  }

  // --------------------------------------------------------- 行事曆資料

  /// 取分類判斷用的行事曆事件，涵蓋**當年與次年**。
  ///
  /// 只排當年的話，空窗期正好落在寒假前後 —— 12 月時 1 月的「學期考試開始」與
  /// 「寒假開始」都排不進來，而那是行事曆最密集的時段之一。次年行事曆在年中就
  /// 已部分公告、之後會陸續補齊，搭配前景重排就會自然收斂。
  ///
  /// 一律取**中文**版，與目前 UI 語言無關：中文版是這份資料的正本，英文是翻譯
  /// 產物。走既有的行事曆快取層（[CalendarCacheService]），不另開第二套抓取邏輯。
  static Future<List<CalendarEvent>> _loadClassificationEvents() async {
    final year = ServerTimeService.instance.now().year;
    final thisYear = await _loadYear(year);
    // 當年抓不到就整趟放棄 —— 呼叫端會據此保留既有排程。若還硬帶著次年那半份
    // 資料往下走，會變成「用不完整的行事曆重排」，把當年剩下的提醒全部清掉。
    if (thisYear.isEmpty) return const [];

    // 次年不存在、為空或抓取失敗都靜默跳過，不影響當年排程。
    final nextYear = await _loadYear(year + 1);
    return [...thisYear, ...nextYear];
  }

  /// 顯示語言那一份行事曆，供通知內文使用；UI 是中文時回傳 `null`。
  ///
  /// 中文時回 `null` 而不是回中文那一份：規劃模組配不到就沿用中文原名，結果
  /// 一模一樣，多抓一次只是白費一趟請求。
  ///
  /// 抓失敗時回傳的是空清單而不是中止 —— 名稱配不到就退回中文，通知照發。
  /// 這裡刻意**不**沿用 [_loadClassificationEvents] 那條「當年抓不到就整趟放棄」
  /// 的規則：那條規則是為了分類判斷，而顯示名稱缺了只是少一層翻譯。
  static Future<List<CalendarEvent>?> _loadDisplayEvents(
    String localeName,
  ) async {
    if (!localeName.toLowerCase().startsWith('en')) return null;

    final year = ServerTimeService.instance.now().year;
    return [
      ...await _loadYear(year, lang: 'en'),
      ...await _loadYear(year + 1, lang: 'en'),
    ];
  }

  static Future<List<CalendarEvent>> _loadYear(
    int year, {
    String lang = 'zh',
  }) async {
    try {
      final data = await CalendarCacheService.getOrFetch(
        year,
        lang,
        (y, {lang}) => ApiService().getCalendar(y, lang: lang),
      );
      if (data == null) return const [];

      final List<dynamic> raw = data['events'] ?? const [];
      return raw
          .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('CalendarReminderService: load calendar $year failed: $e');
      }
      return const [];
    }
  }

  // ------------------------------------------------------ 已排程 id 追蹤

  static Future<void> _cancelScheduled() async {
    final ids = await _loadScheduledIds();
    for (final id in ids) {
      try {
        await NotificationService().cancel(id);
      } catch (_) {}
    }
    await _saveScheduledIds(const []);
  }

  static Future<List<int>> _loadScheduledIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_scheduledIdsKey);
      if (raw == null) return const [];
      return (jsonDecode(raw) as List).map((e) => (e as num).toInt()).toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> _saveScheduledIds(List<int> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_scheduledIdsKey, jsonEncode(ids));
    } catch (_) {}
  }
}
