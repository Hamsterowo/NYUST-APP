import 'package:dio/dio.dart';

void attachCookieManager(Dio dio) {
  throw UnsupportedError(
    'Cannot create a cookie manager without dart:html or dart:io',
  );
}

Future<void> clearCookies() async {
  throw UnsupportedError(
    'Cannot create a cookie manager without dart:html or dart:io',
  );
}
