import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  Map<String, dynamic>? _user;
  String? _error;

  // Login Init Data
  String? _captchaUrl;
  String? _verificationToken;

  AuthProvider() {
    init();
  }

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  Map<String, dynamic>? get user => _user;
  String? get error => _error;
  String? get captchaUrl => _captchaUrl;

  Future<void> init() async {
    await _apiService.init();
    // Check if we have valid cookies/session?
    // For now, let's try to fetch user info to see if logged in
    try {
      final info = await _apiService.getUserInfo();
      if (info['success'] == true) {
        _user = info;
        print(
          'AuthProvider: Session restored! User: ${_user?["user"]?["name"]}',
        );
        notifyListeners();
      } else {
        print('AuthProvider: No active session found.');
      }
    } catch (e) {
      // Not logged in or error
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
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Login failed';
        // Refresh captcha on failure?
        await fetchCaptcha();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      await fetchCaptcha();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    _user = null;
    notifyListeners();
  }

  ApiService get api => _apiService;
}
