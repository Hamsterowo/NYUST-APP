import 'package:drift/drift.dart';

// ---------------------------------------------------------------------------
// 快取表（Stage 3A）— 以 keyed JSON blob 儲存
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// 正規化的學術資料表（Stage 3B）— 供 Repository + 未來統計查詢使用
// ---------------------------------------------------------------------------

/// 每個資料集（grades / graduation / schedule）最後一次成功更新的時間，用於 TTL。
class CacheMeta extends Table {
  TextColumn get datasetKey => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {datasetKey};

  @override
  String get tableName => 'cache_meta';
}

/// 各學期成績摘要（主鍵：學年 + 學期）。
class GradesSemesters extends Table {
  IntColumn get academicYear => integer()();
  IntColumn get semester => integer()();

  /// 於 grades 陣列中的原始順序，重建時用來還原顯示順序。
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  TextColumn get semesterTitle => text().withDefault(const Constant(''))();
  TextColumn get averageScore => text().withDefault(const Constant(''))();
  TextColumn get rank => text().withDefault(const Constant(''))();
  TextColumn get gpa => text().withDefault(const Constant(''))();
  TextColumn get conduct => text().withDefault(const Constant(''))();
  TextColumn get attemptedCredits => text().withDefault(const Constant(''))();
  TextColumn get earnedCredits => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {academicYear, semester};

  @override
  String get tableName => 'grades_semesters';
}

/// 各學期的課程成績（歸屬到 [GradesSemesters]）。
class GradesCourses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get academicYear => integer()();
  IntColumn get semester => integer()();

  /// 於該學期 courses 陣列中的原始順序。
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  TextColumn get code => text().withDefault(const Constant(''))();
  TextColumn get courseNo => text().withDefault(const Constant(''))();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get nameEn => text().withDefault(const Constant(''))();
  TextColumn get type => text().withDefault(const Constant(''))();
  TextColumn get credits => text().withDefault(const Constant(''))();
  TextColumn get score => text().withDefault(const Constant(''))();
  TextColumn get syllabusUrl => text().withDefault(const Constant(''))();

  @override
  String get tableName => 'grades_courses';
}

/// 累計成績（單列，[id] 恆為 0）。
class GradesCumulative extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  TextColumn get attemptedCredits => text().withDefault(const Constant(''))();
  TextColumn get earnedCredits => text().withDefault(const Constant(''))();
  TextColumn get average => text().withDefault(const Constant(''))();
  TextColumn get rank => text().withDefault(const Constant(''))();
  TextColumn get totalStudents => text().withDefault(const Constant(''))();
  TextColumn get gpa => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'grades_cumulative';
}

/// 本學期課表課程。
class ScheduleCourses extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 於 schedule 陣列中的原始順序。
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  TextColumn get semesterCourseNo => text().withDefault(const Constant(''))();
  TextColumn get deptCourseNo => text().withDefault(const Constant(''))();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get nameEn => text().withDefault(const Constant(''))();
  TextColumn get courseClass => text().withDefault(const Constant(''))();
  TextColumn get classType => text().withDefault(const Constant(''))();
  TextColumn get requiredType => text().withDefault(const Constant(''))();
  TextColumn get credits => text().withDefault(const Constant(''))();
  TextColumn get timeRoomStr => text().withDefault(const Constant(''))();
  TextColumn get teacher => text().withDefault(const Constant(''))();
  TextColumn get remark => text().withDefault(const Constant(''))();
  TextColumn get weekday => text().withDefault(const Constant(''))();

  /// times 陣列以 JSON 字串儲存。
  TextColumn get timesJson => text().withDefault(const Constant('[]'))();
  TextColumn get room => text().withDefault(const Constant(''))();
  TextColumn get syllabusUrl => text().withDefault(const Constant(''))();
  TextColumn get year => text().withDefault(const Constant(''))();
  TextColumn get semester => text().withDefault(const Constant(''))();
  TextColumn get courseNo => text().withDefault(const Constant(''))();

  @override
  String get tableName => 'schedule_courses';
}

/// 畢業審核的頂層資訊（單列，[id] 恆為 0）。
class GraduationInfo extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  TextColumn get totalCredits => text().withDefault(const Constant(''))();
  TextColumn get englishThreshold => text().withDefault(const Constant(''))();
  TextColumn get internshipThreshold => text().withDefault(const Constant(''))();
  TextColumn get missingCoursesText => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'graduation_info';
}

/// 畢業學分明細，以 EAV（group + category → value）儲存，
/// 以容納各分組（required_goal / earned / not_received / missing）不一致的欄位集合。
class GraduationCredits extends Table {
  TextColumn get groupName => text()();
  TextColumn get category => text()();
  TextColumn get value => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {groupName, category};

  @override
  String get tableName => 'graduation_credits';
}
