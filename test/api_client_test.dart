import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yun_tool/services/api_client.dart';
import 'package:yun_tool/services/api_service.dart';

/// Locks the "construct-is-ready" contract established in ticket 01: an
/// [ApiClient] wires its cookie management in the constructor, so no init()/
/// ensureInit() step is needed before the first request. This is what keeps an
/// offline cold-start from firing a cookie-less request that looks like a
/// logged-out session.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'ApiClient attaches CookieManager at construction, without any init',
    () {
      final client = ApiClient();

      final cookieInterceptors = client.dio.interceptors
          .whereType<CookieManager>();

      expect(
        cookieInterceptors,
        isNotEmpty,
        reason: 'CookieManager must be present the moment ApiClient is built',
      );
    },
  );

  /// Session cookies, the demo-mode switch and the app-endpoint token are all
  /// app-wide state. A second instance splits them: screens that built their
  /// own client once meant logging out cleared only one client's cookies, so
  /// the login page came back without a verification token.
  test('ApiService() always hands back the same instance', () {
    expect(identical(ApiService(), ApiService()), isTrue);
  });
}
