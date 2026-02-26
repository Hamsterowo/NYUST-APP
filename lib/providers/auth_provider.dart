import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  Map<String, dynamic>? _user;
  String? _error;

  // Login Init Data
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

    // 當 API 偵測到 Session 過期 (401) 時，自動登出
    _apiService.onSessionExpired = () async {
      _user = null;
      await _clearUserCache();
      notifyListeners();
    };

    // Check if we have valid cookies/session?
    // For now, let's try to fetch user info to see if logged in
    try {
      final info = await _apiService.getUserInfo();
      if (info['success'] == true) {
        _user = info;
        print(
          'AuthProvider: Session restored! User: ${_user?["user"]?["name"]}',
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_user_info', jsonEncode(info));

        onLoginSuccess?.call(); // 通知 DataProvider 開始預先載入
      } else if (info['status'] == 'session_expired') {
        print('AuthProvider: Session legitimately expired.');
        await _clearUserCache();
      } else {
        // Validation failed, but it might just be a network error.
        final hasCookies = await _apiService.hasSavedCookies();
        if (hasCookies) {
          final prefs = await SharedPreferences.getInstance();
          final cachedStr = prefs.getString('cached_user_info');
          if (cachedStr != null) {
            _user = jsonDecode(cachedStr);
          } else {
            _user = {
              'offline': true,
              'user': {'name': '離線模式'},
            };
          }
          print('AuthProvider: Offline mode active. Using cached user info.');
          onLoginSuccess?.call();
        } else {
          print('AuthProvider: No active session found nor cookies.');
          await _clearUserCache();
        }
      }
    } catch (e) {
      print('AuthProvider: Session restoration failed: $e');
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
      // Clear cookies to ensure a fresh session for login handshake
      await _apiService.logout();

      final data = await _apiService.loginInit();
      _captchaUrl =
          data['captchaImage']; // Worker returns base64 data uri in 'captchaImage'
      _verificationToken =
          data['verificationToken']; // Worker returns 'verificationToken', check if it matches
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
    bool rememberMe,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_verificationToken == null) {
        throw Exception("Captcha not initialized");
      }

      final result = await _apiService.login(
        username,
        password,
        captcha,
        _verificationToken!,
        rememberMe,
      );

      if (result['success'] == true) {
        // Fetch user info to populate state
        final info = await _apiService.getUserInfo();
        _user = info;
        _user?['username'] = username; // Store username if needed

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_user_info', jsonEncode(_user));

        notifyListeners();
        onLoginSuccess?.call(); // 通知 DataProvider 開始預先載入
        return true;
      } else {
        final loginError = '帳號密碼或驗證碼錯誤';
        await fetchCaptcha();
        _error = loginError; // Restore error after fetchCaptcha clears it
        notifyListeners();
        return false;
      }
    } catch (e) {
      final loginError = '帳號密碼或驗證碼錯誤';
      await fetchCaptcha();
      _error = loginError; // Restore error after fetchCaptcha clears it
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    await _clearUserCache();
    _user = null;
    onLogoutCallback?.call(); // 通知 DataProvider 清除快取
    notifyListeners();
  }

  Future<void> _clearUserCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_user_info');
  }

  ApiService get api => _apiService;
}
