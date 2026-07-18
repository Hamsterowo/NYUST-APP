import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
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

      expect(result['success'], isTrue);
      final grades = result['grades'] as List;
      expect(grades, hasLength(1));

      final semester = grades.first as Map;
      expect(semester['academic_year'], 113);
      expect(semester['semester'], 1);

      final courses = semester['courses'] as List;
      expect(courses, hasLength(2));
      final first = courses.first as Map;
      expect(first['code'], 'CS101-01');
      expect(first['name'], '資料結構');
      expect(first['name_en'], 'Data Structures');
      expect(first['type'], '必修');
      expect(first['credits'], '3');
      expect(first['score'], '92');
      expect(first['courseNo'], 'CS101');
      expect(
        first['syllabusUrl'],
        startsWith('https://webapp.yuntech.edu.tw/WebNewCAS/'),
      );

      final summary = semester['summary'] as Map;
      expect(summary['average_score'], '85.2');
      expect(summary['rank'], '5 / 50');
      expect(summary['gpa'], '3.8');
      expect(summary['conduct'], '90');
      expect(summary['attempted_credits'], '20');
      expect(summary['earned_credits'], '18');

      final cumulative = result['cumulative'] as Map;
      expect(cumulative['attempted_credits'], '40');
      expect(cumulative['earned_credits'], '38');
      expect(cumulative['average'], '84.5');
      expect(cumulative['rank'], '6');
      expect(cumulative['total_students'], '50');
      expect(cumulative['gpa'], '3.75');
    });

    test('reports session_expired when redirected to the login page', () async {
      final dio = Dio();
      dio.httpClientAdapter = FakeHtmlAdapter(
        (options) => htmlBody(loadFixture('login_page.html')),
      );

      final result = await GradesScraper(dio).getGrades();

      expect(result['success'], isFalse);
      expect(result['status'], 'session_expired');
      expect(result['isExpired'], isTrue);
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

      expect(result['success'], isFalse);
      expect(result['status'], 'network_error');
    });
  });
}
