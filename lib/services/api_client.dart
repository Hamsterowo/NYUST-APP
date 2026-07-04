import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:intl/intl.dart';
import 'cookie_manager/cookie_manager_api.dart' as cookie_mgr;

/// 共用的 HTTP 客戶端。
///
/// 集中管理整個 App 唯一的 [Dio] instance、Cookie 管理與 [LanguageInterceptor]。
/// 各個 feature Service 都透過此類別發送請求，不再各自建立 Dio。
///
/// 兩種請求風格共用同一個 Dio：相對路徑（例如 `/api/report`）會打到 [baseUrl]
/// （App 自己的後端），而 scrapers 會對 `webapp.yuntech.edu.tw` 發出**絕對** URL
/// 繞過 [baseUrl]。
class ApiClient {
  late final Dio dio;
  final String baseUrl = 'https://cf-api.nyust-plus.com';

  bool _initStarted = false;
  bool _isInit = false;

  /// Session 過期時的回呼（保留給上層設定）。
  VoidCallback? onSessionExpired;

  static const String _apiSecretKey = String.fromEnvironment(
    'API_SECRET',
    defaultValue: '',
  );

  ApiClient() {
    dio = Dio(
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
    dio.interceptors.add(LanguageInterceptor());
  }

  /// 初始化 Cookie 管理。冪等，並防止並行重複初始化。
  Future<void> init() async {
    if (_isInit) return;
    if (_initStarted) {
      while (!_isInit) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }
    _initStarted = true;

    try {
      await cookie_mgr.setupCookieManager(dio);
      _isInit = true;
    } catch (e) {
      if (kDebugMode) print('ApiClient: Init failed: $e');
      _initStarted = false;
      rethrow;
    }
  }

  /// 確保已初始化後再繼續。
  Future<void> ensureInit() async {
    if (!_isInit) {
      await init();
    }
  }

  /// 檢查是否有儲存的學校 Cookies
  Future<bool> hasSavedCookies() async {
    final cookieJar = dio.interceptors
        .whereType<CookieManager>()
        .firstOrNull
        ?.cookieJar;
    if (cookieJar == null) return false;
    final cookies = await cookieJar.loadForRequest(
      Uri.parse('https://webapp.yuntech.edu.tw'),
    );
    return cookies.isNotEmpty;
  }

  /// 取得特定網域的 Cookies
  Future<List<Cookie>> getCookiesForUri(Uri uri) async {
    final cookieJar = dio.interceptors
        .whereType<CookieManager>()
        .firstOrNull
        ?.cookieJar;
    if (cookieJar == null) return [];
    return await cookieJar.loadForRequest(uri);
  }

  /// 清除所有 Cookies（登出時使用）
  Future<void> clearCookies() async {
    await cookie_mgr.clearCookies();
  }
}

class LanguageInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final uri = options.uri;
    final path = uri.path.toLowerCase();

    // Only intercept student portal pages (WebNewCAS and eStudent) on webapp.yuntech.edu.tw
    if (uri.host == 'webapp.yuntech.edu.tw' &&
        (path.contains('/webnewcas/') || path.contains('/estudent/'))) {
      String languageCode = 'zh';
      try {
        if (Intl.defaultLocale != null && Intl.defaultLocale!.isNotEmpty) {
          languageCode = Intl.defaultLocale!
              .split('_')
              .first
              .split('-')
              .first
              .toLowerCase();
        } else {
          languageCode = ui.PlatformDispatcher.instance.locale.languageCode
              .toLowerCase();
        }
      } catch (_) {
        try {
          languageCode = ui.PlatformDispatcher.instance.locale.languageCode
              .toLowerCase();
        } catch (_) {}
      }

      final langValue = languageCode == 'en' ? 'en' : 'zh-TW';

      String currentPath = options.path;
      if (!currentPath.contains('lang=')) {
        if (currentPath.contains('?')) {
          final lastChar = currentPath.substring(currentPath.length - 1);
          if (lastChar == '?' || lastChar == '&') {
            currentPath = '${currentPath}lang=$langValue';
          } else {
            currentPath = '$currentPath&lang=$langValue';
          }
        } else {
          currentPath = '$currentPath?lang=$langValue';
        }
        options.path = currentPath;
      }
    }
    super.onRequest(options, handler);
  }
}
