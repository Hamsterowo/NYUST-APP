import 'package:flutter_test/flutter_test.dart';
import 'package:yun_tool/models/graduation_report.dart';

/// Locks ticket 03: [GraduationReport.fromJson] is the single ingestion point
/// (scraper, mock and the Drift EAV rebuild all go through it), it tolerates
/// absent groups, and toJson round-trips — which is what lets the repository
/// keep a generic group/category EAV loop.
void main() {
  // Real-scraper shaped payload: 4 groups, with the extra offset/outer
  // categories that only `earned` and `not_received` carry.
  Map<String, dynamic> fullSample() => {
    'success': true,
    'graduation_info': {
      'total_credits': '91',
      'english_threshold': '未通過',
      'internship_threshold': '未修過',
      'credits_breakdown': {
        'required_goal': {
          'pe': '4',
          'civilization': '2',
          'literature': '2',
          'general': '8',
          'dept_required': '63',
          'elective': '49',
          'total': '128',
        },
        'earned': {
          'pe': '4',
          'civilization': '2',
          'literature': '2',
          'general': '6',
          'dept_required': '62',
          'dept_required_offset': '3',
          'elective': '15',
          'elective_offset': '2',
          'elective_outer': '1',
          'total': '91',
        },
        'not_received': {
          'pe': '0',
          'civilization': '0',
          'literature': '0',
          'general': '0',
          'dept_required': '0',
          'elective': '0',
          'elective_outer': '0',
          'total': '0',
        },
        'missing': {
          'pe': '0',
          'civilization': '0',
          'literature': '0',
          'general': '2',
          'dept_required': '1',
          'elective': '34',
          'total': '37',
        },
      },
      'missing_courses_text': 'CSE3007工程倫理與產業導論[3]、實習課程[0]',
    },
  };

  group('GraduationReport.fromJson', () {
    test('parses top-level fields and all four credit groups', () {
      final report = GraduationReport.fromJson(fullSample());

      expect(report.totalCredits, '91');
      expect(report.englishThreshold, '未通過');
      expect(report.internshipThreshold, '未修過');

      expect(report.requiredGoal.total, '128');
      expect(report.requiredGoal.deptRequired, '63');
      expect(report.earned.total, '91');
      expect(report.earned.deptRequiredOffset, '3');
      expect(report.earned.electiveOffset, '2');
      expect(report.earned.electiveOuter, '1');
      expect(report.notReceived.total, '0');
      expect(report.missing.elective, '34');
    });

    test('tolerates absent groups (the demo payload has only three)', () {
      final report = GraduationReport.fromJson({
        'success': true,
        'graduation_info': {
          'total_credits': '91',
          'credits_breakdown': {
            'required_goal': {'total': '128'},
            'earned': {'total': '91'},
            'missing': {'total': '37'},
          },
        },
      });

      expect(report.requiredGoal.total, '128');
      // not_received is absent → empty group, not a crash.
      expect(report.notReceived.total, '');
      expect(report.notReceived.pe, '');
      // Absent categories within a present group are empty too.
      expect(report.earned.pe, '');
      expect(report.missingCoursesText, '');
      expect(report.missingCourses, isEmpty);
    });

    test('an entirely absent breakdown yields empty groups', () {
      final report = GraduationReport.fromJson({
        'success': true,
        'graduation_info': {'total_credits': '0'},
      });

      expect(report.requiredGoal.total, '');
      expect(report.earned.total, '');
      expect(report.missing.total, '');
    });
  });

  group('MissingCourse parsing', () {
    test('splits, extracts code/name/year and sorts by year', () {
      final report = GraduationReport.fromJson(fullSample());
      final courses = report.missingCourses;

      expect(courses, hasLength(2));

      // Sorted by suggested year: the unparseable [0] entry comes first.
      expect(courses.first.year, 0);
      expect(courses.first.code, '');
      expect(courses.first.name, '實習課程[0]');

      expect(courses.last.code, 'CSE3007');
      expect(courses.last.name, '工程倫理與產業導論');
      expect(courses.last.year, 3);
    });

    test('keeps the raw text alongside the parsed list', () {
      final report = GraduationReport.fromJson(fullSample());
      expect(report.missingCoursesText, 'CSE3007工程倫理與產業導論[3]、實習課程[0]');
    });

    test('an empty string parses to no courses', () {
      expect(MissingCourse.parseAll(''), isEmpty);
      expect(MissingCourse.parseAll('   '), isEmpty);
    });
  });

  group('toJson round-trip', () {
    test('model → toJson → fromJson preserves every group value', () {
      final original = GraduationReport.fromJson(fullSample());
      final restored = GraduationReport.fromJson(original.toJson());

      expect(restored.totalCredits, original.totalCredits);
      expect(restored.englishThreshold, original.englishThreshold);
      expect(restored.internshipThreshold, original.internshipThreshold);
      expect(restored.missingCoursesText, original.missingCoursesText);

      expect(restored.requiredGoal.total, original.requiredGoal.total);
      expect(restored.requiredGoal.pe, original.requiredGoal.pe);
      expect(restored.earned.deptRequiredOffset, '3');
      expect(restored.earned.electiveOuter, '1');
      expect(restored.notReceived.total, original.notReceived.total);
      expect(restored.missing.elective, original.missing.elective);
      expect(restored.missingCourses, hasLength(2));
    });

    test('toJson omits empty categories so EAV rows stay sparse', () {
      final group = const CreditGroup(pe: '4', total: '128').toJson();

      expect(group.keys, containsAll(['pe', 'total']));
      expect(group.containsKey('elective_outer'), isFalse);
      expect(group.containsKey('dept_required_offset'), isFalse);
    });
  });
}
