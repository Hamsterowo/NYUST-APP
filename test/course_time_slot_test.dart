import 'package:flutter_test/flutter_test.dart';
import 'package:yun_tool/utils/course_time_slot.dart';

void main() {
  group('parseCourseTimeRooms', () {
    test('單一時段', () {
      final slots = parseCourseTimeRooms('1-CD/EL101');
      expect(slots.length, 1);
      expect(slots.single.weekday, 1);
      expect(slots.single.periods, ['C', 'D']);
      expect(slots.single.room, 'EL101');
    });

    test('連續節次併成一塊，時間橫跨整段', () {
      // C = 10:10-11:00、D = 11:10-12:00
      expect(
        parseCourseTimeRooms('1-CD/EL101').single.timeText,
        '10:10 - 12:00',
      );
    });

    test('同一天不連續的節次拆成兩塊，各自帶自己的時間', () {
      // C,D 與 G,H 之間隔著 Y/E/F。
      final slots = parseCourseTimeRooms('4-CDGH/EL108');
      expect(slots.length, 2);
      expect(slots[0].periods, ['C', 'D']);
      expect(slots[0].timeText, '10:10 - 12:00');
      expect(slots[1].periods, ['G', 'H']);
      expect(slots[1].timeText, '15:10 - 17:00');
    });

    test('跨天的時段各自一塊，各帶自己的教室', () {
      final slots = parseCourseTimeRooms('4-GH/EL108 2-AB/EL205');
      expect(slots.length, 2);
      // 依星期排序，週二在前。
      expect(slots[0].weekday, 2);
      expect(slots[0].room, 'EL205');
      expect(slots[1].weekday, 4);
      expect(slots[1].room, 'EL108');
    });

    test('demo 那門多時段的課：同日不連續 + 跨天不同教室', () {
      final slots = parseCourseTimeRooms('4-CD/EL108 4-GH/EL108 2-AB/EL205');
      expect(slots.length, 3);
      expect(
        slots.map((s) => '${s.weekday}${s.periods.join()}@${s.room}').toList(),
        ['2AB@EL205', '4CD@EL108', '4GH@EL108'],
      );
    });

    test('同一天同一間教室被寫成兩個相鄰項目時併回一塊', () {
      // A,B 與 C,D 是連續的；分開寫只是學校的排版，實際上是一整段課。
      final slots = parseCourseTimeRooms('1-AB/EL101 1-CD/EL101');
      expect(slots.length, 1);
      expect(slots.single.periods, ['A', 'B', 'C', 'D']);
      expect(slots.single.timeText, '08:10 - 12:00');
    });

    test('同一天但不同教室不會被併起來', () {
      final slots = parseCourseTimeRooms('1-AB/EL101 1-CD/EL205');
      expect(slots.length, 2);
      expect(slots[0].room, 'EL101');
      expect(slots[1].room, 'EL205');
    });

    test('容忍節次之間夾逗號或頓號的寫法', () {
      expect(parseCourseTimeRooms('1-C,D/EL101').single.periods, ['C', 'D']);
      expect(parseCourseTimeRooms('1-C、D/EL101').single.periods, ['C', 'D']);
    });

    test('節次順序顛倒時仍按上課先後併塊', () {
      expect(parseCourseTimeRooms('1-DC/EL101').single.periods, ['C', 'D']);
    });

    test('晚上的節次時間正確（不是整點）', () {
      // I = 18:25-19:15、J = 19:20-20:10
      expect(
        parseCourseTimeRooms('3-IJ/EL301').single.timeText,
        '18:25 - 20:10',
      );
    });

    test('解析不出時段時回空清單，呼叫端據此停用按鈕', () {
      expect(parseCourseTimeRooms(''), isEmpty);
      expect(parseCourseTimeRooms('   '), isEmpty);
      expect(parseCourseTimeRooms('EL101'), isEmpty);
      expect(parseCourseTimeRooms('無固定上課時間'), isEmpty);
    });

    test('未知的節次字母被忽略，不會產生時間算不出來的區塊', () {
      // Q 不是節次代碼。
      final slots = parseCourseTimeRooms('1-QC/EL101');
      expect(slots.single.periods, ['C']);
    });

    test('整段都是未知節次時不產生任何區塊', () {
      expect(parseCourseTimeRooms('1-QQ/EL101'), isEmpty);
    });

    test('startOn / endOn 把區塊掛到指定的那一天', () {
      final slot = parseCourseTimeRooms('1-CD/EL101').single;
      final day = DateTime(2026, 3, 16);
      expect(slot.startOn(day), DateTime(2026, 3, 16, 10, 10));
      expect(slot.endOn(day), DateTime(2026, 3, 16, 12, 0));
    });
  });
}
