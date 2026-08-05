import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yun_tool/models/calendar_event.dart';
import 'package:yun_tool/services/calendar_export_service.dart';
import 'package:yun_tool/utils/ics.dart';

/// DTSTAMP 固定成同一刻，輸出才是決定性的。
final _now = DateTime.utc(2026, 2, 1, 3, 4, 5);

String _build(List<IcsEvent> events) => IcsCalendar.build(events, now: _now);

/// 把折行還原回邏輯行：後續行以 CRLF + 一個空白開頭。
List<String> _unfold(String ics) =>
    ics.replaceAll('\r\n ', '').split('\r\n')..removeLast();

void main() {
  group('escapeText', () {
    test('逗號、分號、反斜線各自被跳脫', () {
      expect(IcsCalendar.escapeText('a,b'), r'a\,b');
      expect(IcsCalendar.escapeText('a;b'), r'a\;b');
      expect(IcsCalendar.escapeText(r'a\b'), r'a\\b');
    });

    test('反斜線先跳脫，不會被自己補上的那一個再跳一次', () {
      expect(IcsCalendar.escapeText(r'a\,b'), r'a\\\,b');
    });

    test('三種換行都寫成字面上的 \\n', () {
      expect(IcsCalendar.escapeText('a\nb'), r'a\nb');
      expect(IcsCalendar.escapeText('a\r\nb'), r'a\nb');
      expect(IcsCalendar.escapeText('a\rb'), r'a\nb');
    });

    test('冒號不跳脫 —— 規格沒有要求，跳了反而變成內容的一部分', () {
      expect(IcsCalendar.escapeText('http://x'), 'http://x');
    });
  });

  group('foldLine', () {
    test('75 octet 以內原樣不折', () {
      final line = 'A' * 75;
      expect(IcsCalendar.foldLine(line), line);
    });

    test('超過 75 octet 折行，後續行以一個空白開頭', () {
      final folded = IcsCalendar.foldLine('A' * 80);
      expect(folded, '${'A' * 75}\r\n ${'A' * 5}');
    });

    test('每一段（含後續行開頭的空白）都不超過 75 octet', () {
      final folded = IcsCalendar.foldLine('DESCRIPTION:${'x' * 500}');
      for (final segment in folded.split('\r\n')) {
        expect(utf8.encode(segment).length, lessThanOrEqualTo(75));
      }
    });

    test('中文照 octet 折而不是照字元折', () {
      // 每個中文字 3 octet；40 個字 = 120 octet，一定得折。
      final folded = IcsCalendar.foldLine('第' * 40);
      expect(folded.contains('\r\n '), isTrue);
      for (final segment in folded.split('\r\n')) {
        expect(utf8.encode(segment).length, lessThanOrEqualTo(75));
      }
    });

    test('不會從多位元組字元中間切開', () {
      // 74 個 ASCII 後接一個中文字：照 octet 硬切的話會切碎那個中文字。
      final folded = IcsCalendar.foldLine('${'A' * 74}期中考週');
      expect(folded, contains('期中考週'));
      // 還原後必須與原文逐字相同。
      expect(folded.replaceAll('\r\n ', ''), '${'A' * 74}期中考週');
    });
  });

  group('build（golden）', () {
    test('單一全天事件的完整輸出', () {
      final ics = _build([
        IcsEvent.allDay(
          uid: 'sample@nyust-app',
          summary: '期中考週',
          date: DateTime(2026, 4, 14),
          description: '來自雲科大學校行事曆。',
        ),
      ]);

      expect(
        ics,
        'BEGIN:VCALENDAR\r\n'
        'VERSION:2.0\r\n'
        'PRODID:-//YunTool//NYUST-APP//ZH-TW\r\n'
        'CALSCALE:GREGORIAN\r\n'
        'METHOD:PUBLISH\r\n'
        'BEGIN:VEVENT\r\n'
        'UID:sample@nyust-app\r\n'
        'DTSTAMP:20260201T030405Z\r\n'
        'DTSTART;VALUE=DATE:20260414\r\n'
        'DTEND;VALUE=DATE:20260415\r\n'
        'SUMMARY:期中考週\r\n'
        'DESCRIPTION:來自雲科大學校行事曆。\r\n'
        'END:VEVENT\r\n'
        'END:VCALENDAR\r\n',
      );
    });

    test('全天事件的 DTEND 是隔天，且跨月跨年正確', () {
      final ics = _build([
        IcsEvent.allDay(uid: 'u', summary: 's', date: DateTime(2026, 12, 31)),
      ]);
      expect(ics, contains('DTSTART;VALUE=DATE:20261231\r\n'));
      expect(ics, contains('DTEND;VALUE=DATE:20270101\r\n'));
    });

    test('有時刻的事件寫成浮動當地時間，不帶 Z 也不帶 TZID', () {
      final ics = _build([
        IcsEvent.timed(
          uid: 'u',
          summary: 's',
          start: DateTime(2026, 4, 14, 10, 10),
          end: DateTime(2026, 4, 14, 12, 0),
          location: 'EL101',
        ),
      ]);
      expect(ics, contains('DTSTART:20260414T101000\r\n'));
      expect(ics, contains('DTEND:20260414T120000\r\n'));
      expect(ics, contains('LOCATION:EL101\r\n'));
      expect(ics.contains('TZID'), isFalse);
    });

    test('空的描述與地點不產生該欄位', () {
      final ics = _build([
        IcsEvent.allDay(uid: 'u', summary: 's', date: DateTime(2026, 4, 14)),
      ]);
      expect(ics.contains('DESCRIPTION'), isFalse);
      expect(ics.contains('LOCATION'), isFalse);
    });

    test('多筆事件共用一份 VCALENDAR 外殼', () {
      final ics = _build([
        IcsEvent.allDay(uid: 'a', summary: 'A', date: DateTime(2026, 4, 14)),
        IcsEvent.allDay(uid: 'b', summary: 'B', date: DateTime(2026, 4, 15)),
      ]);
      expect('BEGIN:VEVENT'.allMatches(ics).length, 2);
      expect('BEGIN:VCALENDAR'.allMatches(ics).length, 1);
    });

    test('含半形逗號分號的描述被跳脫', () {
      final ics = _build([
        IcsEvent.allDay(
          uid: 'u',
          summary: 'Add/drop begins',
          date: DateTime(2026, 2, 17),
          description: 'Classes begin, registration; for all students',
        ),
      ]);
      final line = _unfold(ics).firstWhere((l) => l.startsWith('DESCRIPTION:'));
      expect(
        line,
        r'DESCRIPTION:Classes begin\, registration\; for all students',
      );
    });

    test('全形的中文標點不跳脫 —— 它們不是 iCalendar 的分隔符', () {
      final ics = _build([
        IcsEvent.allDay(
          uid: 'u',
          summary: '加退選開始',
          date: DateTime(2026, 2, 17),
          description: '上課開始，註冊；含校際選課',
        ),
      ]);
      final line = _unfold(ics).firstWhere((l) => l.startsWith('DESCRIPTION:'));
      expect(line, 'DESCRIPTION:上課開始，註冊；含校際選課');
    });

    test('含換行的描述折成一行，換行寫作 \\n', () {
      final ics = _build([
        IcsEvent.allDay(
          uid: 'u',
          summary: 's',
          date: DateTime(2026, 2, 17),
          description: '第一行\n第二行\n第三行',
        ),
      ]);
      final line = _unfold(ics).firstWhere((l) => l.startsWith('DESCRIPTION:'));
      expect(line, r'DESCRIPTION:第一行\n第二行\n第三行');
      // 實體上仍然只是一個邏輯行 —— 中間沒有任何未經折行標記的斷行。
      expect(line.contains('\r'), isFalse);
    });

    test('超過 75 octet 的描述被折行，且還原得回原文', () {
      const long =
          '本週介紹作業系統的行程排程演算法，包含先來先服務、最短工作優先、'
          '輪轉法與多層佇列，並比較各自的平均等待時間與飢餓問題。';
      final ics = _build([
        IcsEvent.allDay(
          uid: 'u',
          summary: 's',
          date: DateTime(2026, 2, 17),
          description: long,
        ),
      ]);

      // 每一個實體行都合規。
      for (final segment in ics.split('\r\n')) {
        expect(utf8.encode(segment).length, lessThanOrEqualTo(75));
      }
      // 還原後拿得回原文。
      final line = _unfold(ics).firstWhere((l) => l.startsWith('DESCRIPTION:'));
      expect(line.substring('DESCRIPTION:'.length), long);
    });
  });

  group('校曆事件 → IcsEvent', () {
    CalendarEvent event({String link = ''}) => CalendarEvent(
      id: '12345-0',
      date: '2026-04-14',
      name: '期中考週',
      link: link,
    );

    test('標題就是事件原名，沒有來源前綴', () {
      final ics = CalendarExportService.fromCalendarEvent(
        event(),
        sourceNote: '來自雲科大學校行事曆。',
      );
      expect(ics.summary, '期中考週');
    });

    test('描述含來源說明與校曆頁連結', () {
      final ics = CalendarExportService.fromCalendarEvent(
        event(link: 'https://events.yuntech.edu.tw/?x=1'),
        sourceNote: '來自雲科大學校行事曆。',
      );
      expect(ics.description, contains('來自雲科大學校行事曆。'));
      expect(ics.description, contains('https://events.yuntech.edu.tw/?x=1'));
    });

    test('沒有連結時描述不留空行', () {
      final ics = CalendarExportService.fromCalendarEvent(
        event(),
        sourceNote: '來自雲科大學校行事曆。',
      );
      expect(ics.description, '來自雲科大學校行事曆。');
    });

    test('是單日全天事件', () {
      final ics = CalendarExportService.fromCalendarEvent(
        event(),
        sourceNote: 's',
      );
      expect(ics.isAllDay, isTrue);
      expect(ics.start, DateTime(2026, 4, 14));
      expect(ics.end, DateTime(2026, 4, 15));
    });

    test('UID 穩定：同一筆事件算兩次得到同一個值', () {
      expect(
        CalendarExportService.uidForCalendarEvent(event()),
        CalendarExportService.uidForCalendarEvent(event()),
      );
    });

    test('UID 隨事件而異', () {
      final other = CalendarEvent(
        id: '12345-1',
        date: '2026-04-14',
        name: '校慶',
        link: '',
      );
      expect(
        CalendarExportService.uidForCalendarEvent(event()),
        isNot(CalendarExportService.uidForCalendarEvent(other)),
      );
    });

    test('不帶提醒 —— 輸出裡沒有 VALARM', () {
      final ics = _build([
        CalendarExportService.fromCalendarEvent(event(), sourceNote: 's'),
      ]);
      expect(ics.contains('VALARM'), isFalse);
    });
  });
}
