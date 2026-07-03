import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'schema.dart';

part 'database.g.dart';

/// App 的本地 Drift (SQLite) 資料庫。
///
/// 目前只承載非敏感的**快取**資料（課程詳情、行事曆）。
/// 敏感資料（帳號、密碼、Cookie）仍保留在 `flutter_secure_storage`，不進此資料庫。
@DriftDatabase(tables: [CourseDetailCacheTable, CalendarCacheTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 1;

  /// 全 App 共用的單例。各快取服務透過此存取資料庫。
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
