import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'schema.dart';

part 'database.g.dart';

/// App 的本地 Drift (SQLite) 資料庫。
///
/// 承載非敏感的快取與學術資料：
/// - Stage 3A：課程詳情、行事曆的 keyed JSON 快取表
/// - Stage 3B：正規化的成績 / 課表 / 畢業審核資料表（供 Repository 與未來統計查詢）
///
/// 敏感資料（帳號、密碼、Cookie）仍保留在 `flutter_secure_storage`，不進此資料庫。
@DriftDatabase(
  tables: [
    // Stage 3A
    CourseDetailCacheTable,
    CalendarCacheTable,
    SemesterScheduleCacheTable,
    // Stage 3B
    CacheMeta,
    GradesSemesters,
    GradesCourses,
    GradesCumulative,
    ScheduleCourses,
    GraduationInfo,
    GraduationCredits,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // v1 (Stage 3A) → v2 (Stage 3B): 新增正規化的學術資料表。
      if (from < 2) {
        await m.createTable(cacheMeta);
        await m.createTable(gradesSemesters);
        await m.createTable(gradesCourses);
        await m.createTable(gradesCumulative);
        await m.createTable(scheduleCourses);
        await m.createTable(graduationInfo);
        await m.createTable(graduationCredits);
      }
      // v2 → v3: 新增「其他學期課表」的持久化快取表。
      if (from < 3) {
        await m.createTable(semesterScheduleCacheTable);
      }
    },
  );

  /// 全 App 共用的單例。各快取服務與 Repository 透過此存取資料庫。
  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase();

  static QueryExecutor _open() {
    return driftDatabase(
      name: 'yun_tool_db',
      // Web 平台需要 sqlite3.wasm 與 drift_worker.js（放在 web/ 目錄）。
      // 若缺少這些資產，開啟資料庫會失敗，但各快取服務已對 DB 錯誤做防護
      // （視為 cache miss），因此 Web 仍可正常運作，只是少了本地快取。
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
}
