import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

/// 後備實作（理論上不會被選中）：以記憶體位元組分享。
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
