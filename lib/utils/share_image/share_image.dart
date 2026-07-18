/// 分享 PNG 圖片的平台抽象（conditional import，同 pwa_interop / cookie_manager 模式）。
///
/// 原生平台需要先落地成暫存檔再分享（`dart:io`），Web 直接以記憶體位元組
/// 分享；讓 `dart:io` 只存在於 io 實作，編譯期即隔離。
library;

export 'share_image_stub.dart'
    if (dart.library.io) 'share_image_io.dart'
    if (dart.library.js_interop) 'share_image_web.dart';
