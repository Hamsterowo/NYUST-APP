import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yun_tool/services/scrapers/calendar_scraper.dart';

/// `test/fixtures/calendar_entries.json` —— 2022–2027 六年學校行事曆的真實原文，
/// 每筆保留識別碼、日期、中文原文、英文原文（未切分）。
///
/// 收原文而不是整份網頁：切分規則的正確性論證需要六年份的真實寫法，但六份 HTML
/// 近 500KB，其中絕大多數是版型。抽成原文後約 160KB，且測試不必再解 HTML。
Map<String, List<Map<String, dynamic>>> _loadEntries() {
  final raw =
      jsonDecode(File('test/fixtures/calendar_entries.json').readAsStringSync())
          as Map<String, dynamic>;
  return raw.map(
    (year, rows) =>
        MapEntry(year, (rows as List).cast<Map<String, dynamic>>().toList()),
  );
}

/// 修正前的英文切分規則，只在測試裡留一份，用於證明新規則是嚴格改善。
final _previousSeparator = RegExp(', \\s*(?=[A-Z\u4e00-\u9fa5])');

List<String> _splitWithPreviousRule(String name) => [
  for (final entry
      in name.split('；').map((n) => n.trim()).where((n) => n.isNotEmpty))
    ...entry
        .split(_previousSeparator)
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty),
];

/// 只留下文字本身，丟掉所有標點與空白。
///
/// 切分只會吃掉分隔符（逗號、句點、空白），所以切分前後用同一把尺刮掉這些字元，
/// 剩下的內容必須一字不差 —— 這就是「沒有漏字、也沒有重複」的精確判準。
String _contentOnly(String s) =>
    s.replaceAll(RegExp(r'[^0-9A-Za-z\u4e00-\u9fa5]'), '');

void main() {
  final entries = _loadEntries();
  final allRows = [for (final rows in entries.values) ...rows];

  Map<String, dynamic> rowOn(String date) =>
      allRows.firstWhere((r) => r['date'] == date);

  group('CalendarScraper.splitEventNames — 中文', () {
    test('只以全形分號切分', () {
      expect(
        CalendarScraper.splitEventNames(
          '第2學期結束；博士、碩士學位考試結束；英檢提報結束',
          isEnglish: false,
        ),
        ['第2學期結束', '博士、碩士學位考試結束', '英檢提報結束'],
      );
    });

    test('全形逗號與頓號都不是切分點', () {
      expect(
        CalendarScraper.splitEventNames(
          '學生辦休退學學雜費退1/3截止日，日後不予退費',
          isEnglish: false,
        ),
        ['學生辦休退學學雜費退1/3截止日，日後不予退費'],
      );
      expect(
        CalendarScraper.splitEventNames('國際新生報到、國際新生宿舍入住', isEnglish: false),
        ['國際新生報到、國際新生宿舍入住'],
      );
    });
  });

  group('CalendarScraper.splitEventNames — 英文', () {
    test('逗號後沒有空格也要斷開（2023 年整年的寫法）', () {
      final pieces = CalendarScraper.splitEventNames(
        rowOn('2023-02-13')['en'] as String,
        isEnglish: true,
      );

      expect(pieces, hasLength(2));
      expect(pieces.first, endsWith('(for all students)'));
      expect(pieces.last, startsWith('Application for tuition'));
    });

    test('句點直接黏住下一句時要斷開', () {
      final pieces = CalendarScraper.splitEventNames(
        rowOn('2027-07-31')['en'] as String,
        isEnglish: true,
      );

      expect(pieces, hasLength(4));
      expect(
        pieces[2],
        'Voting for outstanding teaching & excellent teacher ends',
      );
      expect(pieces[3], 'Reporting/uploading of GEPT/TOEIC scores ends.');
    });

    test('逗號後接學年度前綴要斷開', () {
      final pieces = CalendarScraper.splitEventNames(
        rowOn('2025-01-13')['en'] as String,
        isEnglish: true,
      );

      expect(pieces, hasLength(2));
      expect(pieces.first, 'Winter vacation begins');
      expect(pieces.last, startsWith('113-2 The application'));
    });

    test('逗號後接一般數字不切 —— 那是日期，不是事件邊界', () {
      final en = rowOn('2024-01-12')['en'] as String;

      expect(en, contains('January 13, 2013 (Sat)'));
      expect(
        CalendarScraper.splitEventNames(en, isEnglish: true),
        hasLength(1),
      );
    });

    test('整格結尾多打的逗號不會留在事件名稱上', () {
      // 學校在 2026-09-07 那一格的結尾多打了一個逗號。中文那邊結尾的 ；被切分
      // 吃掉了，英文的逗號沒有 —— 留著的話通知裡會長成
      // `On-line course add/drop begins, / Delivery of...`，像兩個事件黏在一起。
      final en = rowOn('2026-09-07')['en'] as String;

      expect(en, endsWith('begins,'));
      expect(
        CalendarScraper.splitEventNames(en, isEnglish: true).last,
        'On-line course add/drop begins',
      );
    });

    test('句尾的句點是句子的一部分，不能刮掉', () {
      expect(
        CalendarScraper.splitEventNames(
          'Midterm examinations begins.',
          isEnglish: true,
        ),
        ['Midterm examinations begins.'],
      );
    });

    test('名稱內部的並列不切（逗號＋空格＋小寫）', () {
      expect(
        CalendarScraper.splitEventNames(
          'Application for minor/double majors, credit waivers, and transference '
          '(including English/Mandarin) begins',
          isEnglish: true,
        ),
        hasLength(1),
      );
    });
  });

  group('六年真實行事曆的整體性質', () {
    test('2024 年起的英文版從不使用全形分號 —— 英文只能靠逗號判斷邊界', () {
      for (final year in entries.keys.where((y) => int.parse(y) >= 2024)) {
        for (final row in entries[year]!) {
          final en = row['en'] as String?;
          if (en == null) continue;
          expect(en, isNot(contains('；')), reason: '${row['date']}');
        }
      }
    });

    test('未翻譯的舊條目退回中文原文，仍以全形分號正確切分', () {
      // 2022 年的英文頁有大量條目根本沒翻譯，直接回傳中文原文（130 筆裡 79 筆
      // 連一個拉丁字母都沒有）。2023 剩 1 筆，2024 起歸零。這種條目走英文路徑
      // 時不能被逗號規則搞壞 —— 它的分隔符仍然是全形分號。
      final untranslated = entries['2022']!
          .where((r) => r['en'] != null && (r['en'] as String).contains('；'))
          .toList();
      expect(untranslated, hasLength(34));

      final row = untranslated.firstWhere((r) => r['date'] == '2022-01-01');
      expect(
        CalendarScraper.splitEventNames(row['en'] as String, isEnglish: true),
        ['開國紀念日', '研究生指導教授提報系統開放'],
      );
    });

    test('新規則相對舊規則是嚴格改善：只多切，不改變既有結果', () {
      var extraPieces = 0;

      for (final row in allRows) {
        final en = row['en'] as String?;
        if (en == null) continue;

        final before = _splitWithPreviousRule(en);
        final after = CalendarScraper.splitEventNames(en, isEnglish: true);
        final where = '${row['date']} (id=${row['id']})';

        // 只會切得更細，不會把原本分開的併回去。
        expect(
          after.length,
          greaterThanOrEqualTo(before.length),
          reason: '$where 的事件數變少了',
        );

        // 內容一字不差 —— 沒有漏掉半句，也沒有重複。
        expect(
          _contentOnly(after.join()),
          _contentOnly(before.join()),
          reason: '$where 的內容在切分後改變了',
        );

        // 每一個新片段都落在某個舊片段之內：新規則只是在舊片段內部再下刀，
        // 不會產生跨越舊邊界的片段。
        var cursor = 0;
        for (final oldPiece in before) {
          final consumed = <String>[];
          while (cursor < after.length && oldPiece.contains(after[cursor])) {
            consumed.add(after[cursor]);
            cursor++;
          }
          expect(consumed, isNotEmpty, reason: '$where 的舊片段沒有對應的新片段');
        }
        expect(cursor, after.length, reason: '$where 有新片段跨越了舊邊界');

        extraPieces += after.length - before.length;
      }

      // 六年份的總增量。fixture 是凍結的，所以這是個確定的數字 —— 改動切分規則
      // 時它會變，那正是應該被看見、被重新驗證的時候。
      expect(extraPieces, 175);
    });
  });
}
