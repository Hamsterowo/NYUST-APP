import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yun_tool/services/api_client.dart';

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
}
