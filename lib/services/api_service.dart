import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'cookie_manager/cookie_manager_api.dart';
import 'scrapers/sso_scraper.dart';
import 'scrapers/info_scraper.dart';
import 'scrapers/schedule_scraper.dart';
import 'scrapers/grades_scraper.dart';
import 'scrapers/graduation_scraper.dart';
import 'scrapers/calendar_scraper.dart';

class ApiService {
  late Dio _dio;
  late SsoScraper _ssoScraper;
  late InfoScraper _infoScraper;
  late ScheduleScraper _scheduleScraper;
  late GradesScraper _gradesScraper;
  late GraduationScraper _graduationScraper;
  late CalendarScraper _calendarScraper;
  final String baseUrl = 'https://cf-api.nyust-plus.com';
  bool _initStarted = false;
  bool _isInit = false;

  Dio get dio => _dio;

  // SharedPreferences 的 key，用來儲存學校 Cookies
  static const String _schoolCookiesKey = 'school_session_cookies';
  // 記住此次登入是否為「僅此次（不保持登入）」
  static const String _sessionOnlyKey = 'session_only_login';

  // 安全密鑰保險箱（已停用，改回 SharedPreferences 解決冷啟動遺失問題）
  // final _secureStorage = const FlutterSecureStorage();

  // 針對後端 API 驗證的通行密鑰 (API_SECRET)
  // 若為編譯版 (如 Web)，可透過 --dart-define=API_SECRET=您的密鑰 來注入
  static const String _apiSecretKey = String.fromEnvironment(
    'API_SECRET',
    defaultValue: 'lrR2Uf-E6No13m45iCa7', // 本機開發或未設定時的預設回退值
  );

  /// 當 API 回傳 401 Session 過期時觸發，由 AuthProvider 設定
  VoidCallback? onSessionExpired;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        validateStatus: (status) {
          return status! < 500;
        },
        headers: {
          'Content-Type': 'application/json',
          'X-Nyust-App-Secret': _apiSecretKey,
        },
      ),
    );
    _ssoScraper = SsoScraper(_dio);
    _infoScraper = InfoScraper(_dio);
    _scheduleScraper = ScheduleScraper(_dio);
    _gradesScraper = GradesScraper(_dio);
    _graduationScraper = GraduationScraper(_dio);
    _calendarScraper = CalendarScraper(_dio);
  }

  Future<void> init() async {
    if (_isInit) return;
    if (_initStarted) {
      while (!_isInit) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      return;
    }
    _initStarted = true;

    try {
      await setupCookieManager(_dio);

      // 若上次登入沒有勾選「保持登入」（或者是全新安裝），重啟時自動清除 cookies
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_sessionOnlyKey) == false; // false 代表 rememberMe 為 true

      if (!rememberMe) {
        if (kDebugMode) {
          print('ApiService: sessionOnlyLogin or unknown state, clearing cookies for safety...');
        }
        await _clearSchoolCookies();
      } else {
        if (kDebugMode) {
          print('ApiService: rememberMe was explicitly enabled, keeping cookies.');
        }
      }

      _isInit = true;
    } catch (e) {
      if (kDebugMode) print('ApiService: Init failed: $e');
      _initStarted = false;
      rethrow;
    }
  }

  Future<void> _ensureInit() async {
    if (!_isInit) {
      await init();
    }
  }

  // ─── 學校 Cookie 的 SharedPreferences 儲存 ────────────────────────────────

  /// 從 SharedPreferences 讀取學校 Cookies（不依賴 CookieJar domain 匹配）
  Future<List<Map<String, dynamic>>> _loadSchoolCookies() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_schoolCookiesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) {
        final map = e as Map;
        final newMap = <String, dynamic>{};
        map.forEach((key, value) {
          newMap[key.toString()] = value;
        });
        return newMap;
      }).toList();
    } catch (e) {
      if (kDebugMode) print('ApiService: Failed to parse cookies: $e');
      return [];
    }
  }

  /// 將學校 Cookies 儲存到 SharedPreferences
  Future<void> _saveSchoolCookies(List<dynamic> cookies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_schoolCookiesKey, jsonEncode(cookies));
  }

  /// 清除學校 Cookies (從 SharedPreferences)
  Future<void> _clearSchoolCookies() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_schoolCookiesKey);
  }

  /// 檢查是否有儲存的學校 Cookies
  Future<bool> hasSavedCookies() async {
    final cookies = await _loadSchoolCookies();
    return cookies.isNotEmpty;
  }

  // ─── 登入流程 ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> loginInit() async {
    await _ensureInit();
    try {
      // 改為使用本地 Scraper
      return await _ssoScraper.loginInit();
    } catch (e) {
      throw Exception('Failed to init login: $e');
    }
  }

  Future<Map<String, dynamic>> login(
    String username,
    String password,
    String captcha,
    String requestVerificationToken,
    bool rememberMe,
  ) async {
    await _ensureInit();
    try {
      // 改為使用本地 Scraper
      final result = await _ssoScraper.login(
        username: username,
        password: password,
        captcha: captcha,
        verificationToken: requestVerificationToken,
        rememberMe: rememberMe,
      );

      if (result['success'] == true) {
        // 登入成功後，同步本地 Cookie 到 SharedPreferences 以相容舊有的 API 呼叫
        await _syncCookiesFromJar();
        
        // 記錄是否為僅此次登入（重啟後清除）
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_sessionOnlyKey, !rememberMe);
      }
      return result;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// 從 CookieJar 中同步學校 Cookies 到 SharedPreferences (供舊版 API 使用)
  Future<void> _syncCookiesFromJar() async {
    try {
      final cookieJar = _dio.interceptors
          .whereType<CookieManager>()
          .firstOrNull
          ?.cookieJar;
      
      if (cookieJar == null) return;

      // 取得雲科大相關網域的 Cookies
      final domains = [
        'https://webapp.yuntech.edu.tw',
        'https://yunportal.yuntech.edu.tw'
      ];
      
      final List<Map<String, dynamic>> allCookies = [];
      for (var domain in domains) {
        final cookies = await cookieJar.loadForRequest(Uri.parse(domain));
        for (var c in cookies) {
          allCookies.add({
            'name': c.name,
            'value': c.value,
            'domain': c.domain,
            'path': c.path,
            'expires': c.expires?.toIso8601String(),
            'httpOnly': c.httpOnly,
            'secure': c.secure,
          });
        }
      }

      if (allCookies.isNotEmpty) {
        await _saveSchoolCookies(allCookies);
        if (kDebugMode) print('ApiService: Cookies synced to SharedPreferences');
      }
    } catch (e) {
      if (kDebugMode) print('ApiService: Failed to sync cookies: $e');
    }
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    await _ensureInit();
    return _infoScraper.getUserInfo();
  }

  Future<Map<String, dynamic>> getCalendarEvents(String year) async {
    await _ensureInit();
    return _calendarScraper.getCalendarEvents(year);
  }

  Future<Map<String, dynamic>> getHolidays(int year) async {
    await _ensureInit();
    return _calendarScraper.getHolidays(year);
  }

  /// 同時呼叫行事曆事件 + 假日兩個端點，合併回傳
  Future<Map<String, dynamic>> getCalendarCombined(String year) async {
    final events = await getCalendarEvents(year);
    final holidays = await getHolidays(int.parse(year));

    return {
      'success': events['success'] == true && holidays['success'] == true,
      'events': events['events'] ?? [],
      'holidays': holidays['holidays'] ?? [],
      'holidayDetails': holidays['holidayDetails'] ?? {},
    };
  }

  Future<Map<String, dynamic>> getGrades() async {
    await _ensureInit();
    return _gradesScraper.getGrades();
  }

  Future<Map<String, dynamic>> getGraduation() async {
    await _ensureInit();
    return _graduationScraper.getGraduation();
  }

  /// 同時呼叫行事曆事件 + 假日兩個端點，合併回傳
  Future<Map<String, dynamic>> getCalendar(int year) async {
    return getCalendarCombined(year.toString());
  }

  Future<Map<String, dynamic>> getPrivacyPolicy() async {
    await _ensureInit();
    try {
      final response = await _dio.get('/api/policy/privacy');
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return {'status': 'error', 'message': '連線逾時，請稍後再試'};
      }
      if (e.type == DioExceptionType.connectionError) {
        return {'status': 'error', 'message': '無法連線至伺服器，請檢查網路連線'};
      }
      return {'status': 'error', 'message': 'API 呼叫失敗: ${e.message}'};
    } catch (e) {
      return {'status': 'error', 'message': 'API call failed: $e'};
    }
  }

  Future<Map<String, dynamic>> getTermsOfService() async {
    await _ensureInit();
    try {
      final response = await _dio.get('/api/policy/terms');
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return {'status': 'error', 'message': '連線逾時，請稍後再試'};
      }
      if (e.type == DioExceptionType.connectionError) {
        return {'status': 'error', 'message': '無法連線至伺服器，請檢查網路連線'};
      }
      return {'status': 'error', 'message': 'API 呼叫失敗: ${e.message}'};
    } catch (e) {
      return {'status': 'error', 'message': 'API call failed: $e'};
    }
  }


  Future<Map<String, dynamic>> getSchedule() async {
    await _ensureInit();
    return _scheduleScraper.getSchedule();
  }

  Future<Map<String, dynamic>> getCourseDetail({
    required String year,
    required String semester,
    required String courseNo,
  }) async {
    await _ensureInit();
    return _scheduleScraper.getCourseDetail(
      year: year,
      semester: semester,
      courseNo: courseNo,
    );
  }

  Future<void> logout() async {
    await _clearSchoolCookies();
    await clearCookies(); // 徹底清除 CookieJar 中的實體檔案
  }

  SsoScraper get ssoScraper => _ssoScraper;
  InfoScraper get infoScraper => _infoScraper;
}
