import 'package:dio/dio.dart';

// Web：瀏覽器自行處理 cookie，無需掛 CookieManager。
void attachCookieManager(Dio dio) {}

Future<void> clearCookies() async {}
