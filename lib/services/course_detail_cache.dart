import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../database/database.dart';

/// 課程詳細資料的本地快取服務
/// 使用 Drift (SQLite) 持久化，快取有效期 7 天
/// 同時具備 in-flight 去重，避免同一門課被並行請求多次
///
/// 註：對外方法簽章與過去（SharedPreferences 版本）完全相同，呼叫端無需修改。
/// 所有 DB 存取都有防護，任何錯誤都會被視為「快取未命中」，確保即使資料庫
/// 不可用（例如 Web 缺少 sqlite3.wasm）App 仍能正常運作。
class CourseDetailCache {
  static const _cacheDuration = Duration(days: 7);

  /// 正在進行中的請求（courseKey → Future），用於去重
  static final Map<String, Future<Map<String, dynamic>?>> _inFlight = {};

  static AppDatabase get _db => AppDatabase.instance;

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
    try {
      final row = await (_db.select(_db.courseDetailCacheTable)
            ..where((t) => t.cacheKey.equals(key)))
          .getSingleOrNull();
      if (row == null) return null;

      if (DateTime.now().difference(row.updatedAt) > _cacheDuration) {
        await (_db.delete(_db.courseDetailCacheTable)
              ..where((t) => t.cacheKey.equals(key)))
            .go();
        return null;
      }

      return jsonDecode(row.dataJson) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) print('CourseDetailCache.get error: $e');
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
    try {
      await _db.into(_db.courseDetailCacheTable).insertOnConflictUpdate(
            CourseDetailCacheTableCompanion.insert(
              cacheKey: key,
              dataJson: jsonEncode(data),
              updatedAt: DateTime.now(),
            ),
          );
    } catch (e) {
      if (kDebugMode) print('CourseDetailCache.save error: $e');
    }
  }

  /// 清除所有課程詳細快取
  static Future<void> clearAll() async {
    _inFlight.clear();
    try {
      await _db.delete(_db.courseDetailCacheTable).go();
    } catch (e) {
      if (kDebugMode) print('CourseDetailCache.clearAll error: $e');
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
