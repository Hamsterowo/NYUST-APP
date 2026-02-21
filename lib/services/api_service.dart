import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ApiService {
  late Dio _dio;
  PersistCookieJar? _cookieJar; // Make nullable
  final String baseUrl =
      'https://nyust-api.hamsterowo.workers.dev'; // Replace with your worker URL if different
  bool _initStarted = false;

  /// 當 API 回傳 401 Session 過期時觸發，由 AuthProvider 設定
  VoidCallback? onSessionExpired;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        validateStatus: (status) {
          return status! < 500; // Accept all 2xx, 3xx, 4xx
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
      // Simple wait if already started
      while (_cookieJar == null) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      return;
    }
    _initStarted = true;

    print('ApiService: Initializing CookieJar...');
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;
      print('ApiService: App Doc Path: $appDocPath');

      _cookieJar = PersistCookieJar(
        storage: FileStorage("$appDocPath/.cookies/"),
      );
      _dio.interceptors.add(CookieManager(_cookieJar!));
      print('ApiService: CookieJar initialized successfully');
    } catch (e) {
      print('ApiService: Failed to initialize CookieJar: $e');
      _initStarted = false; // Allow retry
      throw e;
    }
  }

  Future<void> _ensureInit() async {
    if (_cookieJar == null) {
      await init();
    }
  }

  // Step 1: Get Captcha & Token
  Future<Map<String, dynamic>> loginInit() async {
    await _ensureInit();
    try {
      final response = await _dio.get('/api/login/init');

      // Manual Cookie Saving for init
      if (response.data['cookies'] != null) {
        List<dynamic> newCookiesData = response.data['cookies'];
        List<Cookie> newCookies = newCookiesData.map((c) {
          Cookie cookie = Cookie(c['key'], c['value']);
          if (c['domain'] != null) cookie.domain = c['domain'];
          if (c['path'] != null) cookie.path = c['path'];
          return cookie;
        }).toList();

        await _cookieJar!.saveFromResponse(Uri.parse(baseUrl), newCookies);
      }

      // Debug: Check cookies after init
      List<Cookie> cookies = await _cookieJar!.loadForRequest(
        Uri.parse(baseUrl),
      );
      print('Cookies after loginInit: ${cookies.length}');
      for (var c in cookies) {
        print(
          ' - ${c.name}: ${c.value} (Domain: ${c.domain}, Path: ${c.path})',
        );
      }

      return response.data;
    } catch (e) {
      print('LoginInit Failed: $e'); // Add error logging
      throw Exception('Failed to init login: $e');
    }
  }

  // Step 2: Login
  Future<Map<String, dynamic>> login(
    String username,
    String password,
    String captcha,
    String requestVerificationToken,
    bool rememberMe,
  ) async {
    await _ensureInit();
    try {
      List<Cookie> currentCookies = await _cookieJar!.loadForRequest(
        Uri.parse(baseUrl),
      );
      final cookieList = currentCookies
          .map(
            (c) => {
              'key': c.name,
              'value': c.value,
              'domain': c.domain,
              'path': c.path,
              'secure': c.secure,
              'httpOnly': c.httpOnly,
              'hostOnly': false,
              'creation': null,
              'lastAccessed': null,
            },
          )
          .toList();

      print(
        'Sending Login Request: username=$username, captcha=$captcha, token=$requestVerificationToken',
      );
      final response = await _dio.post(
        '/api/login',
        data: {
          'username': username,
          'password': password,
          'captcha': captcha,
          'verificationToken': requestVerificationToken,
          'cookies': cookieList, // Send current cookies (from init)
          'rememberMe': rememberMe,
        },
      );
      print('Login Response: ${response.data}');

      if (response.data['success'] == true) {
        // Update local JAR with new cookies from response
        if (response.data['cookies'] != null) {
          List<dynamic> newCookiesData = response.data['cookies'];
          List<Cookie> newCookies = newCookiesData.map((c) {
            Cookie cookie = Cookie(c['key'], c['value']);
            if (c['domain'] != null) cookie.domain = c['domain'];
            if (c['path'] != null) cookie.path = c['path'];
            // ... set other properties if needed
            return cookie;
          }).toList();

          await _cookieJar!.saveFromResponse(Uri.parse(baseUrl), newCookies);
        }
      }
      return response.data;
    } catch (e) {
      print('Login Error: $e');
      if (e is DioException) {
        print('DioError Response: ${e.response?.data}');
      }
      throw Exception('Login failed: $e');
    }
  }

  // Generic helper to call API with cookies
  Future<Map<String, dynamic>> _authenticatedPost(String path) async {
    await _ensureInit();
    try {
      List<Cookie> currentCookies = await _cookieJar!.loadForRequest(
        Uri.parse(baseUrl),
      );
      final cookieList = currentCookies
          .map((c) => {'key': c.name, 'value': c.value})
          .toList();

      final response = await _dio.post(path, data: {'cookies': cookieList});

      // 偵測到 401 代表 Session 過期
      if (response.statusCode == 401) {
        await _cookieJar!.deleteAll();
        onSessionExpired?.call();
        return {'status': 'session_expired', 'message': '登入已過期，請重新登入'};
      }

      // Update cookies if returned
      if (response.data['cookies'] != null) {
        List<dynamic> newCookiesData = response.data['cookies'];
        List<Cookie> newCookies = newCookiesData.map((c) {
          Cookie cookie = Cookie(c['key'], c['value']);
          if (c['domain'] != null) cookie.domain = c['domain'];
          if (c['path'] != null) cookie.path = c['path'];
          return cookie;
        }).toList();
        await _cookieJar!.saveFromResponse(Uri.parse(baseUrl), newCookies);
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
    if (_cookieJar != null) {
      await _cookieJar!.deleteAll();
    }
  }
}
