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

  // ─── In-flight 請求去重 ──────────────────────────────────────────────────

  /// 正在進行中的請求（年份 → Future），用於防止並行重複 API 呼叫
  static final Map<int, Future<Map<String, dynamic>?>> _inFlight = {};

  /// 讀快取 → miss 則呼叫 [apiFetcher] → 寫快取，並行呼叫自動去重。
  /// 同一年份若已有進行中的請求，會共享同一個 Future。
  static Future<Map<String, dynamic>?> getOrFetch(
    int year,
    Future<Map<String, dynamic>> Function(int year) apiFetcher,
  ) {
    if (_inFlight.containsKey(year)) return _inFlight[year]!;

    final future = _doGetOrFetch(year, apiFetcher);
    _inFlight[year] = future;
    future.whenComplete(() => _inFlight.remove(year));
    return future;
  }

  static Future<Map<String, dynamic>?> _doGetOrFetch(
    int year,
    Future<Map<String, dynamic>> Function(int year) apiFetcher,
  ) async {
    // 1. 讀本地快取
    final cached = await getCalendarData(year);
    if (cached != null) return cached;

    // 2. 快取 miss → 呼叫 API
    final data = await apiFetcher(year);
    if (data['success'] == true) {
      await saveCalendarData(year, data);
      return data;
    }
    return null;
  }
}
