import 'auth_service.dart';

/// Demo / 除錯模式使用的 [AuthService]，回傳固定的 mock 使用者資料，不發任何網路請求。
///
/// 對應以 `debug` / `test` 帳號登入的情境。固定學號 `D11012345` 也是
/// [AuthProvider] 用來在冷啟動時辨識 mock session 的依據。
class MockAuthService implements AuthService {
  static const Map<String, dynamic> mockUser = {
    'name': '開發除錯員',
    'id': 'D11012345',
    'dept': '資訊工程學系',
    'class': '資工三甲',
  };

  @override
  Future<Map<String, dynamic>> loginInit() async {
    return {
      'success': true,
      'captchaImage': '',
      'verificationToken': 'mock-token',
    };
  }

  @override
  Future<Map<String, dynamic>> login(
    String username,
    String password,
    String captcha,
    String verificationToken,
  ) async {
    return {'success': true};
  }

  @override
  Future<Map<String, dynamic>> getUserInfo() async {
    return {
      'success': true,
      'user': Map<String, dynamic>.from(mockUser),
    };
  }

  @override
  Future<void> logout() async {
    // Mock 模式無 Cookie 可清除。
  }
}
