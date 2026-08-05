/// 把一份 iCalendar 文字交給系統日曆。
///
/// 依平台選實作（與 `cookie_manager/`、`share_image/` 同一套條件式匯入寫法）：
/// 有檔案系統的原生平台走 `ics_launcher_io.dart`，Web 走不支援的 stub。
library;

export 'ics_launcher_stub.dart' if (dart.library.io) 'ics_launcher_io.dart';
