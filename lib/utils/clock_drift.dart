import 'package:intl/intl.dart';

/// 裝置時鐘與伺服器時鐘偏差多少，才視為「時間誤差過大」並提示使用者。
const clockSkewThreshold = Duration(minutes: 5);

/// 解析 HTTP 回應的 `Date` header（RFC 1123，例：
/// `Wed, 21 Oct 2015 07:28:00 GMT`）為 UTC [DateTime]；無法解析時回傳 `null`。
///
/// 刻意不 import `dart:io`（`HttpDate.parse`），因為本專案也編譯到 Web，
/// Web 上沒有 `dart:io`。改用 `intl` 的 [DateFormat] 解析固定格式的 RFC 1123
/// 字串，與 `network_error.dart` 避開 `dart:io` 的做法一致。
DateTime? parseHttpDate(String header) {
  final value = header.trim();
  if (value.isEmpty) return null;
  try {
    return DateFormat(
      "EEE, dd MMM yyyy HH:mm:ss 'GMT'",
      'en_US',
    ).parseUtc(value);
  } catch (_) {
    return null;
  }
}
