import '../api_client.dart';
import '../scrapers/sso_scraper.dart';
import '../scrapers/info_scraper.dart';
import 'auth_service.dart';

/// 以 YunTech SSO / eStudent 網頁為後端的 [AuthService] 實作。
///
/// 內部委派給現有的 [SsoScraper]（網頁登入）與 [InfoScraper]（使用者資訊）。
class NyustAuthService implements AuthService {
  final ApiClient _client;
  late final SsoScraper _ssoScraper;
  late final InfoScraper _infoScraper;

  NyustAuthService(this._client) {
    _ssoScraper = SsoScraper(_client.dio);
    _infoScraper = InfoScraper(_client.dio);
  }

  SsoScraper get ssoScraper => _ssoScraper;
  InfoScraper get infoScraper => _infoScraper;

  @override
  Future<Map<String, dynamic>> loginInit() async {
    await _client.ensureInit();
    try {
      return await _ssoScraper.loginInit();
    } catch (e) {
      throw Exception('Failed to init login: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> login(
    String username,
    String password,
    String captcha,
    String verificationToken,
  ) async {
    await _client.ensureInit();
    try {
      return await _ssoScraper.login(
        username: username,
        password: password,
        captcha: captcha,
        verificationToken: verificationToken,
        rememberMe: true,
      );
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getUserInfo() async {
    await _client.ensureInit();
    return _infoScraper.getUserInfo();
  }

  @override
  Future<void> logout() async {
    await _client.clearCookies();
  }
}
