import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../database/database.dart';
import '../models/course_detail_model.dart';
import 'scrape_result.dart';

/// 課程詳細資料的本地快取服務
/// 使用 Drift (SQLite) 持久化，快取有效期 7 天
/// 同時具備 in-flight 去重，避免同一門課被並行請求多次
///
/// 快取內容為型別化的 [CourseDetail]；舊版存的是整個回應信封，
/// [CourseDetail.fromJson] 會自動解開，因此升級後既有快取仍可離線使用，
/// 並在下次重抓時自然被新格式覆蓋。
///
/// 所有 DB 存取都有防護，任何錯誤都會被視為「快取未命中」，確保即使資料庫
/// 不可用（例如 Web 缺少 sqlite3.wasm）App 仍能正常運作。
class CourseDetailCache {
  static const _cacheDuration = Duration(days: 7);

  /// 正在進行中的請求（courseKey → Future），用於去重
  static final Map<String, Future<ScrapeResult<CourseDetail>>> _inFlight = {};

  static AppDatabase get _db => AppDatabase.instance;

  /// 產生快取 key
  static String _key(String year, String semester, String courseNo) =>
      '${year}_${semester}_$courseNo';

  /// 讀取快取，若不存在或超過有效期則回傳 null
  static Future<CourseDetail?> get(
    String year,
    String semester,
    String courseNo,
  ) async {
    final key = _key(year, semester, courseNo);
    try {
      final row = await (_db.select(
        _db.courseDetailCacheTable,
      )..where((t) => t.cacheKey.equals(key))).getSingleOrNull();
      if (row == null) return null;

      if (DateTime.now().difference(row.updatedAt) > _cacheDuration) {
        await (_db.delete(
          _db.courseDetailCacheTable,
        )..where((t) => t.cacheKey.equals(key))).go();
        return null;
      }

      return CourseDetail.fromJson(
        Map<String, dynamic>.from(jsonDecode(row.dataJson) as Map),
      );
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
    CourseDetail detail,
  ) async {
    final key = _key(year, semester, courseNo);
    try {
      await _db
          .into(_db.courseDetailCacheTable)
          .insertOnConflictUpdate(
            CourseDetailCacheTableCompanion.insert(
              cacheKey: key,
              dataJson: jsonEncode(detail.toJson()),
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
  static Future<ScrapeResult<CourseDetail>> getOrFetch(
    String year,
    String semester,
    String courseNo,
    Future<ScrapeResult<CourseDetail>> Function() fetcher,
  ) {
    final key = _key(year, semester, courseNo);
    final inFlight = _inFlight[key];
    if (inFlight != null) return inFlight;

    final future = _doGetOrFetch(year, semester, courseNo, fetcher);
    _inFlight[key] = future;
    future.whenComplete(() => _inFlight.remove(key));
    return future;
  }

  static Future<ScrapeResult<CourseDetail>> _doGetOrFetch(
    String year,
    String semester,
    String courseNo,
    Future<ScrapeResult<CourseDetail>> Function() fetcher,
  ) async {
    final cached = await get(year, semester, courseNo);
    if (cached != null) return ScrapeResult.success(cached);

    final result = await fetcher();
    if (result.isSuccess) {
      await save(year, semester, courseNo, result.data!);
    }
    return result;
  }
}
