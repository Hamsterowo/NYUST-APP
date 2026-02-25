import 'package:dio/dio.dart';

Future<void> setupCookieManager(Dio dio) async {
  throw UnsupportedError(
    'Cannot create a cookie manager without dart:html or dart:io',
  );
}
