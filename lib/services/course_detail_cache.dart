import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 課程詳細資料的本地快取服務
/// 使用 SharedPreferences 持久化，快取有效期 7 天
/// 同時具備 in-flight 去重，避免同一門課被並行請求多次
class CourseDetailCache {
  static const _prefix = 'course_detail_';
  static const _tsPrefix = 'course_detail_ts_';
  static const _cacheDuration = Duration(days: 7);

  /// 正在進行中的請求（courseKey → Future），用於去重
  static final Map<String, Future<Map<String, dynamic>?>> _inFlight = {};

  /// 產生快取 key
  static String _key(String year, String semester, String courseNo) =>
      '${year}_${semester}_$courseNo';

  /// 讀取快取，若不存在或超過有效期則回傳 null
  static Future<Map<String, dynamic>?> get(
    String year,
    String semester,
    String courseNo,
  ) async {
    final key = _key(year, semester, courseNo);
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('$_tsPrefix$key');
    if (ts == null) return null;

    final cachedTime = DateTime.fromMillisecondsSinceEpoch(ts);
    if (DateTime.now().difference(cachedTime) > _cacheDuration) {
      await prefs.remove('$_prefix$key');
      await prefs.remove('$_tsPrefix$key');
      return null;
    }

    final raw = prefs.getString('$_prefix$key');
    if (raw == null) return null;

    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// 寫入快取
  static Future<void> save(
    String year,
    String semester,
    String courseNo,
    Map<String, dynamic> data,
  ) async {
    final key = _key(year, semester, courseNo);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$key', jsonEncode(data));
    await prefs.setInt('$_tsPrefix$key', DateTime.now().millisecondsSinceEpoch);
  }

  /// 清除所有課程詳細快取
  static Future<void> clearAll() async {
    _inFlight.clear();
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_prefix) || key.startsWith(_tsPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  /// 讀快取 → miss 則呼叫 [fetcher] → 寫快取，並行呼叫自動去重
  static Future<Map<String, dynamic>?> getOrFetch(
    String year,
    String semester,
    String courseNo,
    Future<Map<String, dynamic>> Function() fetcher,
  ) {
    final key = _key(year, semester, courseNo);
    if (_inFlight.containsKey(key)) return _inFlight[key]!;

    final future = _doGetOrFetch(year, semester, courseNo, fetcher);
    _inFlight[key] = future;
    future.whenComplete(() => _inFlight.remove(key));
    return future;
  }

  static Future<Map<String, dynamic>?> _doGetOrFetch(
    String year,
    String semester,
    String courseNo,
    Future<Map<String, dynamic>> Function() fetcher,
  ) async {

    final cached = await get(year, semester, courseNo);
    if (cached != null) return cached;

    final data = await fetcher();
    if (data['status'] == 'success') {
      await save(year, semester, courseNo, data);
      return data;
    }
    return data;
  }
}
