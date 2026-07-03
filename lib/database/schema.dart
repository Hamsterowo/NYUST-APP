import 'package:drift/drift.dart';

/// 課程詳情快取表（取代原本 [CourseDetailCache] 的 SharedPreferences 後端）。
///
/// [cacheKey] 為 `year_semester_courseNo`，[dataJson] 存整包課程詳情 JSON，
/// [updatedAt] 用於 TTL 過期判斷（原本為 7 天）。
class CourseDetailCacheTable extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get dataJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {cacheKey};

  @override
  String get tableName => 'course_detail_cache';
}

/// 行事曆快取表（取代原本 [CalendarCacheService] 的 SharedPreferences 後端）。
///
/// [cacheKey] 為 `year_lang`，[dataJson] 存合併後的行事曆 + 假日 JSON，
/// [updatedAt] 用於 TTL 過期判斷（原本為 30 天）。
class CalendarCacheTable extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get dataJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {cacheKey};

  @override
  String get tableName => 'calendar_cache';
}
