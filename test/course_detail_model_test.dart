import 'package:flutter_test/flutter_test.dart';
import 'package:yun_tool/models/course_detail_model.dart';

/// The course-detail cache stores this model directly. Older builds stored the
/// whole response envelope instead, and those rows are still on devices — a
/// 7-day TTL means they linger, and feeding an envelope straight into the
/// parser yields a blank course rather than an error. So the parser accepts
/// both shapes, and cached syllabi stay readable offline after upgrading.
void main() {
  Map<String, dynamic> payload() => {
    'courseName': '作業系統',
    'teacher': '王老師',
    'credits': '3',
    'timeRoom': '2-34/EB404',
    'requiredType': '必修',
    'goal': '理解作業系統核心概念',
    'outline': '行程、記憶體、檔案系統',
    'grade': '期中 40% 期末 40% 作業 20%',
    'deptCourseNo': 'CSIE3001',
    'courseType': '專業必修',
    'courseClass': '資工三甲',
    'teacherEmailAndTel': 'teacher@yuntech.edu.tw',
    'courseRemark': '需先修計算機概論',
    'syllabus': [
      {'week': '1', 'content': '課程介紹', 'method': '講授', 'remark': ''},
      {'week': '2', 'content': '行程管理', 'method': '講授', 'remark': '小考'},
    ],
  };

  group('CourseDetail.fromJson', () {
    test('parses the plain payload', () {
      final detail = CourseDetail.fromJson(payload());

      expect(detail.courseName, '作業系統');
      expect(detail.teacher, '王老師');
      expect(detail.deptCourseNo, 'CSIE3001');
      expect(detail.syllabus, hasLength(2));
      expect(detail.syllabus.last.content, '行程管理');
      expect(detail.syllabus.last.remark, '小考');
    });

    test('unwraps the legacy response envelope', () {
      final legacy = {'status': 'success', 'data': payload()};

      final detail = CourseDetail.fromJson(legacy);

      expect(
        detail.courseName,
        '作業系統',
        reason: 'an old cache row must not decode into a blank course',
      );
      expect(detail.syllabus, hasLength(2));
    });

    test('missing optional fields fall back rather than throwing', () {
      final detail = CourseDetail.fromJson({'courseName': '書報討論'});

      expect(detail.courseName, '書報討論');
      expect(detail.teacher, '');
      expect(detail.deptCourseNo, isNull);
      expect(detail.syllabus, isEmpty);
    });
  });

  group('toJson round-trip', () {
    test('preserves every field including the syllabus', () {
      final original = CourseDetail.fromJson(payload());
      final restored = CourseDetail.fromJson(original.toJson());

      expect(restored.courseName, original.courseName);
      expect(restored.teacher, original.teacher);
      expect(restored.credits, original.credits);
      expect(restored.timeRoom, original.timeRoom);
      expect(restored.requiredType, original.requiredType);
      expect(restored.goal, original.goal);
      expect(restored.outline, original.outline);
      expect(restored.grade, original.grade);
      expect(restored.deptCourseNo, original.deptCourseNo);
      expect(restored.courseType, original.courseType);
      expect(restored.courseClass, original.courseClass);
      expect(restored.teacherEmailAndTel, original.teacherEmailAndTel);
      expect(restored.courseRemark, original.courseRemark);
      expect(restored.syllabus, hasLength(original.syllabus.length));
      expect(restored.syllabus.first.week, original.syllabus.first.week);
      expect(restored.syllabus.last.remark, original.syllabus.last.remark);
    });

    test('a legacy row survives being re-saved in the new shape', () {
      final fromLegacy = CourseDetail.fromJson({
        'status': 'success',
        'data': payload(),
      });

      // What the cache writes back the next time it stores this course.
      final restored = CourseDetail.fromJson(fromLegacy.toJson());

      expect(restored.courseName, '作業系統');
      expect(restored.syllabus, hasLength(2));
    });
  });
}
