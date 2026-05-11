import 'package:dio/dio.dart';

Future<void> setupCookieManager(Dio dio) async {
  // 網頁版不需要 CookieManager，瀏覽器會自動處理 cookies。
}

Future<void> clearCookies() async {
  // 網頁版 Cookie 由瀏覽器管理，目前不需要額外處理
}
