import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:intl/intl.dart';
import 'cookie_manager/cookie_manager_api.dart' as cookie_mgr;
import 'server_time_service.dart';

/// 共用的 HTTP 客戶端。
///
/// 集中管理整個 App 唯一的 [Dio] instance、Cookie 管理與 [LanguageInterceptor]。
/// 各個 feature Service 都透過此類別發送請求，不再各自建立 Dio。
///
/// 所有請求皆為對外部網站（主要為 `webapp.yuntech.edu.tw`）的**絕對** URL；
/// App 本身沒有任何自架後端。
class ApiClient {
  late final Dio dio;

  bool _initStarted = false;
  bool _isInit = false;

  /// Session 過期時的回呼（保留給上層設定）。
  VoidCallback? onSessionExpired;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        validateStatus: (status) {
          return status! < 500;
        },
        headers: {'Content-Type': 'application/json'},
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
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 從每個回應的 Date header 更新伺服器時間偏移量，供校正時間與誤差橫幅使用。
    ServerTimeService.instance.reportServerDate(response.headers.value('date'));
    super.onResponse(response, handler);
  }

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
