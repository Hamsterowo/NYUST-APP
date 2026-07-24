import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yun_tool/services/scrape_result.dart';
import 'package:yun_tool/services/scrapers/grades_scraper.dart';

import 'fake_adapter.dart';

void main() {
  group('GradesScraper.getGrades', () {
    Dio fakeGradesDio() {
      final dio = Dio();
      dio.httpClientAdapter = FakeHtmlAdapter((options) {
        if (options.path.contains('StudScoreRank.aspx')) {
          return htmlBody(loadFixture('grades_rank_page.html'));
        }
        if (options.path.contains('StudScores.aspx')) {
          return htmlBody(loadFixture('grades_page.html'));
        }
        // 進成績頁前的 Course/ 熱身請求。
        return htmlBody('<html><body>ok</body></html>');
      });
      return dio;
    }

    test('parses semesters, courses and rank summary', () async {
      final result = await GradesScraper(fakeGradesDio()).getGrades();

      expect(result.isSuccess, isTrue);
      final report = result.data!;
      expect(report.semesters, hasLength(1));

      final semester = report.semesters.first;
      expect(semester.academicYear, '113');
      expect(semester.semester, '1');

      expect(semester.courses, hasLength(2));
      final first = semester.courses.first;
      expect(first.code, 'CS101-01');
      expect(first.name, '資料結構');
      expect(first.nameEn, 'Data Structures');
      expect(first.type, '必修');
      expect(first.credits, '3');
      expect(first.score, '92');
      expect(first.courseNo, 'CS101');
      expect(
        first.syllabusUrl,
        startsWith('https://webapp.yuntech.edu.tw/WebNewCAS/'),
      );

      expect(semester.averageScore, '85.2');
      expect(semester.rank, '5 / 50');
      expect(semester.gpa, '3.8');
      expect(semester.conduct, '90');
      expect(semester.attemptedCredits, '20');
      expect(semester.earnedCredits, '18');

      final cumulative = report.cumulative!;
      expect(cumulative.attemptedCredits, '40');
      expect(cumulative.earnedCredits, '38');
      expect(cumulative.average, '84.5');
      expect(cumulative.rank, '6');
      expect(cumulative.totalStudents, '50');
      expect(cumulative.gpa, '3.75');
    });

    test('reports session_expired when redirected to the login page', () async {
      final dio = Dio();
      dio.httpClientAdapter = FakeHtmlAdapter(
        (options) => htmlBody(loadFixture('login_page.html')),
      );

      final result = await GradesScraper(dio).getGrades();

      expect(result.isSuccess, isFalse);
      expect(result.status, RefreshOutcome.sessionExpired);
      expect(result.data, isNull);
    });

    test('reports network_error when the connection fails', () async {
      final dio = Dio();
      dio.httpClientAdapter = FakeHtmlAdapter(
        (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await GradesScraper(dio).getGrades();

      expect(result.isSuccess, isFalse);
      expect(result.status, RefreshOutcome.networkError);
    });
  });
}
