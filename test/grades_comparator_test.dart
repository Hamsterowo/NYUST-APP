import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yun_tool/l10n/app_localizations.dart';
import 'package:yun_tool/utils/grades_comparator.dart';

/// Locks the grade-diff contract the background notification task relies on:
/// which changes produce a notification, in what order, and what the title /
/// body read like in both languages.
void main() {
  final zh = lookupAppLocalizations(const Locale('zh'));
  final en = lookupAppLocalizations(const Locale('en'));

  Map<String, dynamic> course({
    required String code,
    required String name,
    required String nameEn,
    required String score,
  }) => {'code': code, 'name': name, 'name_en': nameEn, 'score': score};

  Map<String, dynamic> grades({
    required List<Map<String, dynamic>> courses,
    String year = '112',
    String semester = '1',
    String average = '80.00',
    String rank = '10 / 50',
    String gpa = '3.50',
  }) => {
    'success': true,
    'grades': [
      {
        'academic_year': year,
        'semester': semester,
        'summary': {'average_score': average, 'rank': rank, 'gpa': gpa},
        'courses': courses,
      },
    ],
  };

  final mobile = course(
    code: 'COE3001',
    name: '行動裝置程式設計',
    nameEn: 'Mobile Device Programming',
    score: '90',
  );
  final software = course(
    code: 'COE3002',
    name: '軟體工程',
    nameEn: 'Software Engineering',
    score: '80',
  );

  final oldGrades = grades(courses: [mobile, software]);

  group('course changes', () {
    final scoreRaised = grades(
      courses: [
        course(
          code: 'COE3001',
          name: '行動裝置程式設計',
          nameEn: 'Mobile Device Programming',
          score: '95',
        ),
        software,
      ],
    );

    test('a raised score is reported, in Chinese', () {
      final changes = GradesComparator.compare(
        oldGrades,
        scoreRaised,
        l10n: zh,
      );

      expect(changes, hasLength(1));
      expect(changes.single.title, '行動裝置程式設計');
      expect(changes.single.body, '成績更新：95 分');
    });

    test('a raised score is reported, in English', () {
      final changes = GradesComparator.compare(
        oldGrades,
        scoreRaised,
        l10n: en,
      );

      expect(changes, hasLength(1));
      expect(changes.single.title, 'Mobile Device Programming');
      expect(changes.single.body, 'Grade updated: 95');
    });

    test('an unchanged score is not reported', () {
      final changes = GradesComparator.compare(oldGrades, oldGrades, l10n: zh);

      expect(changes, isEmpty);
    });

    test('a course that appears for the first time is reported', () {
      final withNetworks = grades(
        courses: [
          mobile,
          software,
          course(
            code: 'COE3003',
            name: '電腦網路',
            nameEn: 'Computer Networks',
            score: '85',
          ),
        ],
      );

      final changesZh = GradesComparator.compare(
        oldGrades,
        withNetworks,
        l10n: zh,
      );
      expect(changesZh, hasLength(1));
      expect(changesZh.single.title, '電腦網路');
      expect(changesZh.single.body, '成績更新：85 分');

      final changesEn = GradesComparator.compare(
        oldGrades,
        withNetworks,
        l10n: en,
      );
      expect(changesEn.single.title, 'Computer Networks');
      expect(changesEn.single.body, 'Grade updated: 85');
    });

    test('a whole new semester reports every course in it', () {
      final nextSemester = grades(courses: [mobile, software], semester: '2');

      final changes = GradesComparator.compare(
        oldGrades,
        nextSemester,
        l10n: zh,
      );

      expect(changes.map((c) => c.title), ['行動裝置程式設計', '軟體工程']);
    });
  });

  group('semester summary changes', () {
    test('a rank change is reported', () {
      final changes = GradesComparator.compare(
        oldGrades,
        grades(courses: [mobile, software], rank: '8 / 50'),
        l10n: zh,
      );

      expect(changes, hasLength(1));
      expect(changes.single.title, '學期排名');
      expect(changes.single.body, '排名：8 / 50');
    });

    test('a rank change is reported, in English', () {
      final changes = GradesComparator.compare(
        oldGrades,
        grades(courses: [mobile, software], rank: '8 / 50'),
        l10n: en,
      );

      expect(changes.single.title, 'Semester Rank');
      expect(changes.single.body, 'Rank: 8 / 50');
    });

    test('a GPA change is reported', () {
      final changes = GradesComparator.compare(
        oldGrades,
        grades(courses: [mobile, software], gpa: '3.70'),
        l10n: zh,
      );

      expect(changes, hasLength(1));
      expect(changes.single.title, '學期 GPA');
      expect(changes.single.body, 'GPA 更新：3.70');
    });

    test('an average change is reported', () {
      final changes = GradesComparator.compare(
        oldGrades,
        grades(courses: [mobile, software], average: '82.00'),
        l10n: zh,
      );

      expect(changes, hasLength(1));
      expect(changes.single.title, '學期平均');
      expect(changes.single.body, '平均更新：82.00 分');
    });

    test('course changes come before the summary changes they caused', () {
      final changes = GradesComparator.compare(
        oldGrades,
        grades(
          courses: [
            course(
              code: 'COE3001',
              name: '行動裝置程式設計',
              nameEn: 'Mobile Device Programming',
              score: '95',
            ),
            software,
          ],
          average: '82.00',
        ),
        l10n: zh,
      );

      expect(changes.map((c) => c.title), ['行動裝置程式設計', '學期平均']);
    });
  });

  group('unusable input', () {
    test('a null side produces nothing', () {
      expect(GradesComparator.compare(null, oldGrades, l10n: zh), isEmpty);
      expect(GradesComparator.compare(oldGrades, null, l10n: zh), isEmpty);
    });

    test('a failed fetch produces nothing', () {
      const failed = {'success': false};

      expect(GradesComparator.compare(oldGrades, failed, l10n: zh), isEmpty);
      expect(GradesComparator.compare(failed, oldGrades, l10n: zh), isEmpty);
    });
  });
}
