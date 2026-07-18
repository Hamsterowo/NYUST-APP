import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android 13+「單一 App 語言」（per-app locale）的原生橋接。
///
/// 支援時語言選擇交由系統儲存：App 內選單寫入 [set]，系統設定頁的變更
/// 則透過 configuration change 自動送回 App —— 兩邊永遠一致。
/// 其他平台／Android 12 以下一律回報不支援，由呼叫端走 App 內覆寫。
class PerAppLocale {
  PerAppLocale._();

  static const _channel = MethodChannel('tw.hamster.yuntool/locale');

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// 目前平台是否支援系統層級的 per-app 語言（Android 13+）。
  static Future<bool> isSupported() async {
    if (!_isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 系統目前的 per-app 語言覆寫；`null` = 跟隨系統。
  static Future<Locale?> current() async {
    try {
      final tag = await _channel.invokeMethod<String?>('get');
      if (tag == null || tag.isEmpty) return null;
      return Locale(tag.split('-').first);
    } catch (_) {
      return null;
    }
  }

  /// 寫入系統的 per-app 語言；`null` 清除覆寫（跟隨系統）。
  ///
  /// tag 需與 `locales_config.xml` 宣告的項目一致，系統設定頁的
  /// 單選清單才會正確對應到所選語言。
  static Future<void> set(Locale? locale) async {
    final tag = switch (locale?.languageCode) {
      null => null,
      'zh' => 'zh-Hant-TW',
      'en' => 'en-US',
      final code => code,
    };
    try {
      await _channel.invokeMethod('set', tag);
    } catch (_) {}
  }
}
