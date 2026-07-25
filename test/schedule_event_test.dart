import 'package:flutter_test/flutter_test.dart';
import 'package:yun_tool/models/schedule_event.dart';

/// Locks ticket 04: [ScheduleEvent] is the currency across the schedule seam.
/// The toJson round-trip is what the persisted "other semester" cache relies on,
/// and the legacy-key test protects cache rows already on device.
void main() {
  Map<String, dynamic> courseJson() => {
    'semesterCourseNo': '1142-0001',
    'deptCourseNo': 'CSIE3001',
    'name': '作業系統',
    'nameEn': 'Operating Systems',
    'courseClass': '資工三甲',
    'classType': '合班',
    'requiredType': '必修',
    'credits': '3',
    'timeRoomStr': '2-34/EB404',
    'teacher': '王老師',
    'remark': '需先修計算機概論',
    'weekday': '2',
    'times': ['3', '4'],
    'room': 'EB404',
    'syllabusUrl': 'https://webapp.yuntech.edu.tw/WebNewCAS/x',
    'year': '114',
    'semester': '2',
    'courseNo': 'CS3001',
  };

  group('ScheduleEvent round-trip', () {
    test('fromJson → toJson → fromJson preserves every field', () {
      final original = ScheduleEvent.fromJson(courseJson());
      final restored = ScheduleEvent.fromJson(original.toJson());

      expect(restored.semesterCourseNo, original.semesterCourseNo);
      expect(restored.deptCourseNo, original.deptCourseNo);
      expect(restored.name, original.name);
      expect(restored.nameEn, original.nameEn);
      expect(restored.courseClass, original.courseClass);
      expect(restored.classType, original.classType);
      expect(restored.requiredType, original.requiredType);
      expect(restored.credits, original.credits);
      expect(restored.timeRoomStr, original.timeRoomStr);
      expect(restored.teacher, original.teacher);
      expect(restored.remark, original.remark);
      expect(restored.weekday, original.weekday);
      expect(restored.times, original.times);
      expect(restored.room, original.room);
      expect(restored.syllabusUrl, original.syllabusUrl);
      expect(restored.year, original.year);
      expect(restored.semester, original.semester);
      expect(restored.courseNo, original.courseNo);
    });

    test('survives a course with no time slot and null optionals', () {
      final event = ScheduleEvent.fromJson({
        'name': '書報討論',
        'times': <String>[],
      });
      final restored = ScheduleEvent.fromJson(event.toJson());

      expect(restored.name, '書報討論');
      expect(restored.times, isEmpty);
      expect(restored.weekday, isNull);
      expect(restored.room, isNull);
      expect(restored.nameEn, isNull);
      // Non-nullable fields fall back to empty strings, not nulls.
      expect(restored.credits, '');
      expect(restored.teacher, '');
    });

    test('toJson emits the camelCase nameEn the scraper already writes', () {
      final wire = ScheduleEvent.fromJson(courseJson()).toJson();

      expect(wire['nameEn'], 'Operating Systems');
      expect(wire.containsKey('name_en'), isFalse);
    });

    test('still reads the legacy name_en key from older cache rows', () {
      final event = ScheduleEvent.fromJson({
        'name': '作業系統',
        'name_en': 'Operating Systems',
        'times': <String>[],
      });

      expect(event.nameEn, 'Operating Systems');
    });
  });

  group('ScheduleSnapshot.fromJson', () {
    test('parses courses, semester options and the current semester', () {
      final snapshot = ScheduleSnapshot.fromJson({
        'schedule': [courseJson()],
        'semesters': [
          {'value': '1142', 'label': '114學年第2學期'},
          {'value': '1141', 'label': '114學年第1學期'},
        ],
        'currentSemester': '1142',
      });

      expect(snapshot.courses, hasLength(1));
      expect(snapshot.courses.single.name, '作業系統');
      expect(snapshot.semesters, hasLength(2));
      expect(snapshot.semesters.first.value, '1142');
      expect(snapshot.semesters.first.label, '114學年第2學期');
      expect(snapshot.currentSemester, '1142');
    });

    test('falls back to empty metadata when the fetch carried none', () {
      final snapshot = ScheduleSnapshot.fromJson({
        'schedule': [courseJson()],
      });

      expect(snapshot.courses, hasLength(1));
      expect(snapshot.semesters, isEmpty);
      expect(snapshot.currentSemester, '');
    });

    test('an empty payload yields no courses', () {
      final snapshot = ScheduleSnapshot.fromJson({});

      expect(snapshot.courses, isEmpty);
      expect(snapshot.semesters, isEmpty);
    });
  });
}
