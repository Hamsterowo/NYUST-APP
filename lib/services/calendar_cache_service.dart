import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';

/// 行事曆本地快取服務
/// 使用 Drift (SQLite) 持久化行事曆 + 假日資料
/// 快取有效期為 30 天
///
/// 註：對外方法簽章與過去（SharedPreferences 版本）完全相同，呼叫端無需修改。
/// 所有 DB 存取都有防護，任何錯誤都會被視為「快取未命中」。
class CalendarCacheService {
  static const _cacheDuration = Duration(days: 30);

  static AppDatabase get _db => AppDatabase.instance;

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

  static String _key(int year, String langCode) => '${year}_$langCode';

  /// 儲存行事曆資料（合併端點的完整回應）
  static Future<void> saveCalendarData(
    int year,
    Map<String, dynamic> data, {
    String? lang,
  }) async {
    final langCode = _getCurrentLanguageCode(lang);
    try {
      await _db.into(_db.calendarCacheTable).insertOnConflictUpdate(
            CalendarCacheTableCompanion.insert(
              cacheKey: _key(year, langCode),
              dataJson: jsonEncode(data),
              updatedAt: DateTime.now(),
            ),
          );
    } catch (e) {
      if (kDebugMode) print('CalendarCacheService.save error: $e');
    }
  }

  /// 讀取快取的行事曆資料，若不存在或超過 30 天回傳 null
  static Future<Map<String, dynamic>?> getCalendarData(int year, {String? lang}) async {
    final langCode = _getCurrentLanguageCode(lang);
    final key = _key(year, langCode);
    try {
      final row = await (_db.select(_db.calendarCacheTable)
            ..where((t) => t.cacheKey.equals(key)))
          .getSingleOrNull();
      if (row == null) return null;

      if (DateTime.now().difference(row.updatedAt) > _cacheDuration) {
        await (_db.delete(_db.calendarCacheTable)
              ..where((t) => t.cacheKey.equals(key)))
            .go();
        return null;
      }

      return jsonDecode(row.dataJson) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) print('CalendarCacheService.get error: $e');
      return null;
    }
  }

  /// 清除所有年份的快取（同時清除 in-flight 追蹤）
  static Future<void> clearAllCache() async {
    _inFlight.clear();
    try {
      await _db.delete(_db.calendarCacheTable).go();
    } catch (e) {
      if (kDebugMode) print('CalendarCacheService.clearAllCache error: $e');
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
