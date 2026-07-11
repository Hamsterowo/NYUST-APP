import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/yuntech_app_crypto.dart';
import '../server_time_service.dart';

/// Thrown by app-endpoint calls when the Bearer token is missing/expired and
/// there is **no saved credential** to silently re-mint it — the UI should
/// prompt the user for their password (see `AppApiPasswordDialog`).
class AppApiAuthRequiredException implements Exception {
  const AppApiAuthRequiredException();
  @override
  String toString() => 'AppApiAuthRequiredException';
}

/// Client for the official app's MobileAppService backend (Bearer-token API).
///
/// This is **deliberately isolated** from the web-scraping [ApiClient]: it uses
/// its own [Dio] with **no cookie jar**, so the `.YunTechSSO` cookie the
/// `/Token` endpoint returns never overwrites the web-login session that the
/// existing HTML scrapers depend on. The two auth worlds stay separate:
///   - web login (captcha) → `.YunTechSSO` cookie → existing scrapers
///   - app login (`/Token`) → Bearer token → `/api/...` features (this class)
///
/// The Bearer token lasts ~90 days and there is no refresh-token endpoint, so
/// re-login is the only way to mint a fresh one. To survive token expiry without
/// forcing a full captcha login, this class can optionally persist the SHA-256
/// **hash** of the password (never the plaintext) — `/Token` only needs the
/// hash. Persisting is **opt-in** (`remember`); an in-memory hash is also kept
/// for the current session so a 401 can self-heal even when the user chose not
/// to persist. On a 401 the token is silently re-minted and the call retried
/// once; if no credential is available, [AppApiAuthRequiredException] is thrown.
///
/// See `docs/mobile_api.md`.
class AppApiService {
  static const String _baseUrl =
      'https://webapp.yuntech.edu.tw/MobileAppService';
  static const String _appVersion = '1.10.3';

  static const String _tokenKey = 'app_api_access_token';
  static const String _userIdKey = 'app_api_user_id';
  static const String _pwdHashKey = 'app_api_pwd_hash';
  static const String _expiryKey = 'app_api_token_expiry';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      validateStatus: (status) => status != null && status < 500,
    ),
  );
  final _storage = const FlutterSecureStorage();

  /// Default constructor. Tests may pass a fake [httpClientAdapter] to drive the
  /// `/Token` and `/api/...` calls without real network; production leaves it
  /// null so the real HTTP client is used.
  AppApiService({HttpClientAdapter? httpClientAdapter}) {
    if (httpClientAdapter != null) {
      _dio.httpClientAdapter = httpClientAdapter;
    }
    // 讓這個獨立 client（含 /Token）的回應也更新伺服器時間偏移量，
    // 使 nonce 的校正時間能在登入當下即時可用。
    _dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          ServerTimeService.instance.reportServerDate(
            response.headers.value('date'),
          );
          handler.next(response);
        },
      ),
    );
  }

  String? _accessToken;
  String? _userId;

  /// SHA-256 hash of the password. Held in memory for the current session; also
  /// persisted only when the user opted in to "remember password".
  String? _passwordHash;

  /// Best-effort token expiry (from `/Token`'s `expires_in`), kept for display
  /// on the credential settings page only — refresh is reactive on 401, so this
  /// is never used to decide when to refresh.
  DateTime? _tokenExpiry;

  /// Demo/mock mode: the demo account never really hits `/Token`, so we seed a
  /// fake token + expiry (and short-circuit network calls) purely so the
  /// credential settings page has sample data to show.
  bool _mockMode = false;

  /// Enables/disables mock mode, seeding or clearing the demo credential.
  void setMockMode(bool value) {
    _mockMode = value;
    if (value) {
      _accessToken = 'mock-access-token';
      _userId = 'B12345678';
      _tokenExpiry = DateTime.now().add(const Duration(days: 90));
      _passwordHash = null; // "remember password" starts off in the demo
    } else {
      _accessToken = null;
      _userId = null;
      _tokenExpiry = null;
      _passwordHash = null;
    }
  }

  /// Seeds the student ID used for app-endpoint logins from the authoritative
  /// web SSO session, when it isn't already known. The app endpoint logs in
  /// with the **same** student ID as the web portal, so as long as the user is
  /// logged in on the web we can always mint/refresh a Bearer token — including
  /// for users who upgraded from a version that never stored it, or whose
  /// background `/Token` call happened to fail at login time. Kept in memory
  /// only (re-seeded each launch from the live session); never overrides an id
  /// already obtained from a real `/Token` response.
  void ensureUserId(String? id) {
    if (_mockMode) return;
    if (id == null || id.isEmpty) return;
    if (_userId != null && _userId!.isNotEmpty) return;
    _userId = id;
  }

  bool get hasToken => _accessToken != null && _accessToken!.isNotEmpty;

  /// Approximate expiry of the current token, or null if unknown / no token.
  DateTime? get tokenExpiry => _tokenExpiry;

  /// Whether a credential is available (in-memory this session or persisted)
  /// that can silently re-mint an expired token without prompting the user.
  bool get hasSavedCredential =>
      _passwordHash != null && _passwordHash!.isNotEmpty;

  /// Whether the password hash is **persisted** (survives restart) — i.e. the
  /// "remember password" setting is currently on.
  Future<bool> isPasswordRemembered() async {
    if (_mockMode) return _passwordHash != null;
    try {
      final v = await _storage.read(key: _pwdHashKey);
      return v != null && v.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Turns the persisted "remember password" setting on/off from the settings
  /// page. Returns true when applied. When enabling but no in-memory credential
  /// is available (e.g. token was restored from storage without the hash),
  /// returns false so the caller can prompt for the password via
  /// [reloginWithPassword].
  Future<bool> setRememberPassword(bool value) async {
    if (_mockMode) {
      _passwordHash = value ? 'mock-hash' : null;
      return true;
    }
    try {
      if (value) {
        if (!hasSavedCredential) return false;
        await _storage.write(key: _pwdHashKey, value: _passwordHash!);
        return true;
      }
      await _storage.delete(key: _pwdHashKey);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Loads a previously persisted token + credential (call on startup).
  Future<void> loadPersisted() async {
    try {
      _accessToken = await _storage.read(key: _tokenKey);
      _userId = await _storage.read(key: _userIdKey);
      _passwordHash = await _storage.read(key: _pwdHashKey);
      final expiryStr = await _storage.read(key: _expiryKey);
      _tokenExpiry = expiryStr == null ? null : DateTime.tryParse(expiryStr);
    } catch (_) {}
  }

  /// Logs in via `POST /Token` (OAuth2 password grant, no captcha) and stores
  /// the Bearer token. When [remember] is true the SHA-256 password hash is
  /// persisted so the token can be silently re-minted after it expires; when
  /// false any previously-persisted hash is cleared (but a session-only copy is
  /// still kept in memory). Returns true on success. Never throws.
  Future<bool> login(
    String username,
    String password, {
    bool remember = false,
  }) async {
    final hash = YuntechAppCrypto.sha256Hex(password);
    final ok = await _requestToken(username, hash);
    if (ok) {
      _passwordHash = hash;
      try {
        if (remember) {
          await _storage.write(key: _pwdHashKey, value: hash);
        } else {
          await _storage.delete(key: _pwdHashKey);
        }
      } catch (_) {}
    }
    return ok;
  }

  /// Re-authenticates using a plaintext password (from the on-demand prompt when
  /// the token expired and nothing was remembered). Uses the already-known
  /// [_userId]. Persists the hash only when [remember] is true.
  Future<bool> reloginWithPassword(
    String password, {
    bool remember = false,
  }) async {
    if (_mockMode) {
      _passwordHash = remember ? 'mock-hash' : _passwordHash;
      return true;
    }
    final userId = _userId;
    if (userId == null || userId.isEmpty) return false;
    final hash = YuntechAppCrypto.sha256Hex(password);
    final ok = await _requestToken(userId, hash);
    if (ok) {
      _passwordHash = hash;
      try {
        if (remember) {
          await _storage.write(key: _pwdHashKey, value: hash);
        }
      } catch (_) {}
    }
    return ok;
  }

  /// POST /Token with an already-hashed password; stores token + userId on
  /// success. The single place the token is minted. Never throws.
  Future<bool> _requestToken(String username, String passwordHash) async {
    try {
      final response = await _dio.post(
        '/Token',
        data: {
          'grant_type': 'password',
          'username': username,
          'password': passwordHash,
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
          _tokenExpiry = _parseExpiry(data['expires_in']);
          await _storage.write(key: _tokenKey, value: token);
          await _storage.write(key: _userIdKey, value: username);
          if (_tokenExpiry != null) {
            await _storage.write(
              key: _expiryKey,
              value: _tokenExpiry!.toIso8601String(),
            );
          } else {
            await _storage.delete(key: _expiryKey);
          }
          return true;
        }
      }
    } catch (e) {
      if (kDebugMode) print('AppApiService._requestToken error: $e');
    }
    return false;
  }

  /// Converts a `/Token` `expires_in` (seconds) into an absolute expiry.
  DateTime? _parseExpiry(dynamic expiresIn) {
    final secs = expiresIn is int
        ? expiresIn
        : (expiresIn is String ? int.tryParse(expiresIn) : null);
    if (secs == null || secs <= 0) return null;
    return DateTime.now().add(Duration(seconds: secs));
  }

  /// Silently re-mints the token from the saved credential. Returns false when
  /// no credential is available or the re-login fails.
  Future<bool> _refreshToken() async {
    final userId = _userId;
    if (!hasSavedCredential || userId == null || userId.isEmpty) return false;
    return _requestToken(userId, _passwordHash!);
  }

  /// GET the current-semester enrollment certificate (在學證明) as PDF bytes.
  /// Returns null if not registered (503) or on network/other error.
  /// Throws [AppApiAuthRequiredException] when the token expired and there is no
  /// saved credential to refresh it (caller should prompt for the password).
  Future<Uint8List?> getYunReport() async {
    // The demo account has no real token; instead of hitting the network,
    // serve a bundled sample PDF (an easter egg) so the demo shows a real
    // document instead of an error/prompt.
    if (_mockMode) {
      try {
        final data = await rootBundle.load('assets/demo_yun_report.pdf');
        return data.buffer.asUint8List();
      } catch (_) {
        return null;
      }
    }
    return _authedGetBytes('/api/User/GetYunReport');
  }

  /// Runs an authenticated GET returning bytes, transparently handling token
  /// expiry: ensures a token (refreshing from the saved credential if needed),
  /// and on a 401 re-mints once and retries. Throws
  /// [AppApiAuthRequiredException] when no credential can satisfy the request.
  /// Returns null on network/other/503 errors.
  Future<Uint8List?> _authedGetBytes(String path) async {
    if (!hasToken) {
      if (!await _refreshToken()) throw const AppApiAuthRequiredException();
    }
    try {
      var response = await _get(path);
      if (response.statusCode == 401) {
        if (!await _refreshToken()) throw const AppApiAuthRequiredException();
        response = await _get(path);
        if (response.statusCode == 401) {
          throw const AppApiAuthRequiredException();
        }
      }
      final data = response.data;
      if (response.statusCode == 200 && data is List<int>) {
        return Uint8List.fromList(data);
      }
    } on AppApiAuthRequiredException {
      rethrow;
    } catch (e) {
      if (kDebugMode) print('AppApiService._authedGetBytes($path) error: $e');
    }
    return null;
  }

  Future<Response<dynamic>> _get(String path) => _dio.get(
    path,
    options: Options(
      responseType: ResponseType.bytes,
      headers: {
        ..._commonHeaders(_userId ?? ''),
        'Authorization': 'Bearer $_accessToken',
      },
    ),
  );

  Future<void> clear() async {
    _mockMode = false;
    _accessToken = null;
    _userId = null;
    _passwordHash = null;
    _tokenExpiry = null;
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userIdKey);
      await _storage.delete(key: _pwdHashKey);
      await _storage.delete(key: _expiryKey);
    } catch (_) {}
  }

  Map<String, String> _commonHeaders(String userId) => {
    'X-User-App-Platform': defaultTargetPlatform == TargetPlatform.iOS
        ? 'iOS'
        : 'Android',
    'X-User-App-Version-Name': _appVersion,
    'X-User-Nonce': YuntechAppCrypto.buildNonce(
      userId: userId,
      appVersion: _appVersion,
      now: ServerTimeService.instance.now(),
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
