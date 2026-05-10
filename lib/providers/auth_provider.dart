import 'dart:convert';
import 'package:flutter/foundation.dart';
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

    // 檢查是否有儲存的學校 Cookies
    final hasCookies = await _apiService.hasSavedCookies();

    if (!hasCookies) {
      await _clearUserCache();
      _isInitialized = true;
      notifyListeners();
      return;
    }

    // 有 Cookies 才有機會恢復 Session
    try {
      final info = await _apiService.getUserInfo();

      // 嚴格檢查：必須有 user 物件，且名稱（或 ID）不能為空
      final bool hasValidUser = info['user'] != null &&
          info['user']['name'] != null &&
          info['user']['name'].toString().trim().isNotEmpty;

      if (info['success'] == true && hasValidUser) {
        _user = info;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_user_info', jsonEncode(info));

        onLoginSuccess?.call(); // 通知 DataProvider 開始預先載入
      } else if (info['status'] == 'session_expired' ||
          info['success'] == false ||
          (info['success'] == true && !hasValidUser)) {
        // 如果 API 明確回傳失敗或過期，或者雖然 success 但沒抓到名字（幽靈 Session），強制登出
        _user = null;
        await _clearUserCache();
        await _apiService.logout(); // 強制清除 Cookies
      } else if (info['status'] == 'error') {
        // 只有在「網路錯誤」時才嘗試恢復離線快取
        final prefs = await SharedPreferences.getInstance();
        final cachedStr = prefs.getString('cached_user_info');

        if (cachedStr != null) {
          _user = jsonDecode(cachedStr);
          onLoginSuccess?.call();
        } else {
          await _clearUserCache();
        }
      } else {
        // 其他未知狀況，安全起見直接登出
        await _clearUserCache();
        await _apiService.logout();
      }
    } catch (e) {
      // 網路異常且有 Cookies 時，嘗試從本地快取恢復
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedStr = prefs.getString('cached_user_info');
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
        final loginError = '帳密或驗證碼錯誤';
        await fetchCaptcha();
        _error = loginError; // Restore error after fetchCaptcha clears it
        notifyListeners();
        return false;
      }
    } catch (e) {
      final loginError = '帳密或驗證碼錯誤';
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
