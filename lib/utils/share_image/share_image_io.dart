import 'dart:io';
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 原生平台：寫入暫存檔後分享（iPad 需要 sharePositionOrigin 定位分享面板）。
Future<void> sharePngBytes(
  Uint8List pngBytes, {
  required String filename,
  Rect? sharePositionOrigin,
}) async {
  final tempDir = await getTemporaryDirectory();
  final file = await File('${tempDir.path}/$filename').create();
  await file.writeAsBytes(pngBytes);

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path)],
      sharePositionOrigin: sharePositionOrigin,
    ),
  );
}
