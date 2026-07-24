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
    // 順序固定為 [LanguageInterceptor, CookieManager]。Cookie 管理於建構時
    // 同步掛上（見 [attachCookieManager]），因此 client 一 new 出來即完全可用，
    // 不再有 init()/ensureInit() 的非同步初始化時序。
    dio.interceptors.add(LanguageInterceptor());
    cookie_mgr.attachCookieManager(dio);
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
