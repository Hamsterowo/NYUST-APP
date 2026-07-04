import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as hp;
import 'package:html/dom.dart' as dom;

/// 所有學校資料爬取類的基底
abstract class BaseScraper {
  final Dio dio;

  BaseScraper(this.dio);

  /// 將 HTML 字串轉換為可操作的 Document 物件
  dom.Document parseHtml(dynamic html) {
    if (html is String) return hp.parse(html);
    return hp.parse(html.toString());
  }

  /// 封裝 GET 請求，並處理雲科大特有的 JavaScript 導向 (Redirecting 頁面)
  Future<Response> getWithRedirects(String url, {Options? options}) async {
    String currentUrl = url;
    int redirectCount = 0;
    const int maxRedirects = 10;

    while (redirectCount < maxRedirects) {
      final response = await dio.get(
        currentUrl,
        options: (options ?? Options(headers: commonHeaders)).copyWith(
          followRedirects: false,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 301 || response.statusCode == 302) {
        final nextUrl = response.headers.value('location');
        if (nextUrl != null) {
          final uri = Uri.parse(currentUrl);
          final nextUri = nextUrl.startsWith('http')
              ? nextUrl
              : '${uri.scheme}://${uri.host}${nextUrl.startsWith('/') ? '' : '/'}$nextUrl';

          if (kDebugMode)
            print('BaseScraper: Detected HTTP 302 redirect to $nextUri');
          currentUrl = nextUri;
          redirectCount++;
          continue;
        }
      }

      if (response.data is String &&
          response.data.toString().contains('var redirectUrl')) {
        final text = response.data.toString();
        final match = RegExp(
          r"var\s+redirectUrl\s*=\s*'([^']+)'",
        ).firstMatch(text);

        if (match != null && match.group(1) != null) {
          final nextUrl = match.group(1)!;
          final uri = Uri.parse(currentUrl);
          final nextUri = nextUrl.startsWith('http')
              ? nextUrl
              : '${uri.scheme}://${uri.host}${nextUrl.startsWith('/') ? '' : '/'}$nextUrl';

          if (kDebugMode)
            print('BaseScraper: Detected JS redirect to $nextUri');
          currentUrl = nextUri;
          redirectCount++;
          continue;
        }
      }

      return response;
    }
    throw Exception('Too many redirects');
  }

  /// 模擬瀏覽器的 User-Agent，確保不會被學校伺服器阻擋
  Map<String, String> get commonHeaders => {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'Accept-Language': 'zh-TW,zh;q=0.9,en-US;q=0.8,en;q=0.7',
  };

  /// 輔助方法：安全地獲取元素文字
  String getText(dom.Element? element) {
    return element?.text.trim() ?? '';
  }

  /// 輔助方法：安全地獲取元素屬性
  String getAttribute(dom.Element? element, String attribute) {
    return element?.attributes[attribute]?.trim() ?? '';
  }
}
