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

PersistCookieJar? _cookieJar;

/// 全 App 共用的同一個 cookie jar。
///
/// **必須是單例**：App 內不只一個 [Dio]（[AuthProvider] 之外，行事曆頁與課程
/// 詳情頁也各自建了 ApiService）。若每次掛載都新建一個 jar 並覆寫這個變數，
/// 全域就會指向最後建立的那一個，而先前的 Dio 仍握著舊 jar —— [clearCookies]
/// 於是清到錯的 jar，登出後主 client 仍帶著 `.YunTechSSO`，登入頁被判定為已
/// 登入而轉址，頁面裡就沒有 `__RequestVerificationToken`（Token not found）。
PersistCookieJar get _globalCookieJar =>
    _cookieJar ??= PersistCookieJar(storage: SecureCookieStorage());

/// 同步掛上 Cookie 管理。[PersistCookieJar] 為同步建構、cookie 於首次請求時
/// 才從 secure storage 惰性載入，因此可在 [ApiClient] 建構子直接呼叫，
/// 保證第一筆請求送出前 interceptor 已在位（不會發生「沒帶 cookie 被誤判登出」）。
void attachCookieManager(Dio dio) {
  dio.interceptors.add(CookieManager(_globalCookieJar));
}

Future<void> clearCookies() async {
  await _globalCookieJar.deleteAll();
}
