import 'dart:convert';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

/// 行事曆本地快取服務
/// 使用 SharedPreferences 持久化行事曆 + 假日資料
/// 快取有效期為 30 天
class CalendarCacheService {
  static const _dataPrefix = 'calendar_data_';
  static const _tsPrefix = 'calendar_ts_';
  static const _cacheDuration = Duration(days: 30);

  static String _getCurrentLanguageCode(String? lang) {
    if (lang != null) {
      return lang.toLowerCase() == 'en' ? 'en' : 'zh-tw';
    }
    String languageCode = 'zh';
    try {
      if (Intl.defaultLocale != null && Intl.defaultLocale!.isNotEmpty) {
        languageCode = Intl.defaultLocale!.split('_').first.split('-').first.toLowerCase();
      } else {
        languageCode = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
      }
    } catch (_) {
      try {
        languageCode = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
      } catch (_) {}
    }
    return languageCode == 'en' ? 'en' : 'zh-tw';
  }

  /// 儲存行事曆資料（合併端點的完整回應）
  static Future<void> saveCalendarData(
    int year,
    Map<String, dynamic> data, {
    String? lang,
  }) async {
    final langCode = _getCurrentLanguageCode(lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_dataPrefix${year}_$langCode', jsonEncode(data));
    await prefs.setInt(
      '$_tsPrefix${year}_$langCode',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// 讀取快取的行事曆資料，若不存在或超過 30 天回傳 null
  static Future<Map<String, dynamic>?> getCalendarData(int year, {String? lang}) async {
    final langCode = _getCurrentLanguageCode(lang);
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('$_tsPrefix${year}_$langCode');
    if (ts == null) return null;

    final cachedTime = DateTime.fromMillisecondsSinceEpoch(ts);
    if (DateTime.now().difference(cachedTime) > _cacheDuration) {
      await prefs.remove('$_dataPrefix${year}_$langCode');
      await prefs.remove('$_tsPrefix${year}_$langCode');
      return null;
    }

    final raw = prefs.getString('$_dataPrefix${year}_$langCode');
    if (raw == null) return null;

    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// 清除所有年份的快取（同時清除 in-flight 追蹤）
  static Future<void> clearAllCache() async {
    _inFlight.clear();
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_dataPrefix) || key.startsWith(_tsPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  /// 正在進行中的請求（年份_語言 → Future），用於防止並行重複 API 呼叫
  static final Map<String, Future<Map<String, dynamic>?>> _inFlight = {};

  /// 讀快取 → miss 則呼叫 [apiFetcher] → 寫快取，並行呼叫自動去重。
  /// 同一年份若已有進行中的請求，會共享同一個 Future。
  static Future<Map<String, dynamic>?> getOrFetch(
    int year,
    String? lang,
    Future<Map<String, dynamic>> Function(int year, {String? lang}) apiFetcher,
  ) {
    final langCode = _getCurrentLanguageCode(lang);
    final key = '${year}_$langCode';
    if (_inFlight.containsKey(key)) return _inFlight[key]!;

    final future = _doGetOrFetch(year, lang, apiFetcher);
    _inFlight[key] = future;
    future.whenComplete(() => _inFlight.remove(key));
    return future;
  }

  static Future<Map<String, dynamic>?> _doGetOrFetch(
    int year,
    String? lang,
    Future<Map<String, dynamic>> Function(int year, {String? lang}) apiFetcher,
  ) async {
    final cached = await getCalendarData(year, lang: lang);
    if (cached != null) return cached;

    final data = await apiFetcher(year, lang: lang);
    if (data['success'] == true) {
      await saveCalendarData(year, data, lang: lang);
      return data;
    }
    return null;
  }
}
