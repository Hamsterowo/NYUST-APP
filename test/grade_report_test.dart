import 'package:flutter_test/flutter_test.dart';
import 'package:yun_tool/models/grade_report.dart';

/// Locks ticket 02's central guarantee: [GradeReport] is the single ingestion
/// point (fromJson) and its toJson reproduces the scraper wire shape byte-for-
/// byte on the keys the background `grades_comparator` reads — so the comparator
/// and `cache_grades` stay untouched.
void main() {
  // A scraper-shaped payload (all-String values, snake_case keys).
  Map<String, dynamic> sample() => {
    'success': true,
    'grades': [
      {
        'academic_year': '112',
        'semester': '1',
        'semester_title': '第112學年第1學期',
        'courses': [
          {
            'code': 'GE101',
            'courseNo': '0001',
            'name': '微積分',
            'name_en': 'Calculus I',
            'type': '必修',
            'credits': '3',
            'score': '85',
            'syllabusUrl': 'https://example/x',
          },
        ],
        'summary': {
          'average_score': '85',
          'rank': '6 / 50',
          'gpa': '3.7',
          'conduct': '',
          'attempted_credits': '19',
          'earned_credits': '19',
        },
      },
    ],
    'cumulative': {
      'attempted_credits': '91',
      'earned_credits': '91',
      'average': '84.5',
      'rank': '6',
      'total_students': '50',
      'gpa': '3.75',
    },
  };

  group('GradeReport.fromJson', () {
    test('parses the scraper wire shape into typed fields', () {
      final report = GradeReport.fromJson(sample());

      expect(report.semesters, hasLength(1));
      final sem = report.semesters.single;
      expect(sem.academicYear, '112');
      expect(sem.semester, '1');
      expect(sem.gpa, '3.7');
      expect(sem.rank, '6 / 50');
      expect(sem.courses.single.nameEn, 'Calculus I');
      expect(sem.courses.single.name, '微積分');
      expect(sem.courses.single.score, '85');
      expect(report.cumulative?.average, '84.5');
      expect(report.cumulative?.totalStudents, '50');
    });

    test('accepts the camelCase nameEn key as a fallback', () {
      final report = GradeReport.fromJson({
        'success': true,
        'grades': [
          {
            'academic_year': '112',
            'semester': '1',
            'courses': [
              {'name': 'X', 'nameEn': 'English X'},
            ],
          },
        ],
        'cumulative': null,
      });
      expect(report.semesters.single.courses.single.nameEn, 'English X');
    });
  });

  group('GradeReport.toJson wire compatibility', () {
    test('reproduces the keys grades_comparator reads', () {
      final wire = GradeReport.fromJson(sample()).toJson();

      expect(wire['success'], true);

      final sem = (wire['grades'] as List).single as Map;
      expect(sem['academic_year'], '112');
      expect(sem['semester'], '1');

      final course = (sem['courses'] as List).single as Map;
      expect(course['code'], 'GE101');
      expect(course['name'], '微積分');
      expect(course['name_en'], 'Calculus I');
      expect(course['score'], '85');

      final summary = sem['summary'] as Map;
      expect(summary['average_score'], '85');
      expect(summary['rank'], '6 / 50');
      expect(summary['gpa'], '3.7');

      final cumulative = wire['cumulative'] as Map;
      expect(cumulative['average'], '84.5');
      expect(cumulative['rank'], '6');
      expect(cumulative['total_students'], '50');
      expect(cumulative['earned_credits'], '91');
    });
  });
}
