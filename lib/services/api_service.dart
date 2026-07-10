import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'api_client.dart';
import 'demo_mode.dart';
import 'app_api/app_api_service.dart';
import 'scrapers/sso_scraper.dart';
import 'scrapers/info_scraper.dart';

/// 對外的統一入口 facade。
///
/// 本身不再包辦 HTTP 細節，也不再有 mock 分支：而是持有一個 [ApiClient] 與一個
/// [ServiceFactory]，並把呼叫委派給 factory 依 demo 模式選出的 Service 實作。
/// 藉此保持既有的對外 API 不變（[AuthProvider] / [DataProvider] 等呼叫端不需修改）。
class ApiService {
  final ApiClient _client = ApiClient();
  late final ServiceFactory _factory = ServiceFactory(_client);

  /// 雲科 App 端點（MobileAppService，Bearer token）client。與 web 爬蟲的
  /// [ApiClient] 隔離，各用各的 session（見 [AppApiService]）。
  final AppApiService appApi = AppApiService();

  ApiService();

  Dio get dio => _client.dio;

  VoidCallback? get onSessionExpired => _client.onSessionExpired;
  set onSessionExpired(VoidCallback? cb) => _client.onSessionExpired = cb;

  /// demo / 除錯模式開關。實際上代理到 [ServiceFactory.isDemoMode]，
  /// 由它決定回傳 Mock 還是真實 Service 實作。
  bool get isMockMode => _factory.isDemoMode;
  set isMockMode(bool v) {
    _factory.isDemoMode = v;
    // Keep the app-endpoint client in sync so the credential page shows
    // sample data for the demo account (which never really logs in via /Token).
    appApi.setMockMode(v);
  }

  Future<void> init() => _client.init();

  /// 檢查是否有儲存的學校 Cookies
  Future<bool> hasSavedCookies() => _client.hasSavedCookies();

  /// 取得特定網域的 Cookies
  Future<List<Cookie>> getCookiesForUri(Uri uri) =>
      _client.getCookiesForUri(uri);

  // ---- Auth ----

  Future<Map<String, dynamic>> loginInit() => _factory.authService.loginInit();

  Future<Map<String, dynamic>> login(
    String username,
    String password,
    String captcha,
    String requestVerificationToken,
  ) => _factory.authService.login(
    username,
    password,
    captcha,
    requestVerificationToken,
  );

  Future<Map<String, dynamic>> submitTotp(
    String code,
    String verificationToken,
  ) => _factory.authService.submitTotp(code, verificationToken);

  Future<Map<String, dynamic>> getUserInfo() =>
      _factory.authService.getUserInfo();

  Future<void> logout() => _factory.authService.logout();

  // ---- Calendar ----

  Future<Map<String, dynamic>> getCalendarEvents(String year, {String? lang}) =>
      _factory.calendarService.getCalendarEvents(year, lang: lang);

  Future<Map<String, dynamic>> getHolidays(int year, {String? lang}) =>
      _factory.calendarService.getHolidays(year, lang: lang);

  /// 同時呼叫行事曆事件 + 假日兩個端點，合併回傳
  Future<Map<String, dynamic>> getCalendarCombined(
    String year, {
    String? lang,
  }) => _factory.calendarService.getCalendarCombined(year, lang: lang);

  /// 同時呼叫行事曆事件 + 假日兩個端點，合併回傳
  Future<Map<String, dynamic>> getCalendar(int year, {String? lang}) =>
      _factory.calendarService.getCalendarCombined(year.toString(), lang: lang);

  // ---- Grades ----

  Future<Map<String, dynamic>> getGrades() =>
      _factory.gradesService.getGrades();

  Future<Map<String, dynamic>> getGraduation() =>
      _factory.gradesService.getGraduation();

  // ---- Course ----

  Future<Map<String, dynamic>> getSchedule({String? semester}) =>
      _factory.courseService.getSchedule(semester: semester);

  Future<Map<String, dynamic>> getCourseDetail({
    required String year,
    required String semester,
    required String courseNo,
  }) => _factory.courseService.getCourseDetail(
    year: year,
    semester: semester,
    courseNo: courseNo,
  );

  // ---- Scraper 存取（維持既有對外 getter；目前無外部使用者）----

  SsoScraper get ssoScraper => _factory.nyustAuth.ssoScraper;
  InfoScraper get infoScraper => _factory.nyustAuth.infoScraper;
}
