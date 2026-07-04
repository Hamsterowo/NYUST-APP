import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';

class SecureCookieStorage implements Storage {
  final _secureStorage = const FlutterSecureStorage();

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {
    // No-op
  }

  @override
  Future<String?> read(String key) async {
    return await _secureStorage.read(key: "cookie_$key");
  }

  @override
  Future<void> write(String key, String value) async {
    await _secureStorage.write(key: "cookie_$key", value: value);
  }

  @override
  Future<void> delete(String key) async {
    await _secureStorage.delete(key: "cookie_$key");
  }

  @override
  Future<void> deleteAll(List<String> keys) async {
    for (var key in keys) {
      await _secureStorage.delete(key: "cookie_$key");
    }
  }
}

late PersistCookieJar _globalCookieJar;

Future<void> setupCookieManager(Dio dio) async {
  // Clear any legacy unencrypted cookie files stored on disk
  try {
    final appDocDir = await getApplicationDocumentsDirectory();
    final legacyCookiesDir = Directory("${appDocDir.path}/.cookies");
    if (await legacyCookiesDir.exists()) {
      await legacyCookiesDir.delete(recursive: true);
    }
  } catch (_) {}

  _globalCookieJar = PersistCookieJar(storage: SecureCookieStorage());
  dio.interceptors.add(CookieManager(_globalCookieJar));
}

Future<void> clearCookies() async {
  await _globalCookieJar.deleteAll();
}
