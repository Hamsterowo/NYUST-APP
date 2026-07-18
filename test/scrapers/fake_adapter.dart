import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// 依請求路徑回覆罐頭 HTML 的 dio [HttpClientAdapter]，
/// 讓爬蟲測試完全離線執行（同 app_api_service_test 的 fake adapter 模式）。
class FakeHtmlAdapter implements HttpClientAdapter {
  FakeHtmlAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody htmlBody(String html, {int status = 200}) =>
    ResponseBody.fromString(
      html,
      status,
      headers: {
        Headers.contentTypeHeader: ['text/html; charset=utf-8'],
      },
    );

/// 讀取 `test/fixtures/` 下的 HTML fixture。
String loadFixture(String name) =>
    File('test/fixtures/$name').readAsStringSync();
