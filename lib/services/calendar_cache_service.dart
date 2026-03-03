import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 行事曆本地快取服務
/// 使用 SharedPreferences 持久化行事曆 + 假日資料
/// 快取有效期為 30 天
class CalendarCacheService {
  static const _dataPrefix = 'calendar_data_';
  static const _tsPrefix = 'calendar_ts_';
  static const _cacheDuration = Duration(days: 30);

  /// 儲存行事曆資料（合併端點的完整回應）
  static Future<void> saveCalendarData(
    int year,
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_dataPrefix$year', jsonEncode(data));
    await prefs.setInt(
      '$_tsPrefix$year',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// 讀取快取的行事曆資料，若不存在或超過 30 天回傳 null
  static Future<Map<String, dynamic>?> getCalendarData(int year) async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('$_tsPrefix$year');
    if (ts == null) return null;

    final cachedTime = DateTime.fromMillisecondsSinceEpoch(ts);
    if (DateTime.now().difference(cachedTime) > _cacheDuration) {
      // 快取過期，清除
      await prefs.remove('$_dataPrefix$year');
      await prefs.remove('$_tsPrefix$year');
      return null;
    }

    final raw = prefs.getString('$_dataPrefix$year');
    if (raw == null) return null;

    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// 清除所有年份的快取
  static Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_dataPrefix) || key.startsWith(_tsPrefix)) {
        await prefs.remove(key);
      }
    }
  }
}
