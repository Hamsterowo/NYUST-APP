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

  /// 學校頁面解析出的驗證錯誤原文（例：帳號或密碼錯誤、驗證碼錯誤、帳號鎖定）。
  /// 僅在 [_error] 為 'loginFailed'（憑證被明確拒絕）時可能有值，供 UI 優先顯示。
  String? _errorDetail;

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

  // 二步驟驗證（TOTP）待處理狀態：login() 偵測到帳號啟用 2FA 後暫存，
  // 待 UI 收集 6 碼驗證碼呼叫 submitTotp() 完成登入。密碼只保留在記憶體，
  // 供驗證成功後補打 App 端點登入用，絕不持久化明文。
  bool _mfaRequired = false;
  String? _mfaVerificationToken;
  String? _pendingUsername;
  String? _pendingPassword;
  bool _pendingRememberPassword = false;

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
  String? get errorDetail => _errorDetail;
  String? get captchaUrl => _captchaUrl;

  /// login() 是否偵測到帳號啟用二步驟驗證，正等待 UI 收集 TOTP 驗證碼。
  bool get mfaRequired => _mfaRequired;

  Future<void> init() async {
    await _apiService.init();
    // 載入先前保存的 App 端點 Bearer token（供在學證明等 /api 服務使用）。
    await _apiService.appApi.loadPersisted();

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
        _seedAppApiUserId();
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
        _seedAppApiUserId();
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

  /// Feeds the app-endpoint client the student ID from the authoritative web
  /// session so it can mint/refresh a Bearer token even when it was never
  /// stored (e.g. upgrade from an older build, or a failed background login).
  /// The web login username and the app-endpoint username are the same student
  /// ID. No-op when we don't have one or the app client already knows it.
  void _seedAppApiUserId() {
    final userMap = _user?['user'];
    final id = (userMap is Map ? userMap['學號'] : null) ?? _user?['username'];
    final studentId = id?.toString().trim();
    if (studentId != null && studentId.isNotEmpty) {
      _apiService.appApi.ensureUserId(studentId);
    }
  }

  Future<void> fetchCaptcha() async {
    _isLoading = true;
    _error = null;
    _errorDetail = null;
    notifyListeners();
    try {
      await _apiService.logout();
      await _apiService.init();

      final data = await _apiService.loginInit();
      if (data['success'] == true) {
        _captchaUrl = data['captchaImage'];
        _verificationToken = data['verificationToken'];
      } else {
        // 依 scraper 分類顯示「無網路」或「登入服務不可用」,
        // 絕不把原始錯誤字串（Dio 例外等）丟給 UI。
        _error = data['status'] == 'network_error'
            ? 'loginNoNetwork'
            : 'ssoUnavailable';
      }
    } catch (e) {
      final offline = !await ConnectivityService.instance.checkOnline();
      _error = offline ? 'loginNoNetwork' : 'ssoUnavailable';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(
    String username,
    String password,
    String captcha, {
    bool rememberPassword = false,
  }) async {
    _isLoading = true;
    _error = null;
    _errorDetail = null;
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

      // 帳號啟用二步驟驗證（TOTP）：尚未完成登入，暫存待驗證狀態，
      // 交由 UI 收集 6 碼驗證碼後呼叫 submitTotp()。
      if (result['mfaRequired'] == true) {
        _mfaRequired = true;
        _mfaVerificationToken = result['verificationToken'] as String?;
        _pendingUsername = username;
        _pendingPassword = password;
        _pendingRememberPassword = rememberPassword;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (result['success'] == true) {
        await _completeLogin(username, password, rememberPassword);
        return true;
      } else {
        // 三態分流:憑證被明確拒絕(rejected) / 無網路 / 登入服務異常。
        // 只有 rejected 才顯示「帳密錯誤」類訊息,伺服器掛掉不能誤怪使用者。
        final status = result['status']?.toString();
        final String loginError;
        String? detail;
        if (status == 'rejected') {
          loginError = 'loginFailed';
          detail = result['serverMessage']?.toString();
        } else if (status == 'network_error') {
          loginError = 'loginNoNetwork';
        } else {
          loginError = 'ssoUnavailable';
        }
        await fetchCaptcha();
        _error = loginError;
        _errorDetail = detail;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // 例外不是憑證錯誤:離線給「無網路」,其餘視為登入服務異常。
      final offline = !await ConnectivityService.instance.checkOnline();
      await fetchCaptcha();
      _error = offline ? 'loginNoNetwork' : 'ssoUnavailable';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 登入成功後的共用收尾：抓使用者資訊、寫快取、補打 App 端點登入。
  /// 由一般登入與 TOTP 驗證成功兩條路徑共用。
  Future<void> _completeLogin(
    String username,
    String password,
    bool rememberPassword,
  ) async {
    final info = await _apiService.getUserInfo();
    _user = info;
    _user?['username'] = username;

    await _saveUserCache(_user!);

    // 額外用同一組帳密（免驗證碼）拿 App 端點 Bearer token，供在學證明等
    // /api 服務使用。用獨立 client、不影響網頁 session；失敗不影響登入。
    // rememberPassword 為 true 時，會持久化密碼雜湊以便 token 過期後靜默重登。
    await _apiService.appApi.login(
      username,
      password,
      remember: rememberPassword,
    );
    // Even if that background /Token call failed, remember the student ID
    // so a later app-endpoint re-login (在學證明 / remember-password) works.
    _apiService.appApi.ensureUserId(username);

    _clearMfaState();
    notifyListeners();
    onLoginSuccess?.call();
  }

  void _clearMfaState() {
    _mfaRequired = false;
    _mfaVerificationToken = null;
    _pendingUsername = null;
    _pendingPassword = null;
    _pendingRememberPassword = false;
  }

  /// 提交二步驟驗證（TOTP）6 碼驗證碼，完成登入。
  ///
  /// 需先由 login() 進入 [mfaRequired] 狀態。驗證碼正確 → 完成登入回傳 true；
  /// 錯誤 → 學校會作廢 session，這裡清掉待驗證狀態並重新取得驗證碼，
  /// 設定 `_error = 'totpFailed'`，回傳 false，由 UI 引導重新登入。
  Future<bool> submitTotp(String code) async {
    if (!_mfaRequired || _mfaVerificationToken == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    final username = _pendingUsername!;
    final password = _pendingPassword!;
    final rememberPassword = _pendingRememberPassword;

    try {
      final result = await _apiService.submitTotp(code, _mfaVerificationToken!);

      if (result['success'] == true) {
        await _completeLogin(username, password, rememberPassword);
        return true;
      }

      // 驗證碼錯誤：session 已被學校作廢，需從頭重新登入（含重抓驗證碼）。
      // 僅 rejected(驗證碼錯) 顯示 totpFailed;連線/伺服器問題給對應訊息。
      final status = result['status']?.toString();
      _clearMfaState();
      await fetchCaptcha();
      _error = status == 'network_error'
          ? 'loginNoNetwork'
          : status == 'rejected'
          ? 'totpFailed'
          : 'ssoUnavailable';
      notifyListeners();
      return false;
    } catch (e) {
      final offline = !await ConnectivityService.instance.checkOnline();
      _clearMfaState();
      await fetchCaptcha();
      _error = offline ? 'loginNoNetwork' : 'ssoUnavailable';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 使用者在 TOTP 頁選擇取消：放棄本次登入，回到登入頁並重取驗證碼。
  Future<void> cancelMfa() async {
    _clearMfaState();
    await fetchCaptcha();
    notifyListeners();
  }

  /// 變更 SSO 密碼。成功回傳 true；失敗時把訊息放進 [error] 回傳 false。
  ///
  /// 成功後以新密碼靜默重登 App 端點：更新記憶體中的密碼，若使用者開了
  /// 「記住密碼」也一併把本機的密碼雜湊換成新密碼的，避免日後 token 續期
  /// 仍用舊密碼而失敗。網頁 session（cookie）於同一 session 變更後通常仍有效。
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _apiService.changePassword(oldPassword, newPassword);
      if (result['success'] == true) {
        if (!_apiService.isMockMode) {
          final username = _user?['username']?.toString() ?? '';
          if (username.isNotEmpty) {
            final remember = await _apiService.appApi.isPasswordRemembered();
            await _apiService.appApi.login(
              username,
              newPassword,
              remember: remember,
            );
          }
        }
        return true;
      }
      // rejected(舊密碼錯誤等) → 顯示學校原文;無網路/其他 → 對應通用訊息。
      final status = result['status']?.toString();
      final serverMessage = result['serverMessage']?.toString();
      if (status == 'rejected' &&
          serverMessage != null &&
          serverMessage.isNotEmpty) {
        _error = serverMessage;
      } else if (status == 'network_error') {
        _error = 'loginNoNetwork';
      } else {
        _error = 'changePasswordFailed';
      }
      return false;
    } catch (e) {
      final offline = !await ConnectivityService.instance.checkOnline();
      _error = offline ? 'loginNoNetwork' : 'changePasswordFailed';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _apiService.isMockMode = false;
    await _apiService.logout();
    await _apiService.appApi.clear();
    await _clearUserCache();
    _clearMfaState();
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
