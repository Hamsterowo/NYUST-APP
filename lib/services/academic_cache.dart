import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../database/database.dart';
import 'calendar_cache_service.dart';
import 'course_detail_cache.dart';

/// 學業快取（成績 / 畢業門檻 / 課表 / 課綱 / 行事曆）的整體重設與歸屬。
///
/// 這裡是「把某個帳號的快取整份清掉」的**唯一**入口，而且刻意**不依賴任何
/// provider** —— 它只需要 Drift 單例與 secure storage。過去清除只能經由
/// `DataProvider` 的登出回呼觸發，而該 provider 是惰性建立的：開機時若在任何
/// 資料頁被開啟前就登出，回呼還沒接上，快取便原封留給下一個登入的帳號。
///
/// [claimFor] 進一步把快取和帳號綁在一起：只要登入的學號與快取記錄的擁有者
/// 不符（或根本沒記錄），就先清空再開始。如此一來保證不再取決於「每一條登出
/// 路徑都寫對」。
class AcademicCache {
  const AcademicCache._();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// 目前快取屬於哪個學號。快取被清空時一併移除。
  static const String _ownerKey = 'cache_owner_id';

  /// 成績的 JSON 副本（背景成績比對 isolate 使用）。
  static const String _gradesCacheKey = 'cache_grades';

  /// 清空所有學業快取，並抹除擁有者記錄。
  ///
  /// 登出、以及發現快取屬於別的帳號時呼叫。任何一步失敗都不應阻斷其餘清除，
  /// 因此個別包覆例外。
  static Future<void> clearAll() async {
    try {
      final db = AppDatabase.instance;
      await db.transaction(() async {
        await db.delete(db.gradesCourses).go();
        await db.delete(db.gradesSemesters).go();
        await db.delete(db.gradesCumulative).go();
        await db.delete(db.graduationCredits).go();
        await db.delete(db.graduationInfo).go();
        await db.delete(db.scheduleCourses).go();
        await db.delete(db.semesterScheduleCacheTable).go();
        await db.delete(db.cacheMeta).go();
      });
    } catch (_) {
      // DB 不可用（例如 Web 缺少 sqlite3.wasm）時視同無快取可清。
    }

    try {
      await _secureStorage.delete(key: _gradesCacheKey);
    } catch (_) {}

    try {
      await CourseDetailCache.clearAll();
    } catch (_) {}

    try {
      await CalendarCacheService.clearAllCache();
    } catch (_) {}

    await _forgetOwner();
  }

  /// 宣告目前的快取屬於 [accountId]。
  ///
  /// 與記錄中的擁有者不符（或尚無記錄，例如從舊版升級上來）時，先 [clearAll]
  /// 再記下新擁有者，確保下一個帳號不會看到上一個帳號的資料。
  /// [accountId] 為空時不做任何事（尚不知道自己是誰，寧可不動）。
  static Future<void> claimFor(String accountId) async {
    if (accountId.isEmpty) return;

    final current = await _owner();
    if (current == accountId) return;

    await clearAll();
    try {
      await _secureStorage.write(key: _ownerKey, value: accountId);
    } catch (_) {}
  }

  static Future<String?> _owner() async {
    try {
      return await _secureStorage.read(key: _ownerKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _forgetOwner() async {
    try {
      await _secureStorage.delete(key: _ownerKey);
    } catch (_) {}
  }
}
