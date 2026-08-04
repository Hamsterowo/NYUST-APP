import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yun_tool/models/calendar_event.dart';
import 'package:yun_tool/services/scrapers/calendar_scraper.dart';
import 'package:yun_tool/utils/calendar_reminder_planner.dart';

/// 用 2022–2027 六年真實行事曆驗證中英配對。
///
/// 走的是與正式路徑同一條管線 —— 原文先經 [CalendarScraper.splitEventNames] 切分、
/// 組出與爬蟲相同的 `{項目 id}-{序號}` 識別碼，再交給
/// [CalendarReminderPlanner.pairDisplayNames]。所以這裡測到的就是使用者會看到的。
///
/// 手寫的小樣本測試在 calendar_reminder_planner_test.dart，兩者互補：那邊釘住
/// 規則的意圖，這邊釘住規則碰到真實資料時的實際成績。
List<CalendarEvent> _eventsFor(
  List<Map<String, dynamic>> rows, {
  required bool english,
}) {
  final events = <CalendarEvent>[];
  for (final row in rows) {
    final raw = (english ? row['en'] : row['zh']) as String?;
    if (raw == null) continue;
    final names = CalendarScraper.splitEventNames(raw, isEnglish: english);
    for (var i = 0; i < names.length; i++) {
      events.add(
        CalendarEvent(
          id: '${row['id']}-$i',
          date: row['date'] as String,
          name: names[i],
          link: '',
        ),
      );
    }
  }
  return events;
}

void main() {
  final fixture =
      jsonDecode(File('test/fixtures/calendar_entries.json').readAsStringSync())
          as Map<String, dynamic>;
  final byYear = fixture.map(
    (year, rows) =>
        MapEntry(year, (rows as List).cast<Map<String, dynamic>>().toList()),
  );

  /// 某幾年份的中文事件名稱 → 顯示語言名稱。
  Map<String, String> pairingFor(List<String> years) {
    final rows = [for (final y in years) ...byYear[y]!];
    final zh = _eventsFor(rows, english: false);
    final en = _eventsFor(rows, english: true);
    final byId = CalendarReminderPlanner.pairDisplayNames(zh, en);
    return {
      for (final event in zh)
        if (byId[event.id] != null) event.name: byId[event.id]!,
    };
  }

  group('真實行事曆的中英配對', () {
    test('英文把子句翻成一整句時仍配得上（2026-11-27／2027-05-14）', () {
      final paired = pairingFor(['2026', '2027']);

      expect(
        paired['學生辦休退學學雜費退1/3截止日，日後不予退費'],
        'Reimbursement of 1/3 tuition/miscellaneous fees for '
        'suspended/dropout students ends.',
      );
    });

    test('英文在頓號處切開時仍配得上（2026-08-28）', () {
      final paired = pairingFor(['2026']);

      expect(
        paired['全校學生第2次預選(網路選課)開始'],
        'The second advance course registration (Course selection online) '
        'for all students begins',
      );
      expect(
        paired['國際新生報到、國際新生宿舍入住'],
        'New international students check in, '
        'New international students check in at the dormitory.',
      );
    });

    test('三重並列也配得上（2026-08-29）', () {
      expect(
        pairingFor(['2026'])['宿舍新生入住、新生家長座談會、新生體檢'],
        'Freshman check in at the dormitory, Freshman Parent Symposium, '
        'Freshman physical examination.',
      );
    });

    test('「上課開始，註冊」仍吃掉兩個英文片段，沒有因為新的搜尋層而改變', () {
      expect(
        pairingFor(['2026'])['上課開始，註冊'],
        'Spring semester classes begins, Enrollment',
      );
    });

    test('英文版真的少列一筆事件時，整組仍退回中文（2026-02-22）', () {
      // 中文 5 筆、英文只有 4 筆 —— 學校漏譯了「國際新生宿舍入住」。任何拆法都
      // 湊不出來，結構上就是無解。這一筆要靠跨年翻譯記憶才救得回來。
      final paired = pairingFor(['2026']);

      expect(paired.containsKey('寒假結束'), isFalse);
      expect(paired.containsKey('農曆春節假期結束'), isFalse);
    });
  });

  group('會產生提醒的事件有多少配到顯示語言', () {
    /// [years] 裡命中任一提醒分類、且配到顯示語言名稱的事件數 / 總數。
    (int, int) coverage(List<String> years) {
      final rows = [for (final y in years) ...byYear[y]!];
      final zh = _eventsFor(rows, english: false);
      final byId = CalendarReminderPlanner.pairDisplayNames(
        zh,
        _eventsFor(rows, english: true),
      );

      var total = 0;
      var paired = 0;
      for (final event in zh) {
        if (!CalendarReminderPlanner.matchesAny(
          event.name,
          ReminderCategory.values.toSet(),
        )) {
          continue;
        }
        total++;
        if (byId[event.id] != null) paired++;
      }
      return (paired, total);
    }

    test('App 實際使用的兩年窗口：75 筆裡 74 筆配到英文', () {
      // 唯一的缺口是 2026-02-22「寒假結束」，見上面那個測試。
      expect(coverage(['2026', '2027']), (74, 75));
    });

    test('六年合計：279 筆裡 272 筆配到顯示語言', () {
      // 2022 年的英文頁大量未翻譯，那些條目「配到的顯示語言」其實是中文原文 ——
      // 配對本身仍然成功，這裡量的是配對率，不是翻譯率。
      //
      // 沒配到的 7 筆全是真正的無解（英文片段數在任何拆法下都湊不出中文筆數）：
      // 2023-09-08、2023-09-11、2024-02-19 共 6 筆已成過去，不會再被排程；
      // 剩下的 2026-02-22 是唯一還會影響使用者的一筆。
      expect(coverage(byYear.keys.toList()), (272, 279));
    });
  });
}
