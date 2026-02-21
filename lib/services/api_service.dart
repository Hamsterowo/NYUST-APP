import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

class ApiService {
  late Dio _dio;
  PersistCookieJar? _cookieJar;
  final String baseUrl = 'https://nyust-api.hamsterowo.workers.dev';
  bool _initStarted = false;

  // SharedPreferences 的 key，用來儲存學校 Cookies
  static const String _schoolCookiesKey = 'school_session_cookies';
  // 記錄此次登入是否為「僅此次（不保持登入）」
  static const String _sessionOnlyKey = 'session_only_login';

  /// 當 API 回傳 401 Session 過期時觸發，由 AuthProvider 設定
  VoidCallback? onSessionExpired;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        validateStatus: (status) {
          return status! < 500;
        },
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  Future<void> init() async {
    if (_cookieJar != null) return;
    if (_initStarted) {
      while (_cookieJar == null) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      return;
    }
    _initStarted = true;

    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;

      _cookieJar = PersistCookieJar(
        storage: FileStorage("$appDocPath/.cookies/"),
      );
      _dio.interceptors.add(CookieManager(_cookieJar!));

      // 若上次登入沒有勾選「保持登入」，重啟時自動清除 cookies
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_sessionOnlyKey) == true) {
        await _clearSchoolCookies();
      }
    } catch (e) {
      _initStarted = false;
      throw e;
    }
  }

  Future<void> _ensureInit() async {
    if (_cookieJar == null) {
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
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// 將學校 Cookies 儲存到 SharedPreferences
  Future<void> _saveSchoolCookies(List<dynamic> cookies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_schoolCookiesKey, jsonEncode(cookies));
  }

  /// 清除學校 Cookies
  Future<void> _clearSchoolCookies() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_schoolCookiesKey);
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

  Future<Map<String, dynamic>> _authenticatedPost(String path) async {
    await _ensureInit();
    try {
      // 直接從 SharedPreferences 讀取，不受 domain 匹配限制
      final cookieList = await _loadSchoolCookies();

      final response = await _dio.post(path, data: {'cookies': cookieList});

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

  Future<Map<String, dynamic>> getSchedule() async {
    return _authenticatedPost('/api/schedule');
  }

  Future<void> logout() async {
    await _clearSchoolCookies();
    if (_cookieJar != null) {
      await _cookieJar!.deleteAll();
    }
  }
}
