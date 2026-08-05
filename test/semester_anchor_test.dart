import 'package:flutter_test/flutter_test.dart';
import 'package:yun_tool/models/calendar_event.dart';
import 'package:yun_tool/utils/semester_anchor.dart';

CalendarEvent ev(String date, String name) =>
    CalendarEvent(id: '$date-$name', date: date, name: name, link: '');

/// 一份長得像真實行事曆的 2026 年資料：同一年裡**同時**有 2 月與 9 月兩筆
/// 「上課開始」，前者屬於 114-2、後者屬於 115-1。挑錯就整批歪掉半年。
final _calendar2026 = [
  ev('2026-01-01', '元旦放假'),
  ev('2026-02-01', '第2學期開始'),
  ev('2026-02-17', '上課開始'),
  ev('2026-02-28', '和平紀念日放假'),
  ev('2026-06-16', '學期考試開始'),
  ev('2026-08-01', '第1學期開始'),
  ev('2026-09-14', '上課開始'),
  ev('2026-10-10', '國慶日放假'),
];

void main() {
  group('gregorianYearOf', () {
    test('上學期是學年 + 1911（秋天，同一個西元年）', () {
      expect(gregorianYearOf(year: '114', semester: '1'), 2025);
      expect(gregorianYearOf(year: '115', semester: '1'), 2026);
    });

    test('下學期是學年 + 1912（春天，落在隔一個西元年）', () {
      expect(gregorianYearOf(year: '114', semester: '2'), 2026);
      expect(gregorianYearOf(year: '113', semester: '2'), 2025);
    });

    test('學年或學期不成形時回 null', () {
      expect(gregorianYearOf(year: '', semester: '1'), isNull);
      expect(gregorianYearOf(year: 'abc', semester: '1'), isNull);
      expect(gregorianYearOf(year: '114', semester: '3'), isNull);
      expect(gregorianYearOf(year: '114', semester: ''), isNull);
    });
  });

  group('findClassStart', () {
    test('下學期挑到 2 月那一筆，不是同一年 9 月那一筆', () {
      expect(
        findClassStart(_calendar2026, year: '114', semester: '2'),
        DateTime(2026, 2, 17),
      );
    });

    test('上學期挑到 9 月那一筆，不是同一年 2 月那一筆', () {
      expect(
        findClassStart(_calendar2026, year: '115', semester: '1'),
        DateTime(2026, 9, 14),
      );
    });

    test('不會抓到 8/1 的「第1學期開始」—— 那是行政起日，不是開學', () {
      final onlyAdministrative = [
        ev('2026-08-01', '第1學期開始'),
        ev('2026-02-01', '第2學期開始'),
      ];
      expect(
        findClassStart(onlyAdministrative, year: '115', semester: '1'),
        isNull,
      );
      expect(
        findClassStart(onlyAdministrative, year: '114', semester: '2'),
        isNull,
      );
    });

    test('該學年的行事曆沒有這一筆時回 null', () {
      expect(findClassStart(_calendar2026, year: '120', semester: '1'), isNull);
    });

    test('同一格切出多筆時取最早的那一筆', () {
      final events = [ev('2026-02-18', '上課開始'), ev('2026-02-17', '上課開始，註冊')];
      expect(
        findClassStart(events, year: '114', semester: '2'),
        DateTime(2026, 2, 17),
      );
    });

    test('月份落在區間外的同名事件不算數', () {
      // 6 月的「上課開始」（暑修之類）不該被當成下學期的錨點。
      final events = [ev('2026-06-29', '上課開始')];
      expect(findClassStart(events, year: '114', semester: '2'), isNull);
    });

    test('日期壞掉的事件被跳過，不讓整批推導失敗', () {
      final events = [ev('not-a-date', '上課開始'), ev('2026-02-17', '上課開始')];
      expect(
        findClassStart(events, year: '114', semester: '2'),
        DateTime(2026, 2, 17),
      );
    });

    test('回傳值只保留日期，不帶時刻', () {
      final result = findClassStart(_calendar2026, year: '114', semester: '2')!;
      expect(result.hour, 0);
      expect(result.minute, 0);
    });
  });

  group('firstWeekMonday', () {
    test('開學日就是週一時，第 1 週的週一就是開學日', () {
      final monday = DateTime(2026, 2, 16); // 週一
      expect(firstWeekMonday(monday), monday);
    });

    test('開學日不是週一時，回推到那一週的週一（會落在開學前）', () {
      // 2026-02-17 是週二 → 那一週的週一是 02-16。
      expect(firstWeekMonday(DateTime(2026, 2, 17)), DateTime(2026, 2, 16));
      // 2026-09-14 是週一。
      expect(firstWeekMonday(DateTime(2026, 9, 14)), DateTime(2026, 9, 14));
    });

    test('開學日是週日時回推六天', () {
      // 2026-03-01 是週日 → 週一是 02-23。
      expect(firstWeekMonday(DateTime(2026, 3, 1)), DateTime(2026, 2, 23));
    });

    test('回推跨月正確', () {
      // 2026-03-04 是週三 → 週一是 03-02，不跨月；
      // 2026-03-01（週日）已在上例驗過跨月。
      expect(firstWeekMonday(DateTime(2026, 3, 4)), DateTime(2026, 3, 2));
    });
  });

  group('dateOfWeek', () {
    final monday = DateTime(2026, 2, 16);

    test('第 1 週的週一就是錨點本身', () {
      expect(dateOfWeek(monday, week: 1, weekday: 1), monday);
    });

    test('第 N 週 = 錨點 + (N-1)×7 + (星期-1)', () {
      // 第 1 週週三
      expect(dateOfWeek(monday, week: 1, weekday: 3), DateTime(2026, 2, 18));
      // 第 5 週週一 = +28 天
      expect(dateOfWeek(monday, week: 5, weekday: 1), DateTime(2026, 3, 16));
      // 第 5 週週四 = +31 天
      expect(dateOfWeek(monday, week: 5, weekday: 4), DateTime(2026, 3, 19));
    });

    test('第 18 週仍在同一學期內，且跨月正確', () {
      // +119 天
      expect(dateOfWeek(monday, week: 18, weekday: 1), DateTime(2026, 6, 15));
    });

    test('跨年正確', () {
      final september = DateTime(2026, 9, 14);
      // 第 17 週週一 = +112 天 → 隔年 1 月
      expect(dateOfWeek(september, week: 17, weekday: 1), DateTime(2027, 1, 4));
    });

    test('算出來的星期真的是要的那一個', () {
      for (var weekday = 1; weekday <= 7; weekday++) {
        for (var week = 1; week <= 18; week++) {
          expect(
            dateOfWeek(monday, week: week, weekday: weekday).weekday,
            weekday,
          );
        }
      }
    });
  });
}
