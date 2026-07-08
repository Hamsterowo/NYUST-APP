import 'auth_service.dart';
import '../mock/mock_data.dart';

/// Demo 模式使用的 [AuthService]，回傳 [MockData] 中的固定使用者資料，
/// 不發任何網路請求。
class MockAuthService implements AuthService {
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
  Future<Map<String, dynamic>> loginViaAppApi(
    String username,
    String password,
  ) async {
    return {
      'success': true,
      'accessToken': 'mock-access-token',
      'userType': 'S',
    };
  }

  @override
  Future<Map<String, dynamic>> getUserInfo() async {
    return {'success': true, 'user': Map<String, dynamic>.from(MockData.user)};
  }

  @override
  Future<void> logout() async {
    // Mock 模式無 Cookie 可清除。
  }
}
