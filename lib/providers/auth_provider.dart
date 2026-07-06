import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/mock/mock_data.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  Map<String, dynamic>? _user;
  String? _error;

  final _secureStorage = const FlutterSecureStorage();
  static const String _cachedUserInfoKey = 'cached_user_info';

  Future<String?> _loadUserCache() async {
    return await _secureStorage.read(key: _cachedUserInfoKey);
  }

  Future<void> _saveUserCache(Map<String, dynamic> info) async {
    await _secureStorage.write(
      key: _cachedUserInfoKey,
      value: jsonEncode(info),
    );
  }

  Future<void> _clearUserCache() async {
    await _secureStorage.delete(key: _cachedUserInfoKey);
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

    _apiService.onSessionExpired = () {
      handleSessionExpired();
    };

    bool isAlreadyLoggedIn = false;

    final hasCookies = await _apiService.hasSavedCookies();

    if (!hasCookies) {
      final cachedStr = await _loadUserCache();
      if (cachedStr != null) {
        final cachedUser = jsonDecode(cachedStr);
        if (cachedUser['user']?['id'] == MockData.demoId) {
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
        if (cachedUser['user']?['id'] == MockData.demoId) {
          _apiService.isMockMode = true;
        }
        isAlreadyLoggedIn = true;
        notifyListeners();
        onLoginSuccess?.call();
      }
    } catch (_) {}

    // 離線時直接沿用快取,跳過線上驗證(避免無謂的逾時等待,也不會誤登出)。
    if (!await ConnectivityService.instance.checkOnline()) {
      _isInitialized = true;
      notifyListeners();
      return;
    }

    try {
      final info = await _apiService.getUserInfo();
      final status = info['status'];

      final bool hasValidUser =
          info['user'] != null &&
          info['user']['name'] != null &&
          info['user']['name'].toString().trim().isNotEmpty;

      if (status == 'network_error') {
        // 離線 / 連不上伺服器：保留已由快取載入的登入狀態與資料，
        // 等恢復連線後再驗證。絕不在這裡清除 cookie 或快取。
      } else if (info['success'] == true && hasValidUser) {
        _user = info;
        await _saveUserCache(info);
        if (!isAlreadyLoggedIn) {
          onLoginSuccess?.call();
        }
      } else if (status == 'session_expired' ||
          (info['success'] == true && !hasValidUser)) {
        // 連得到伺服器、但確認未登入 → 真正的 session 過期,登出。
        _user = null;
        await _clearUserCache();
        await _apiService.logout();
      } else {
        // 其他不明錯誤(解析失敗等):無法確定 session 是否還有效,
        // 保守起見保留快取,不要把使用者踢出去。
        final cachedStr = await _loadUserCache();
        if (cachedStr != null) {
          _user = jsonDecode(cachedStr);
          if (!isAlreadyLoggedIn) {
            onLoginSuccess?.call();
          }
        }
      }
    } catch (e) {
      try {
        final cachedStr = await _loadUserCache();
        if (cachedStr != null) {
          _user = jsonDecode(cachedStr);
          if (!isAlreadyLoggedIn) {
            onLoginSuccess?.call();
          }
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
      // 離線時顯示友善的「無網路」訊息,而非原始的 Dio 例外字串。
      final offline = !await ConnectivityService.instance.checkOnline();
      _error = offline ? 'loginNoNetwork' : e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password, String captcha) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (MockData.isDemoAccount(username)) {
        _apiService.isMockMode = true;
        _user = {
          'success': true,
          'user': Map<String, dynamic>.from(MockData.user),
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
        final loginError = 'loginFailed';
        await fetchCaptcha();
        _error = loginError;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // 離線時給明確的「無網路」訊息,而非籠統的帳密/驗證碼錯誤。
      final offline = !await ConnectivityService.instance.checkOnline();
      await fetchCaptcha();
      _error = offline ? 'loginNoNetwork' : 'loginFailed';
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

  /// 由資料層在「線上、但伺服器明確回報未登入」時呼叫,執行完整登出。
  /// 僅在目前為登入狀態時作用,避免重複觸發;離線 (network_error) 絕不會走到這裡。
  Future<void> handleSessionExpired() async {
    if (_user == null) return;
    await logout();
  }

  /// 更新使用者資料 (用於重新整理功能)
  void updateUserInfo(Map<String, dynamic> info) {
    _user = info;
    notifyListeners();
    _saveUserCache(info);
  }

  ApiService get api => _apiService;
}
