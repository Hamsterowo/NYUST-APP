import 'package:dio/dio.dart';

/// 判斷一個例外是否為「連不上伺服器」的網路/連線類錯誤
/// （離線、逾時、DNS 失敗…），而非伺服器有回應的業務錯誤。
///
/// 用來把「離線」和「session 過期 / 頁面解析失敗」區分開來：
/// 前者絕不該把使用者登出，後者才需要。
///
/// 刻意不 import `dart:io`（`SocketException`），因為本專案也編譯到 Web，
/// Web 上沒有 `dart:io`。改用 [DioException.type] 與字串比對達成跨平台判斷。
bool isNetworkError(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return true;
      case DioExceptionType.unknown:
        // Dio 把底層錯誤（例如 SocketException）包在 error 內
        final inner = error.error;
        return inner != null && _looksLikeSocketError(inner.toString());
      default:
        return false;
    }
  }
  return _looksLikeSocketError(error.toString());
}

bool _looksLikeSocketError(String message) {
  return message.contains('SocketException') ||
      message.contains('Connection refused') ||
      message.contains('Connection closed') ||
      message.contains('Network is unreachable') ||
      message.contains('Failed host lookup') ||
      message.contains('XMLHttpRequest'); // Web: dio browser adapter 連線失敗
}
