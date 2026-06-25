import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsUtils {
  static const _channel = MethodChannel('tw.hamster.yuntool/settings');

  static Future<void> openLanguageSettings() async {
    if (kIsWeb) {
      // On Web, system settings jump is not applicable.
      return;
    }
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('openLanguageSettings');
      } on PlatformException catch (e) {
        debugPrint("Failed to open Android language settings: ${e.message}");
      }
    } else if (Platform.isIOS) {
      final Uri url = Uri.parse('app-settings:');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        debugPrint("Failed to launch iOS app settings URL");
      }
    }
  }
}
