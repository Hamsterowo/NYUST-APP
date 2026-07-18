import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yun_tool/services/scrapers/info_scraper.dart';

import 'fake_adapter.dart';

void main() {
  group('InfoScraper.getUserInfo', () {
    test('parses user fields from the Chinese info page', () async {
      final dio = Dio();
      dio.httpClientAdapter = FakeHtmlAdapter(
        (options) => htmlBody(loadFixture('info_page.html')),
      );

      final result = await InfoScraper(dio).getUserInfo();

      expect(result['success'], isTrue);
      final user = result['user'] as Map;
      expect(user['name'], '王小明');
      expect(user['姓名'], '王小明');
      expect(user['學號'], 'B11217990');
      expect(user['department'], '資訊工程系');
      expect(user['班級'], '四資工三A');
      expect(user['入學年制'], '四技');
    });

    test('reports session_expired when landed on the login page', () async {
      final dio = Dio();
      dio.httpClientAdapter = FakeHtmlAdapter(
        (options) => htmlBody(loadFixture('login_page.html')),
      );

      final result = await InfoScraper(dio).getUserInfo();

      expect(result['success'], isFalse);
      expect(result['status'], 'session_expired');
    });

    test('reports network_error when the connection fails', () async {
      final dio = Dio();
      dio.httpClientAdapter = FakeHtmlAdapter(
        (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await InfoScraper(dio).getUserInfo();

      expect(result['success'], isFalse);
      expect(result['status'], 'network_error');
    });
  });
}
