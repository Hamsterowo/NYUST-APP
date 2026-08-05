import 'dart:convert';
import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// 原生平台：把 .ics 寫進快取目錄，再以 `text/calendar` 交給系統開啟。
///
/// **刻意不用分享面板。** Google 日曆沒有註冊 `ACTION_SEND`，.ics 丟進分享面板時
/// 日曆根本不會出現在選項裡，使用者只會看到「儲存到檔案」。`ACTION_VIEW`
/// （`OpenFilex.open` 在 Android 上做的事）才會叫出日曆的匯入流程。
///
/// 檔案寫在快取目錄，走外掛自己的 FileProvider 授權，不需要任何儲存權限。
Future<void> openIcsFile(String icsText, {required String filename}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  // .ics 規格上是 UTF-8；中文事件名稱靠這個才不會變成亂碼。
  await file.writeAsBytes(utf8.encode(icsText), flush: true);

  final result = await OpenFilex.open(file.path, type: 'text/calendar');
  if (result.type != ResultType.done) {
    throw IcsLaunchException(result.message);
  }
}

/// 系統沒能開啟這個 .ics（多半是裝置上沒有任何日曆 App）。
class IcsLaunchException implements Exception {
  final String message;
  const IcsLaunchException(this.message);

  @override
  String toString() => 'IcsLaunchException: $message';
}
