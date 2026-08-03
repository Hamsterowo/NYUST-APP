import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/calendar_event.dart';
import '../utils/calendar_reminder_planner.dart';
import 'api_service.dart';
import 'calendar_cache_service.dart';
import 'notification_channel.dart';
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
  static const _scheduledIdsKey = 'calendar_reminder_scheduled_ids';

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

  /// 目前的提醒清單。
  ///
  /// 此階段固定為「前 1 天 08:00」，尚不提供自訂（那是後續的自訂提醒清單）。
  static Future<List<ReminderRule>> loadRules() async => const [
    ReminderRule.defaultRule,
  ];

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

  /// 取消所有既有排程，再依目前設定重新排入。
  ///
  /// 取消的是「上次排進去的那些 id」而不是 `cancelAll()` —— 後者會連帶清掉
  /// 成績通知已經顯示在通知欄的內容。
  static Future<void> reschedule(AppLocalizations l10n) async {
    if (!isSupported) return;

    await _cancelScheduled();

    final categories = await loadCategories();
    final rules = await loadRules();
    if (categories.isEmpty || rules.isEmpty) return;

    final events = await _loadClassificationEvents();
    if (events.isEmpty) return;

    final planned = CalendarReminderPlanner.plan(
      events: events,
      categories: categories,
      rules: rules,
      now: ServerTimeService.instance.now(),
      limit: scheduleLimit,
    );

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

    if (kDebugMode) {
      print('CalendarReminderService: scheduled ${planned.length} reminders');
    }
  }

  static Future<void> _schedule(
    PlannedReminder reminder,
    AppLocalizations l10n,
  ) async {
    final channel = NotificationChannelSpec.calendarReminders(l10n);
    final body = reminder.eventNames.join('\n');

    await NotificationService().zonedSchedule(
      id: reminder.id,
      title: l10n.notificationChannelCalendarName,
      body: body,
      scheduledDate: reminder.triggerTime,
      channel: channel,
    );
  }

  // -------------------------------------------------------------- 除錯

  /// 除錯用：依目前設定重算一次規劃結果，不排程、不改動任何狀態。
  static Future<List<PlannedReminder>> debugPlan() async {
    final categories = await loadCategories();
    final rules = await loadRules();
    if (categories.isEmpty || rules.isEmpty) return const [];

    return CalendarReminderPlanner.plan(
      events: await _loadClassificationEvents(),
      categories: categories,
      rules: rules,
      now: ServerTimeService.instance.now(),
      limit: scheduleLimit,
    );
  }

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

  /// 除錯用的固定 id，落在行事曆提醒的區間尾端。
  ///
  /// 不進追蹤清單，所以 [reschedule] 不會把它取消掉 —— 重開機驗證要的就是
  /// 「排下去之後不再碰它」。
  static const int debugTestId =
      CalendarReminderPlanner.idNamespace | 0x0FFFFFFF;

  /// 除錯用：[delay] 之後發一則內容固定的行事曆提醒。
  static Future<void> debugScheduleTest(
    AppLocalizations l10n,
    Duration delay,
  ) async {
    await NotificationService().ensureChannel(
      NotificationChannelSpec.calendarReminders(l10n),
    );
    await NotificationService().zonedSchedule(
      id: debugTestId,
      title: l10n.calendarReminderTitle,
      body: 'debug test · ${DateTime.now().add(delay)}',
      scheduledDate: DateTime.now().add(delay),
      channel: NotificationChannelSpec.calendarReminders(l10n),
    );
  }

  // --------------------------------------------------------- 行事曆資料

  /// 取分類判斷用的行事曆事件。
  ///
  /// 一律取**中文**版，與目前 UI 語言無關：中文版是這份資料的正本，英文是翻譯
  /// 產物。走既有的行事曆快取層（[CalendarCacheService]），不另開第二套抓取邏輯。
  static Future<List<CalendarEvent>> _loadClassificationEvents() async {
    final year = ServerTimeService.instance.now().year;
    return _loadYear(year);
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
      // 抓不到行事曆就不排程，但既有的排程不受影響（已在 reschedule 前取消，
      // 這一趟就是空的）。下次進 App 會再試一次。
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
