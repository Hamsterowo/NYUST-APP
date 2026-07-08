import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/yuntech_app_crypto.dart';

/// Client for the official app's MobileAppService backend (Bearer-token API).
///
/// This is **deliberately isolated** from the web-scraping [ApiClient]: it uses
/// its own [Dio] with **no cookie jar**, so the `.YunTechSSO` cookie the
/// `/Token` endpoint returns never overwrites the web-login session that the
/// existing HTML scrapers depend on. The two auth worlds stay separate:
///   - web login (captcha) → `.YunTechSSO` cookie → existing scrapers
///   - app login (`/Token`) → Bearer token → `/api/...` features (this class)
///
/// See `docs/mobile_api.md`.
class AppApiService {
  static const String _baseUrl =
      'https://webapp.yuntech.edu.tw/MobileAppService';
  static const String _appVersion = '1.10.3';

  static const String _tokenKey = 'app_api_access_token';
  static const String _userIdKey = 'app_api_user_id';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      validateStatus: (status) => status != null && status < 500,
    ),
  );
  final _storage = const FlutterSecureStorage();

  String? _accessToken;
  String? _userId;

  bool get hasToken => _accessToken != null && _accessToken!.isNotEmpty;

  /// Loads a previously persisted token (call on startup).
  Future<void> loadPersisted() async {
    try {
      _accessToken = await _storage.read(key: _tokenKey);
      _userId = await _storage.read(key: _userIdKey);
    } catch (_) {}
  }

  /// Logs in via `POST /Token` (OAuth2 password grant, no captcha) and stores
  /// the Bearer token. Returns true on success. Never throws.
  Future<bool> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/Token',
        data: {
          'grant_type': 'password',
          'username': username,
          'password': YuntechAppCrypto.sha256Hex(password),
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.json,
          headers: _commonHeaders(username),
        ),
      );

      if (response.statusCode == 200) {
        final data = _asMap(response.data);
        final token = data['access_token'] as String?;
        if (token != null && token.isNotEmpty) {
          _accessToken = token;
          _userId = username;
          await _storage.write(key: _tokenKey, value: token);
          await _storage.write(key: _userIdKey, value: username);
          return true;
        }
      }
    } catch (e) {
      if (kDebugMode) print('AppApiService.login error: $e');
    }
    return false;
  }

  /// GET the current-semester enrollment certificate (在學證明) as PDF bytes.
  /// Returns null if not logged in, not registered (503), or on error.
  Future<Uint8List?> getYunReport() async {
    if (!hasToken) return null;
    try {
      final response = await _dio.get(
        '/api/User/GetYunReport',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            ..._commonHeaders(_userId ?? ''),
            'Authorization': 'Bearer $_accessToken',
          },
        ),
      );
      final data = response.data;
      if (response.statusCode == 200 && data is List<int>) {
        return Uint8List.fromList(data);
      }
    } catch (e) {
      if (kDebugMode) print('AppApiService.getYunReport error: $e');
    }
    return null;
  }

  Future<void> clear() async {
    _accessToken = null;
    _userId = null;
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userIdKey);
    } catch (_) {}
  }

  Map<String, String> _commonHeaders(String userId) => {
    'X-User-App-Platform':
        defaultTargetPlatform == TargetPlatform.iOS ? 'iOS' : 'Android',
    'X-User-App-Version-Name': _appVersion,
    'X-User-Nonce': YuntechAppCrypto.buildNonce(
      userId: userId,
      appVersion: _appVersion,
    ),
  };

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
