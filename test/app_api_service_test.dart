import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yun_tool/services/app_api/app_api_service.dart';
import 'package:yun_tool/utils/yuntech_app_crypto.dart';

/// A dio [HttpClientAdapter] that returns canned responses from a per-test
/// handler, so `/Token` and `/api/...` calls can be exercised without network.
/// The handler receives each request plus its 0-based index (call order), so a
/// test can vary the reply per call (e.g. 401 first, 200 on retry).
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final ResponseBody Function(RequestOptions options, int callIndex) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final index = requests.length;
    requests.add(options);
    return handler(options, index);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonBody(Map<String, dynamic> body, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json; charset=utf-8'],
      },
    );

ResponseBody _bytesBody(List<int> data, {int status = 200}) =>
    ResponseBody.fromBytes(
      data,
      status,
      headers: {
        Headers.contentTypeHeader: ['application/pdf'],
      },
    );

int _tokenCalls(_FakeAdapter a) =>
    a.requests.where((r) => r.path.contains('Token')).length;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // In-memory stand-in for flutter_secure_storage's platform channel.
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  late Map<String, String> store;

  setUp(() {
    store = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final args =
              (call.arguments as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};
          switch (call.method) {
            case 'write':
              store[args['key'] as String] = args['value'] as String;
              return null;
            case 'read':
              return store[args['key'] as String];
            case 'delete':
              store.remove(args['key'] as String);
              return null;
            case 'containsKey':
              return store.containsKey(args['key'] as String);
            case 'readAll':
              return Map<String, String>.from(store);
            case 'deleteAll':
              store.clear();
              return null;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('mock mode', () {
    test(
      'setMockMode seeds a fake credential and short-circuits the network',
      () async {
        final service = AppApiService();
        service.setMockMode(true);

        expect(service.hasToken, isTrue);
        expect(service.tokenExpiry, isNotNull);
        // Demo account serves the bundled sample PDF (easter egg) instead of
        // hitting the network or prompting for a password.
        final pdf = await service.getYunReport();
        expect(pdf, isNotNull);
        expect(String.fromCharCodes(pdf!.take(5)), '%PDF-');
      },
    );

    test('remember toggle works in memory without touching storage', () async {
      final service = AppApiService();
      service.setMockMode(true);

      expect(await service.isPasswordRemembered(), isFalse);
      expect(await service.setRememberPassword(true), isTrue);
      expect(await service.isPasswordRemembered(), isTrue);
      expect(service.hasSavedCredential, isTrue);
      // Nothing was persisted — it's all in-memory demo state.
      expect(store, isEmpty);
    });

    test('clear turns mock mode off', () async {
      final service = AppApiService();
      service.setMockMode(true);
      await service.setRememberPassword(true);

      await service.clear();

      expect(service.hasToken, isFalse);
      expect(await service.isPasswordRemembered(), isFalse);
    });
  });

  group('login', () {
    test(
      'stores the token and persists the hash when remember is on',
      () async {
        final adapter = _FakeAdapter(
          (options, i) => _jsonBody({
            'access_token': 'tok-1',
            'expires_in': 7776000, // 90 days
          }),
        );
        final service = AppApiService(httpClientAdapter: adapter);

        final ok = await service.login('D11012345', 'pw', remember: true);

        expect(ok, isTrue);
        expect(service.hasToken, isTrue);
        expect(service.hasSavedCredential, isTrue);
        expect(service.tokenExpiry, isNotNull);
        expect(service.tokenExpiry!.isAfter(DateTime.now()), isTrue);
        // Persisted: token, user id, and the SHA-256 hash (never plaintext).
        expect(store['app_api_access_token'], 'tok-1');
        expect(store['app_api_user_id'], 'D11012345');
        expect(store['app_api_pwd_hash'], YuntechAppCrypto.sha256Hex('pw'));
        expect(store, isNot(contains('pw')));
      },
    );

    test(
      'keeps the hash in memory but off-disk when remember is off',
      () async {
        final adapter = _FakeAdapter(
          (options, i) => _jsonBody({'access_token': 'tok-2'}),
        );
        final service = AppApiService(httpClientAdapter: adapter);

        final ok = await service.login('D11012345', 'pw', remember: false);

        expect(ok, isTrue);
        // In-memory credential lets a 401 self-heal this session...
        expect(service.hasSavedCredential, isTrue);
        // ...but nothing is persisted across restarts.
        expect(store.containsKey('app_api_pwd_hash'), isFalse);
        expect(await service.isPasswordRemembered(), isFalse);
      },
    );

    test('returns false when the endpoint gives no access_token', () async {
      final adapter = _FakeAdapter(
        (options, i) => _jsonBody({'error': 'invalid_grant'}, status: 400),
      );
      final service = AppApiService(httpClientAdapter: adapter);

      expect(await service.login('D11012345', 'wrong'), isFalse);
      expect(service.hasToken, isFalse);
    });
  });

  group('ensureUserId (seed student ID from web session)', () {
    test('lets an upgraded user re-login without a stored id', () async {
      final adapter = _FakeAdapter(
        (options, i) => _jsonBody({'access_token': 'tok-1'}),
      );
      // No prior login → no stored user id, like a user upgrading from an
      // older build. reloginWithPassword would otherwise fail before the call.
      final service = AppApiService(httpClientAdapter: adapter);
      expect(await service.reloginWithPassword('pw'), isFalse);

      service.ensureUserId('D11012345');
      expect(await service.reloginWithPassword('pw'), isTrue);
      expect(service.hasToken, isTrue);
    });

    test('does not override an id already known from a real login', () async {
      final adapter = _FakeAdapter(
        (options, i) => _jsonBody({'access_token': 'tok-1'}),
      );
      final service = AppApiService(httpClientAdapter: adapter);
      await service.login('D11012345', 'pw');

      service.ensureUserId('OTHER999'); // should be ignored
      expect(store['app_api_user_id'], 'D11012345');
    });

    test('is a no-op for empty ids and in mock mode', () async {
      final service = AppApiService();
      service.ensureUserId('');
      expect(await service.reloginWithPassword('pw'), isFalse);

      service.setMockMode(true);
      service.ensureUserId('D11012345'); // mock mode keeps its own demo id
      expect(await service.reloginWithPassword('pw'), isTrue);
    });
  });

  group('getYunReport auth handling', () {
    test('on 401 it silently re-mints the token and retries once', () async {
      final adapter = _FakeAdapter((options, i) {
        if (options.path.contains('Token')) {
          return _jsonBody({'access_token': 'tok-refreshed'});
        }
        // First GET is unauthorized; the retry after refresh succeeds.
        final getCalls = i; // token call is index 0
        return getCalls == 1
            ? _bytesBody(const [], status: 401)
            : _bytesBody(const [1, 2, 3]);
      });
      final service = AppApiService(httpClientAdapter: adapter);
      await service.login('D11012345', 'pw', remember: true);

      final pdf = await service.getYunReport();

      expect(pdf, isNotNull);
      expect(pdf, equals(Uint8List.fromList(const [1, 2, 3])));
      // One initial /Token (login) + one refresh /Token after the 401.
      expect(_tokenCalls(adapter), 2);
    });

    test(
      'throws AppApiAuthRequiredException with no token and no credential',
      () async {
        final adapter = _FakeAdapter(
          (options, i) => _bytesBody(const [], status: 401),
        );
        final service = AppApiService(httpClientAdapter: adapter);

        await expectLater(
          service.getYunReport(),
          throwsA(isA<AppApiAuthRequiredException>()),
        );
        // No credential to refresh with → we never even hit the network.
        expect(adapter.requests, isEmpty);
      },
    );

    test(
      'throws when the token is expired and the refresh also 401s',
      () async {
        final adapter = _FakeAdapter((options, i) {
          if (options.path.contains('Token')) {
            // Login mints a token; the later refresh fails to mint a new one.
            return i == 0
                ? _jsonBody({'access_token': 'tok-1'})
                : _jsonBody({'error': 'invalid_grant'}, status: 400);
          }
          return _bytesBody(const [], status: 401); // every GET is unauthorized
        });
        final service = AppApiService(httpClientAdapter: adapter);
        await service.login('D11012345', 'pw', remember: true);

        await expectLater(
          service.getYunReport(),
          throwsA(isA<AppApiAuthRequiredException>()),
        );
      },
    );
  });

  group('remember-password persistence', () {
    test(
      'setRememberPassword(true) persists, (false) removes the hash',
      () async {
        final adapter = _FakeAdapter(
          (options, i) => _jsonBody({'access_token': 'tok-1'}),
        );
        final service = AppApiService(httpClientAdapter: adapter);
        await service.login('D11012345', 'pw', remember: false);
        expect(store.containsKey('app_api_pwd_hash'), isFalse);

        expect(await service.setRememberPassword(true), isTrue);
        expect(store['app_api_pwd_hash'], YuntechAppCrypto.sha256Hex('pw'));
        expect(await service.isPasswordRemembered(), isTrue);

        expect(await service.setRememberPassword(false), isTrue);
        expect(store.containsKey('app_api_pwd_hash'), isFalse);
        expect(await service.isPasswordRemembered(), isFalse);
        // Turning it off drops the on-disk copy but keeps the session credential.
        expect(service.hasSavedCredential, isTrue);
      },
    );

    test(
      'setRememberPassword(true) is refused when no credential is known',
      () async {
        final service = AppApiService();
        expect(await service.setRememberPassword(true), isFalse);
      },
    );
  });

  test('clear wipes tokens and all persisted keys', () async {
    final adapter = _FakeAdapter(
      (options, i) =>
          _jsonBody({'access_token': 'tok-1', 'expires_in': 7776000}),
    );
    final service = AppApiService(httpClientAdapter: adapter);
    await service.login('D11012345', 'pw', remember: true);
    expect(store, isNotEmpty);

    await service.clear();

    expect(service.hasToken, isFalse);
    expect(service.hasSavedCredential, isFalse);
    expect(service.tokenExpiry, isNull);
    expect(store, isEmpty);
    expect(await service.isPasswordRemembered(), isFalse);
  });

  test('loadPersisted restores a saved session', () async {
    // Seed a first instance, then load into a fresh one (simulating restart).
    final adapter = _FakeAdapter(
      (options, i) =>
          _jsonBody({'access_token': 'tok-1', 'expires_in': 7776000}),
    );
    await AppApiService(
      httpClientAdapter: adapter,
    ).login('D11012345', 'pw', remember: true);

    final restored = AppApiService();
    await restored.loadPersisted();

    expect(restored.hasToken, isTrue);
    expect(restored.hasSavedCredential, isTrue);
    expect(restored.tokenExpiry, isNotNull);
  });
}
