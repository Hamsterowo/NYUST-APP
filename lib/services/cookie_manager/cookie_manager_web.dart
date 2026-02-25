import 'package:dio/dio.dart';

Future<void> setupCookieManager(Dio dio) async {
  // 網頁版不需要 CookieManager，瀏覽器會自動處理 cookies。
}
