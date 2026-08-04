import '../models/calendar_event.dart';

/// 行事曆提醒的分類，以及各分類的關鍵字比對規則。
///
/// 規則以 2025–2027 三年的真實行事曆逐條驗證過。命中任一 [includeKeywords]
/// 且不命中任何 [excludeKeywords]，才算屬於該分類 —— 比對前一律先經過
/// [CalendarReminderPlanner.normalizeName]。
///
/// 排除詞是為了處理「字面上像、實際上不是」的事件：
/// - [exam] 排掉 `退選`，`期中考後停修(退選)截止` 屬於選課而不是考試。
/// - [registration] 排掉 `減免`，學雜費減免各梯次不是繳費期限；注意排除的是
///   `減免` 而不是 `免`，`學生辦休退學免學雜費截止日` 仍算註冊繳費。
///
/// 注意行事曆裡**沒有「期末考」這個字串** —— 期末考在行事曆上寫作「學期考試」。
enum ReminderCategory {
  courseSelection(includeKeywords: ['預選', '加退選', '退選'], excludeKeywords: []),
  exam(includeKeywords: ['期中考', '學期考試'], excludeKeywords: ['退選']),
  registration(
    includeKeywords: ['註冊', '學雜費', '就學貸款', '退費'],
    excludeKeywords: ['減免'],
  ),
  semester(
    includeKeywords: ['學期開始', '學期結束', '上課開始', '寒假', '暑假'],
    excludeKeywords: [],
  );

  const ReminderCategory({
    required this.includeKeywords,
    required this.excludeKeywords,
  });

  final List<String> includeKeywords;
  final List<String> excludeKeywords;

  /// [normalizedName] 必須已經過 [CalendarReminderPlanner.normalizeName]。
  bool matches(String normalizedName) {
    for (final exclude in excludeKeywords) {
      if (normalizedName.contains(exclude)) return false;
    }
    for (final include in includeKeywords) {
      if (normalizedName.contains(include)) return true;
    }
    return false;
  }
}

/// 一筆提醒設定：事件日往前 [daysBefore] 天的 [hour]:[minute]。
///
/// [daysBefore] 為 0 表示事件當天。這是全域設定，四個分類共用同一組。
class ReminderRule {
  const ReminderRule({
    required this.daysBefore,
    required this.hour,
    required this.minute,
  });

  final int daysBefore;
  final int hour;
  final int minute;

  /// 使用者打開分類就能直接用的預設值，不必先自己設一筆提醒。
  static const defaultRule = ReminderRule(daysBefore: 1, hour: 8, minute: 0);

  /// 提前天數不能是負的（那是事件之後），時刻必須落在一天之內。
  bool get isValid =>
      daysBefore >= 0 && hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;

  Map<String, dynamic> toJson() => {
    'daysBefore': daysBefore,
    'hour': hour,
    'minute': minute,
  };

  factory ReminderRule.fromJson(Map<String, dynamic> json) => ReminderRule(
    daysBefore: (json['daysBefore'] as num?)?.toInt() ?? 0,
    hour: (json['hour'] as num?)?.toInt() ?? 0,
    minute: (json['minute'] as num?)?.toInt() ?? 0,
  );

  /// 正規化一份提醒清單：丟掉無效的、去重，並由遠到近排序。
  ///
  /// 去重是必要的而不是整潔：兩筆相同的提醒會算出**同一個通知 id**，排第二次
  /// 只會覆蓋第一次，看起來像其中一筆憑空消失。
  static List<ReminderRule> normalizeList(Iterable<ReminderRule> rules) {
    final unique = rules.where((r) => r.isValid).toSet().toList();
    unique.sort((a, b) {
      final byDays = b.daysBefore.compareTo(a.daysBefore);
      if (byDays != 0) return byDays;
      final byHour = a.hour.compareTo(b.hour);
      return byHour != 0 ? byHour : a.minute.compareTo(b.minute);
    });
    return unique;
  }

  @override
  bool operator ==(Object other) =>
      other is ReminderRule &&
      other.daysBefore == daysBefore &&
      other.hour == hour &&
      other.minute == minute;

  @override
  int get hashCode => Object.hash(daysBefore, hour, minute);

  @override
  String toString() => 'ReminderRule(D-$daysBefore $hour:$minute)';
}

/// 一則排定要發出的通知：某個事件日、該日的所有事件、以及觸發時刻。
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.triggerTime,
    required this.eventDate,
    required this.daysBefore,
    required this.eventNames,
  });

  /// 系統排程用的通知 id，由事件日期與提醒設定決定性計算而來（見
  /// [CalendarReminderPlanner.notificationIdFor]）。
  final int id;

  /// 通知要發出的當地時刻。
  final DateTime triggerTime;

  /// 這些事件所在的日期（當地時間的當天零時）。
  final DateTime eventDate;

  /// 提前幾天；0 表示事件當天。
  final int daysBefore;

  /// 該日的事件名稱，已是顯示語言，順序與行事曆一致。
  final List<String> eventNames;

  @override
  String toString() =>
      'PlannedReminder(#$id at $triggerTime, D-$daysBefore, $eventNames)';
}

/// 把「行事曆事件 + 訂閱設定 + 現在時間」算成「該排哪些通知、什麼時候發、內容
/// 是什麼」的純函式模組。
///
/// 這一層集中了整個提醒功能所有會判斷錯的東西 —— 關鍵字比對、分類歸屬、同日
/// 合併、去重、過期跳過、排序截斷、通知 id、中英名稱配對 —— 也因此是唯一的
/// 測試接縫；外層（抓行事曆、呼叫通知外掛、儲存設定、UI）都是無邏輯的膠水。
class CalendarReminderPlanner {
  CalendarReminderPlanner._();

  /// 全形標點轉半形。只用於關鍵字比對，不影響顯示的名稱。
  ///
  /// 行事曆同一個事件在不同年度的寫法會漂移（`截止(含校際選課)` 與
  /// `截止（含校際選課）` 並存、`學雜費 減免` 中間多一個空白），正規化後才能
  /// 用同一組關鍵字比對到。
  static const Map<String, String> _fullWidthPunctuation = {
    '（': '(',
    '）': ')',
    '「': '｢',
    '」': '｣',
    '，': ',',
    '、': '､',
  };

  static final RegExp _whitespace = RegExp(r'\s');

  /// 正規化事件名稱：全形括號、引號、逗號、頓號轉半形，並移除所有空白字元。
  static String normalizeName(String name) {
    final buffer = StringBuffer();
    for (final rune in name.runes) {
      final char = String.fromCharCode(rune);
      if (_whitespace.hasMatch(char)) continue;
      buffer.write(_fullWidthPunctuation[char] ?? char);
    }
    return buffer.toString();
  }

  /// 這個事件是否命中 [categories] 其中任一分類。
  static bool matchesAny(String name, Set<ReminderCategory> categories) {
    if (categories.isEmpty) return false;
    final normalized = normalizeName(name);
    return categories.any((c) => c.matches(normalized));
  }

  /// 把顯示語言的事件名稱配對到中文事件的識別碼上。
  ///
  /// 識別碼是 `{行事曆項目 id}-{子事件序號}`，序號由爬蟲切分子事件時產生 ——
  /// 而**兩種語言用的分隔符不一樣**：中文以 `；` 分隔，英文以 `, ` 分隔。多數
  /// 情況兩邊切出來的筆數剛好一致，逐筆比序號也就看似可行；但只要某一筆中文
  /// 子事件內部又含一個 `，`（例如「上課開始，註冊」），英文那一刀也會切下去，
  /// 於是該項目底下從那裡開始整排序號錯開一格 —— 配出來的是**前一個事件的
  /// 翻譯**，而不是配不到。逐筆比對擋得住「配不到」，擋不住「配錯」。
  ///
  /// 所以這裡照結構配：中文每一筆該吃掉幾個英文片段，由它內部的並列符號決定。
  /// 問題是**沒有任何一條標點規則是對的** —— 決定切不切的是語意，不是標點：
  /// - 「上課開始，註冊」英文切成兩段，但「…截止日，日後不予退費」翻成一整句沒切
  /// - 「輔系、雙主修、抵免申請」英文不切，但「國際新生報到、國際新生宿舍入住」切了
  ///
  /// 所以分兩層。第一層是固定規則「`，` 算切分點、`、` 不算」，它在「上課開始，
  /// 註冊」那幾天是對的，必須保留。第一層加總對不起來時才進第二層：把每一筆的
  /// 寬度放寬成 `1` 到「內部並列符號數 + 1」的區間，窮舉所有加總得起來的組合，
  /// **只有恰好一組可行時才採用**。
  ///
  /// 多組或無解一律沿用中文原名 —— 寧可顯示中文，也不要顯示錯的英文，因為使用者
  /// 看不出後者是錯的。這也是 2026-02-22 那種「英文版真的少列一筆事件」的下場：
  /// 中文 5 筆對英文 4 筆，怎麼拆都湊不出來，結構上就是無解。
  static Map<String, String> pairDisplayNames(
    List<CalendarEvent> events,
    List<CalendarEvent>? displayEvents,
  ) {
    if (displayEvents == null || displayEvents.isEmpty) return const {};

    final zhGroups = _groupById(events);
    final displayGroups = _groupById(displayEvents);

    final paired = <String, String>{};
    zhGroups.forEach((groupId, zhItems) {
      final displayItems = displayGroups[groupId];
      if (displayItems == null) return;

      final widths = _resolveWidths(zhItems, displayItems.length);
      if (widths == null) return;

      var cursor = 0;
      for (var i = 0; i < zhItems.length; i++) {
        // 用 ', ' 接回去，還原爬蟲切開前的原文。
        paired[zhItems[i].id] = displayItems
            .sublist(cursor, cursor + widths[i])
            .map((e) => e.name)
            .join(', ');
        cursor += widths[i];
      }
    });
    return paired;
  }

  /// 決定 [zhItems] 每一筆該吃掉幾個顯示語言片段，總數必須剛好是 [total]。
  /// 決定不了就回 `null`，呼叫端據此整組沿用中文。
  static List<int>? _resolveWidths(List<CalendarEvent> zhItems, int total) {
    final fixed = [for (final e in zhItems) _countOf(e.name, '，') + 1];
    if (fixed.fold(0, (sum, w) => sum + w) == total) return fixed;

    return _uniqueDecomposition([
      for (final e in zhItems)
        1 + _countOf(e.name, '，') + _countOf(e.name, '、'),
    ], total);
  }

  static int _countOf(String text, String pattern) =>
      pattern.allMatches(text).length;

  /// 把 [total] 拆成一串各自落在 `1..maxWidths[i]` 的寬度；**恰好一種**拆法時
  /// 回傳它，零種或多於一種都回 `null`。
  ///
  /// 找到第二組就收手 —— 這裡要的不是所有解，而是「解唯一嗎」這個是非題。
  /// 搜尋空間本來就小：六年真實行事曆裡組合數最多的一天是 24 組。
  static List<int>? _uniqueDecomposition(List<int> maxWidths, int total) {
    final current = List<int>.filled(maxWidths.length, 1);
    List<int>? only;
    var solutions = 0;

    void search(int index, int remaining) {
      if (index == maxWidths.length) {
        if (remaining != 0) return;
        solutions++;
        if (solutions == 1) only = List<int>.of(current);
        return;
      }

      // 後面每一筆至少還要吃掉一個片段，留不出來就不必再往上加。
      final reserved = maxWidths.length - index - 1;
      for (var w = 1; w <= maxWidths[index]; w++) {
        if (remaining - w < reserved) break;
        current[index] = w;
        search(index + 1, remaining - w);
        if (solutions > 1) return;
      }
    }

    search(0, total);
    return solutions == 1 ? only : null;
  }

  /// 依識別碼的項目部分分組，組內按子事件序號排序；重複的識別碼只留第一筆。
  static Map<String, List<CalendarEvent>> _groupById(
    List<CalendarEvent> events,
  ) {
    final seen = <String>{};
    final groups = <String, List<CalendarEvent>>{};
    for (final event in events) {
      if (!seen.add(event.id)) continue;
      groups.putIfAbsent(_groupIdOf(event.id), () => []).add(event);
    }
    for (final items in groups.values) {
      items.sort((a, b) => _subIndexOf(a.id).compareTo(_subIndexOf(b.id)));
    }
    return groups;
  }

  static String _groupIdOf(String id) {
    final dash = id.lastIndexOf('-');
    return dash <= 0 ? id : id.substring(0, dash);
  }

  static int _subIndexOf(String id) {
    final dash = id.lastIndexOf('-');
    return dash < 0 ? 0 : int.tryParse(id.substring(dash + 1)) ?? 0;
  }

  /// 行事曆提醒專用的通知 id 區間起點。
  ///
  /// 成績通知用時間戳當 id，散佈在整個 32 位元正整數空間；把行事曆提醒收進一段
  /// 可辨識的區間，log 與 pending 清單一眼就看得出是哪一類的排程。
  static const int idNamespace = 0x40000000;
  static const int _idMask = 0x0FFFFFFF;

  /// 由事件日期與提醒設定決定性計算通知 id：同樣的輸入必得同樣的 id，
  /// 重排時才能正確取消舊排程。
  static int notificationIdFor(DateTime eventDate, ReminderRule rule) {
    final key =
        '${_dateKey(eventDate)}|${rule.daysBefore}|${rule.hour}|${rule.minute}';
    // FNV-1a 32-bit。選它是因為實作短、無外部相依，且結果與平台無關
    // （Dart 的 String.hashCode 不保證跨版本／跨執行穩定，不能拿來當持久 id）。
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return idNamespace | (hash & _idMask);
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// 規劃出所有該排入系統的通知。
  ///
  /// [events] 是**中文**行事曆 —— 分類判斷一律以它為準，與 UI 語言無關：中文版
  /// 是這份資料的正本，英文是翻譯產物，拿翻譯當判斷依據等於把可靠度往下押一層。
  /// [displayEvents] 是顯示語言的同一份行事曆（UI 為中文時傳 null 即可）；顯示
  /// 用的名稱以事件識別碼配對，配不到就沿用中文原名。
  ///
  /// [now] 由呼叫端傳入（而非在內部讀時鐘），讓這個模組保持純函式、可測試。
  /// 觸發時間不在 [now] 之後的提醒一律不產出，也不補發。
  ///
  /// 結果依觸發時間由近到遠排序，並截斷到 [limit] 則。
  static List<PlannedReminder> plan({
    required List<CalendarEvent> events,
    required Set<ReminderCategory> categories,
    required List<ReminderRule> rules,
    required DateTime now,
    required int limit,
    List<CalendarEvent>? displayEvents,
  }) {
    if (categories.isEmpty || rules.isEmpty || limit <= 0) return const [];

    final validRules = rules.where((r) => r.isValid).toList();
    if (validRules.isEmpty) return const [];

    final displayNames = pairDisplayNames(events, displayEvents);

    // 同一天合併成一則通知。同一個事件即使同時命中多個分類也只會進來一次
    // （這裡只問「有沒有命中任一已訂閱分類」，不逐分類展開）；行事曆本身重複
    // 出現的同一 id 也在此去重。
    final byDate = <String, List<String>>{};
    final seenIds = <String>{};
    for (final event in events) {
      if (!seenIds.add(event.id)) continue;
      if (!matchesAny(event.name, categories)) continue;
      byDate
          .putIfAbsent(event.date, () => [])
          .add(displayNames[event.id] ?? event.name);
    }

    final planned = <PlannedReminder>[];
    for (final entry in byDate.entries) {
      final DateTime eventDate;
      try {
        final parsed = DateTime.parse(entry.key);
        eventDate = DateTime(parsed.year, parsed.month, parsed.day);
      } catch (_) {
        continue; // 日期壞掉的事件靜默跳過，不讓整批排程失敗。
      }

      for (final rule in validRules) {
        // 用 DateTime 建構子做日期加減（而非 Duration）：跨月、跨年與日光節約
        // 時間的換算交給它處理，減出來的時刻才會是預期的當地牆上時間。
        final trigger = DateTime(
          eventDate.year,
          eventDate.month,
          eventDate.day - rule.daysBefore,
          rule.hour,
          rule.minute,
        );
        if (!trigger.isAfter(now)) continue;

        planned.add(
          PlannedReminder(
            id: notificationIdFor(eventDate, rule),
            triggerTime: trigger,
            eventDate: eventDate,
            daysBefore: rule.daysBefore,
            eventNames: List.unmodifiable(entry.value),
          ),
        );
      }
    }

    // 同一時刻可能同時排到兩則（例如 9/10 的 D-7 與 9/4 的 D-1）；以 id 當
    // 次要鍵，讓相同輸入永遠得到相同順序，截斷後的結果才是決定性的。
    planned.sort((a, b) {
      final byTime = a.triggerTime.compareTo(b.triggerTime);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });

    return planned.length > limit ? planned.sublist(0, limit) : planned;
  }
}
