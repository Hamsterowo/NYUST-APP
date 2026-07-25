import 'package:flutter_test/flutter_test.dart';
import 'package:yun_tool/models/schedule_event.dart';
import 'package:yun_tool/utils/timetable_layout.dart';

/// Locks ticket 06: the weekly grid's placement rules live in a pure module and
/// are exercised without building a widget.
void main() {
  // The real period codes, in order. Index 0 is 'X' (07:10), index 1 is 'A'.
  const allPeriods = [
    'X', 'A', 'B', 'C', 'D', 'Y', 'E', 'F', 'G', 'H', //
    'Z', 'I', 'J', 'K', 'L',
  ];

  ScheduleEvent course({
    required String name,
    required String weekday,
    required List<String> times,
    String semesterCourseNo = 'C-1',
  }) {
    return ScheduleEvent(
      semesterCourseNo: semesterCourseNo,
      deptCourseNo: '',
      name: name,
      courseClass: '',
      classType: '',
      requiredType: '',
      credits: '',
      timeRoomStr: '',
      teacher: '',
      remark: '',
      weekday: weekday,
      times: times,
    );
  }

  group('grid bounds', () {
    test('an empty course list falls back to Mon–Fri and periods A..H', () {
      final layout = TimetableLayout.from(const [], allPeriods: allPeriods);

      expect(layout.dayIndices, [0, 1, 2, 3, 4]);
      expect(layout.periods.first, 'A');
      expect(layout.periods.last, 'H');
    });

    test('a Mon–Fri course inside the default range keeps the floor', () {
      final layout = TimetableLayout.from([
        course(name: '微積分', weekday: '3', times: ['C']),
      ], allPeriods: allPeriods);

      expect(layout.dayIndices, [0, 1, 2, 3, 4]);
      expect(layout.periods.first, 'A');
      // Note the existing asymmetry this pins down: with no courses at all the
      // grid runs to 'H' (index 9), but once there is any class the lower bound
      // becomes index 8 ('G'), growing only if a course runs later than that.
      expect(layout.periods.last, 'G');
    });

    test('a Saturday course extends the grid past Friday', () {
      final layout = TimetableLayout.from([
        course(name: '週末課', weekday: '6', times: ['C']),
      ], allPeriods: allPeriods);

      expect(layout.dayIndices, [0, 1, 2, 3, 4, 5]);
    });

    test('an early and a late course extend the period range both ways', () {
      final layout = TimetableLayout.from([
        course(name: '早八前', weekday: '1', times: ['X']),
        course(name: '夜間', weekday: '1', times: ['K'], semesterCourseNo: 'C-2'),
      ], allPeriods: allPeriods);

      expect(layout.periods.first, 'X');
      expect(layout.periods.last, 'K');
    });
  });

  group('cell placement', () {
    test('a single-period course occupies exactly one cell', () {
      final layout = TimetableLayout.from([
        course(name: '微積分', weekday: '1', times: ['B']),
      ], allPeriods: allPeriods);

      final monday = layout.column(0);
      final filled = monday.where((c) => !c.isEmpty).toList();

      expect(filled, hasLength(1));
      expect(filled.single.event!.name, '微積分');
      expect(filled.single.span, 1);
    });

    test(
      'consecutive periods of one course merge into a single spanning cell',
      () {
        final layout = TimetableLayout.from([
          course(name: '專題', weekday: '2', times: ['C', 'D', 'Y']),
        ], allPeriods: allPeriods);

        final tuesday = layout.column(1);
        final filled = tuesday.where((c) => !c.isEmpty).toList();

        expect(
          filled,
          hasLength(1),
          reason: 'merged, not three separate cells',
        );
        expect(filled.single.span, 3);
        expect(filled.single.event!.name, '專題');
      },
    );

    test('two different courses in adjacent periods stay separate', () {
      final layout = TimetableLayout.from([
        course(name: '甲課', weekday: '1', times: ['A'], semesterCourseNo: 'C-1'),
        course(name: '乙課', weekday: '1', times: ['B'], semesterCourseNo: 'C-2'),
      ], allPeriods: allPeriods);

      final filled = layout.column(0).where((c) => !c.isEmpty).toList();

      expect(filled, hasLength(2));
      expect(filled.every((c) => c.span == 1), isTrue);
    });

    test('same name but a different course number does not merge', () {
      final layout = TimetableLayout.from([
        course(name: '體育', weekday: '1', times: ['A'], semesterCourseNo: 'C-1'),
        course(name: '體育', weekday: '1', times: ['B'], semesterCourseNo: 'C-2'),
      ], allPeriods: allPeriods);

      final filled = layout.column(0).where((c) => !c.isEmpty).toList();

      expect(filled, hasLength(2));
      expect(filled.every((c) => c.span == 1), isTrue);
    });

    test('a clash keeps the first course and silently drops the second', () {
      // Documents today's behaviour: there is no clash handling, first wins.
      final layout = TimetableLayout.from([
        course(
          name: '先到的',
          weekday: '1',
          times: ['B'],
          semesterCourseNo: 'C-1',
        ),
        course(
          name: '被蓋掉的',
          weekday: '1',
          times: ['B'],
          semesterCourseNo: 'C-2',
        ),
      ], allPeriods: allPeriods);

      final filled = layout.column(0).where((c) => !c.isEmpty).toList();

      expect(filled, hasLength(1));
      expect(filled.single.event!.name, '先到的');
    });

    test('courses with no time slot never reach the grid', () {
      final layout = TimetableLayout.from([
        course(name: '書報討論', weekday: null.toString(), times: const []),
      ], allPeriods: allPeriods);

      for (final day in layout.dayIndices) {
        expect(layout.column(day).every((c) => c.isEmpty), isTrue);
      }
    });

    test(
      'every column covers the full period range once spans are counted',
      () {
        final layout = TimetableLayout.from([
          course(name: '專題', weekday: '1', times: ['C', 'D']),
        ], allPeriods: allPeriods);

        final total = layout.column(0).fold<int>(0, (sum, c) => sum + c.span);

        expect(total, layout.periods.length);
      },
    );
  });

  group('course names', () {
    test('are de-duplicated and sorted, ignoring unnamed entries', () {
      final layout = TimetableLayout.from([
        course(name: 'B課', weekday: '1', times: ['A']),
        course(name: 'A課', weekday: '2', times: ['A'], semesterCourseNo: 'C-2'),
        course(name: 'B課', weekday: '3', times: ['A'], semesterCourseNo: 'C-3'),
      ], allPeriods: allPeriods);

      expect(layout.courseNames, ['A課', 'B課']);
    });
  });

  group('column lookup', () {
    test('a weekday outside the grid returns nothing', () {
      final layout = TimetableLayout.from(const [], allPeriods: allPeriods);

      expect(layout.column(6), isEmpty);
    });
  });
}
