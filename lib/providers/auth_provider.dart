import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  Map<String, dynamic>? _user;
  String? _error;

  final _secureStorage = const FlutterSecureStorage();
  static const String _cachedUserInfoKey = 'cached_user_info';

  Future<String?> _loadUserCache() async {
    // 1. 嘗試從安全儲存區讀取
    final raw = await _secureStorage.read(key: _cachedUserInfoKey);
    if (raw != null && raw.isNotEmpty) {
      return raw;
    }

    // 2. 若無，自 SharedPreferences 轉移舊明文資料
    try {
      final prefs = await SharedPreferences.getInstance();
      final oldRaw = prefs.getString(_cachedUserInfoKey);
      if (oldRaw != null && oldRaw.isNotEmpty) {
        await _secureStorage.write(key: _cachedUserInfoKey, value: oldRaw);
        await prefs.remove(_cachedUserInfoKey);
        if (kDebugMode) {
          print('AuthProvider: Migrated user info to FlutterSecureStorage');
        }
        return oldRaw;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _saveUserCache(Map<String, dynamic> info) async {
    await _secureStorage.write(key: _cachedUserInfoKey, value: jsonEncode(info));
  }

  Future<void> _clearUserCache() async {
    await _secureStorage.delete(key: _cachedUserInfoKey);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedUserInfoKey);
    } catch (_) {}
  }

  String? _captchaUrl;
  String? _verificationToken;
  bool _isInitialized = false;

  /// 登入成功後的回呼，由 DataProvider 設定
  VoidCallback? onLoginSuccess;

  /// 登出時的回呼，由 DataProvider 設定
  VoidCallback? onLogoutCallback;

  AuthProvider() {
    init();
  }

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _user != null;
  Map<String, dynamic>? get user => _user;
  String? get error => _error;
  String? get captchaUrl => _captchaUrl;

  Future<void> init() async {
    await _apiService.init();

    _apiService.onSessionExpired = () async {
      _user = null;
      await _clearUserCache();
      notifyListeners();
    };

    final hasCookies = await _apiService.hasSavedCookies();

    if (!hasCookies) {
      final cachedStr = await _loadUserCache();
      if (cachedStr != null) {
        final cachedUser = jsonDecode(cachedStr);
        if (cachedUser['user']?['id'] == 'D11012345') {
          _apiService.isMockMode = true;
          _user = cachedUser;
          _isInitialized = true;
          notifyListeners();
          onLoginSuccess?.call();
          return;
        }
      }
      await _clearUserCache();
      _isInitialized = true;
      notifyListeners();
      return;
    }

    // Load cached user info immediately if available, so that isLoggedIn is true from startup
    try {
      final cachedStr = await _loadUserCache();
      if (cachedStr != null) {
        final cachedUser = jsonDecode(cachedStr);
        _user = cachedUser;
        if (cachedUser['user']?['id'] == 'D11012345') {
          _apiService.isMockMode = true;
        }
        notifyListeners();
        onLoginSuccess?.call();
      }
    } catch (_) {}

    try {
      final info = await _apiService.getUserInfo();

      final bool hasValidUser = info['user'] != null &&
          info['user']['name'] != null &&
          info['user']['name'].toString().trim().isNotEmpty;

      if (info['success'] == true && hasValidUser) {
        _user = info;
        await _saveUserCache(info);
        onLoginSuccess?.call();
      } else if (info['status'] == 'session_expired' ||
          info['success'] == false ||
          (info['success'] == true && !hasValidUser)) {

        _user = null;
        await _clearUserCache();
        await _apiService.logout();
      } else if (info['status'] == 'error') {
        final cachedStr = await _loadUserCache();
        if (cachedStr != null) {
          _user = jsonDecode(cachedStr);
          onLoginSuccess?.call();
        } else {
          await _clearUserCache();
        }
      } else {
        await _clearUserCache();
        await _apiService.logout();
      }
    } catch (e) {
      try {
        final cachedStr = await _loadUserCache();
        if (cachedStr != null) {
          _user = jsonDecode(cachedStr);
          onLoginSuccess?.call();
        }
      } catch (_) {}
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> fetchCaptcha() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {

      await _apiService.logout();
      await _apiService.init();

      final data = await _apiService.loginInit();
      if (data['success'] == true) {
        _captchaUrl = data['captchaImage'];
        _verificationToken = data['verificationToken'];
      } else {
        throw Exception(data['message'] ?? 'Failed to init login');
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(
    String username,
    String password,
    String captcha,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {

      if (username == 'debug' || username.toLowerCase() == 'test') {
        _apiService.isMockMode = true;
        _user = {
          'success': true,
          'user': {
            'name': '開發除錯員',
            'id': 'D11012345',
            'dept': '資訊工程學系',
            'class': '資工三甲',
          },
          'username': username,
        };
        await _saveUserCache(_user!);
        _isLoading = false;
        notifyListeners();
        onLoginSuccess?.call();
        return true;
      }

      if (_verificationToken == null) {
        throw Exception("Captcha not initialized");
      }

      final result = await _apiService.login(
        username,
        password,
        captcha,
        _verificationToken!,
      );

      if (result['success'] == true) {

        final info = await _apiService.getUserInfo();
        _user = info;
        _user?['username'] = username;

        await _saveUserCache(_user!);

        notifyListeners();
        onLoginSuccess?.call();
        return true;
      } else {
        final loginError = '帳密或驗證碼錯誤';
        await fetchCaptcha();
        _error = loginError;
        notifyListeners();
        return false;
      }
    } catch (e) {
      final loginError = '帳密或驗證碼錯誤';
      await fetchCaptcha();
      _error = loginError;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _apiService.isMockMode = false;
    await _apiService.logout();
    await _clearUserCache();
    _user = null;
    onLogoutCallback?.call();
    notifyListeners();
  }

  /// 更新使用者資料 (用於重新整理功能)
  void updateUserInfo(Map<String, dynamic> info) {
    _user = info;
    notifyListeners();
    _saveUserCache(info);
  }

  ApiService get api => _apiService;
}
