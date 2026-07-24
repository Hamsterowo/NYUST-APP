import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

/// 同步掛上 Cookie 管理。[PersistCookieJar] 為同步建構、cookie 於首次請求時
/// 才從 secure storage 惰性載入，因此可在 [ApiClient] 建構子直接呼叫，
/// 保證第一筆請求送出前 interceptor 已在位（不會發生「沒帶 cookie 被誤判登出」）。
void attachCookieManager(Dio dio) {
  _globalCookieJar = PersistCookieJar(storage: SecureCookieStorage());
  dio.interceptors.add(CookieManager(_globalCookieJar));
}

Future<void> clearCookies() async {
  await _globalCookieJar.deleteAll();
}
