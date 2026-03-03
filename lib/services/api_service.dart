import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'cookie_manager/cookie_manager_api.dart';

class ApiService {
  late Dio _dio;
  final String baseUrl = 'https://cf-api.nyust-plus.com';
  bool _initStarted = false;
  bool _isInit = false;

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
    defaultValue: '***REMOVED***', // 本機開發或未設定時的預設回退值
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

      // 若上次登入沒有勾選「保持登入」，重啟時自動清除 cookies
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_sessionOnlyKey) == true) {
        if (kDebugMode) {
          print('ApiService: sessionOnlyLogin detected, clearing cookies...');
        }
        await _clearSchoolCookies();
      } else {
        if (kDebugMode) {
          print('ApiService: rememberMe was enabled, keeping cookies.');
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
      final response = await _dio.get('/api/login/init');

      // 儲存初始 Cookies 到 SharedPreferences
      if (response.data['cookies'] != null) {
        await _saveSchoolCookies(response.data['cookies']);
      }

      return response.data;
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
      // 讀取 loginInit 儲存的 Cookies
      final cookieList = await _loadSchoolCookies();

      final response = await _dio.post(
        '/api/login',
        data: {
          'username': username,
          'password': password,
          'captcha': captcha,
          'verificationToken': requestVerificationToken,
          'cookies': cookieList,
          'rememberMe': rememberMe,
        },
      );

      if (response.data['success'] == true) {
        // 儲存登入後取得的最新學校 Cookies
        if (response.data['cookies'] != null) {
          await _saveSchoolCookies(response.data['cookies']);
        }
        // 記錄是否為僅此次登入（重啟後清除）
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_sessionOnlyKey, !rememberMe);
      }
      return response.data;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // ─── 通用認證請求（使用 SharedPreferences 中的 Cookies）──────────────────

  Future<Map<String, dynamic>> _authenticatedPost(
    String path, {
    Map<String, Object?>? data,
    Duration? receiveTimeout,
    Duration? connectTimeout,
  }) async {
    await _ensureInit();
    try {
      final cookieList = await _loadSchoolCookies();

      final requestData = <String, dynamic>{'cookies': cookieList};
      if (data != null) {
        requestData.addAll(data);
      }

      final options = (receiveTimeout != null || connectTimeout != null)
          ? Options(receiveTimeout: receiveTimeout, sendTimeout: connectTimeout)
          : null;

      final response = await _dio.post(
        path,
        data: requestData,
        options: options,
      );

      // 偵測到 401 代表 Session 過期
      if (response.statusCode == 401) {
        await _clearSchoolCookies();
        onSessionExpired?.call();
        return {'status': 'session_expired', 'message': '登入已過期，請重新登入'};
      }

      // API 回傳更新後的 Cookies → 存回 SharedPreferences
      final updatedCookies =
          response.data['finalCookies'] ?? response.data['cookies'];
      if (updatedCookies != null) {
        await _saveSchoolCookies(updatedCookies);
      }

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
      return {'status': 'error', 'message': 'API call to $path failed: $e'};
    }
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    return _authenticatedPost('/api/user-info');
  }

  Future<Map<String, dynamic>> getGrades() async {
    return _authenticatedPost('/api/grades');
  }

  Future<Map<String, dynamic>> getGraduation() async {
    return _authenticatedPost('/api/graduation');
  }

  Future<Map<String, dynamic>> getCalendar(int year) async {
    await _ensureInit();
    try {
      final response = await _dio.get('/api/calendar/$year');
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
      return {
        'status': 'error',
        'message': 'API call to /api/calendar/$year failed: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getHolidays(int year) async {
    await _ensureInit();
    try {
      final response = await _dio.get('/api/holidays/$year');
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
      return {
        'status': 'error',
        'message': 'API call to /api/holidays/$year failed: $e',
      };
    }
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

  Future<Map<String, dynamic>> getSchedule() async {
    return _authenticatedPost('/api/schedule');
  }

  Future<Map<String, dynamic>> getCourseDetail({
    required String year,
    required String semester,
    required String courseNo,
  }) async {
    return _authenticatedPost(
      '/api/schedule/detail',
      data: {'year': year, 'semester': semester, 'courseNo': courseNo},
    );
  }

  Future<void> logout() async {
    await _clearSchoolCookies();
    // CookieJar clearance is handled by the platform-specific implementation if needed
    // However, since we rely on SharedPreferences for school cookies, clearing those is sufficient for logout.
  }
}
