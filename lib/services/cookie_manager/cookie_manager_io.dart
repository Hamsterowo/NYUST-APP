import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

late CookieJar _globalCookieJar;

Future<void> setupCookieManager(Dio dio) async {
  // Clear any legacy unencrypted cookie files stored on disk
  try {
    final appDocDir = await getApplicationDocumentsDirectory();
    final legacyCookiesDir = Directory("${appDocDir.path}/.cookies");
    if (await legacyCookiesDir.exists()) {
      await legacyCookiesDir.delete(recursive: true);
    }
  } catch (_) {}

  _globalCookieJar = CookieJar();
  dio.interceptors.add(CookieManager(_globalCookieJar));
}

Future<void> clearCookies() async {
  await _globalCookieJar.deleteAll();
}
