import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

late PersistCookieJar _globalCookieJar;

Future<void> setupCookieManager(Dio dio) async {
  Directory appDocDir = await getApplicationDocumentsDirectory();
  String appDocPath = appDocDir.path;

  _globalCookieJar = PersistCookieJar(
    storage: FileStorage("$appDocPath/.cookies/"),
  );
  dio.interceptors.add(CookieManager(_globalCookieJar));
}

Future<void> clearCookies() async {
  await _globalCookieJar.deleteAll();
}
