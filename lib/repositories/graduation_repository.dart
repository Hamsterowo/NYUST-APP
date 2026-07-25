import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/graduation_report.dart';
import '../services/api_service.dart';
import 'refresh_outcome.dart';

/// 畢業審核資料的 Repository。頂層欄位存 [GraduationInfo]（單列），
/// 各分組的學分明細以 EAV（[GraduationCredits]）儲存，重建時還原成
/// 型別化的 [GraduationReport]。
///
/// EAV 迴圈維持通用：寫入時走 [CreditGroup.toJson] 的 entries，讀回時交給
/// [GraduationReport.fromJson]，因此不需要手寫欄位↔欄名的對映表。
///
/// 透過 [ApiService] facade 取得資料，使 demo/除錯模式的切換即時生效。
class GraduationRepository {
  final AppDatabase _db;
  final ApiService _api;

  static const String _datasetKey = 'graduation';
  static const Duration _ttl = Duration(hours: 1);

  GraduationRepository(this._db, this._api);

  Stream<GraduationReport?> watchGraduation() {
    return _db
        .select(_db.graduationInfo)
        .watch()
        .asyncMap((_) => _buildReport());
  }

  /// 依 TTL 抓取畢業審核。回傳 [RefreshOutcome]，失敗時含原因分類。
  Future<RefreshOutcome> refresh({bool force = false}) async {
    if (!force && !await _isStale()) return RefreshOutcome.success;

    final result = await _api.getGraduation();
    if (!result.status.isSuccess) return result.status;

    await _write(result.data!);
    return RefreshOutcome.success;
  }

  Future<bool> _isStale() async {
    final meta = await (_db.select(
      _db.cacheMeta,
    )..where((t) => t.datasetKey.equals(_datasetKey))).getSingleOrNull();
    if (meta == null) return true;
    return DateTime.now().difference(meta.updatedAt) > _ttl;
  }

  Future<GraduationReport?> _buildReport() async {
    final info = await (_db.select(
      _db.graduationInfo,
    )..where((t) => t.id.equals(0))).getSingleOrNull();
    if (info == null) return null;

    final creditRows = await _db.select(_db.graduationCredits).get();
    final breakdown = <String, Map<String, dynamic>>{};
    for (final row in creditRows) {
      (breakdown[row.groupName] ??= <String, dynamic>{})[row.category] =
          row.value;
    }

    return GraduationReport.fromJson({
      'success': true,
      'graduation_info': {
        'total_credits': info.totalCredits,
        'english_threshold': info.englishThreshold,
        'internship_threshold': info.internshipThreshold,
        'credits_breakdown': breakdown,
        'missing_courses_text': info.missingCoursesText,
      },
    });
  }

  Future<void> _write(GraduationReport report) async {
    final breakdown = {
      'required_goal': report.requiredGoal.toJson(),
      'earned': report.earned.toJson(),
      'not_received': report.notReceived.toJson(),
      'missing': report.missing.toJson(),
    };

    await _db.transaction(() async {
      await _db.delete(_db.graduationCredits).go();
      await _db.delete(_db.graduationInfo).go();

      await _db
          .into(_db.graduationInfo)
          .insert(
            GraduationInfoCompanion.insert(
              id: const Value(0),
              totalCredits: Value(report.totalCredits),
              englishThreshold: Value(report.englishThreshold),
              internshipThreshold: Value(report.internshipThreshold),
              missingCoursesText: Value(report.missingCoursesText),
            ),
            mode: InsertMode.insertOrReplace,
          );

      for (final groupEntry in breakdown.entries) {
        for (final catEntry in groupEntry.value.entries) {
          await _db
              .into(_db.graduationCredits)
              .insert(
                GraduationCreditsCompanion.insert(
                  groupName: groupEntry.key,
                  category: catEntry.key,
                  value: Value(catEntry.value.toString()),
                ),
                mode: InsertMode.insertOrReplace,
              );
        }
      }

      await _db
          .into(_db.cacheMeta)
          .insert(
            CacheMetaCompanion.insert(
              datasetKey: _datasetKey,
              updatedAt: DateTime.now(),
            ),
            mode: InsertMode.insertOrReplace,
          );
    });
  }
}
