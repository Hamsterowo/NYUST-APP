import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

/// Web：無檔案系統，直接以記憶體位元組分享。
Future<void> sharePngBytes(
  Uint8List pngBytes, {
  required String filename,
  Rect? sharePositionOrigin,
}) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(pngBytes, mimeType: 'image/png', name: filename)],
    ),
  );
}
