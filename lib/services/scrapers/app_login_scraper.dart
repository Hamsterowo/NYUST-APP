import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../utils/yuntech_app_crypto.dart';
import 'base_scraper.dart';

/// Logs in through the official 行動雲科 app's backend
/// (`MobileAppService`, OAuth2 password grant at `/Token`).
///
/// Unlike [SsoScraper] this path needs **no image captcha**. The `/Token`
/// response also sets the `.YunTechSSO` session cookie, which the shared
/// [Dio] cookie jar captures — so the existing web-page scrapers (grades,
/// graduation, schedule, info) keep working after this login.
///
/// See `docs/mobile_api.md` for the full contract.
class AppLoginScraper extends BaseScraper {
  AppLoginScraper(super.dio);

  static const String baseUrl =
      'https://webapp.yuntech.edu.tw/MobileAppService';
  static const String tokenUrl = '$baseUrl/Token';

  /// The version the official app reports. Intentionally the value hard-coded
  /// in the app (`Settings.UserAppVersionName`), which lags the real package
  /// version — the server does not enforce it. Must match the `version=` field
  /// baked into the nonce.
  static const String appVersion = '1.10.3';

  /// Performs the app-endpoint login. Returns a map with `success` plus, on
  /// success, `accessToken` / `expiresIn` / `userName` / `userType`.
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final nonce = YuntechAppCrypto.buildNonce(
        userId: username,
        appVersion: appVersion,
      );

      final response = await dio.post(
        tokenUrl,
        data: {
          'grant_type': 'password',
          'username': username,
          'password': YuntechAppCrypto.sha256Hex(password),
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.json,
          headers: {
            'X-User-App-Platform': defaultTargetPlatform == TargetPlatform.iOS
                ? 'iOS'
                : 'Android',
            'X-User-App-Version-Name': appVersion,
            'X-User-Nonce': nonce,
            'Accept': 'application/json',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final data = _asMap(response.data);

      if (response.statusCode == 200) {
        final token = data['access_token'] as String?;
        if (token != null && token.isNotEmpty) {
          return {
            'success': true,
            'accessToken': token,
            'expiresIn': data['expires_in'],
            'userName': data['UserName'],
            'userType': data['UserType'],
          };
        }
      }

      // OAuth error (typically {"error":"invalid_grant"}) or unexpected body.
      final error = data['error'];
      final message = error == 'invalid_grant'
          ? '帳號或密碼錯誤'
          : '登入失敗，請檢查帳號密碼（${response.statusCode}）';
      return {
        'success': false,
        'message': message,
        'statusCode': response.statusCode,
      };
    } catch (e) {
      if (kDebugMode) print('AppLoginScraper Error: $e');
      return {'success': false, 'message': '登入請求發生錯誤: $e'};
    }
  }

  /// Normalises the Dio response body (Map when auto-decoded as JSON, String
  /// otherwise) into a `Map`.
  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return const {};
  }
}
