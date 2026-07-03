import 'package:drift/drift.dart';
import '../database/database.dart';
import '../services/api_service.dart';

/// 畢業審核資料的 Repository。頂層欄位存 [GraduationInfo]（單列），
/// 各分組的學分明細以 EAV（[GraduationCredits]）儲存，重建時還原成巢狀 Map。
///
/// 透過 [ApiService] facade 取得資料，使 demo/除錯模式的切換即時生效。
class GraduationRepository {
  final AppDatabase _db;
  final ApiService _api;

  static const String _datasetKey = 'graduation';
  static const Duration _ttl = Duration(hours: 1);

  GraduationRepository(this._db, this._api);

  Stream<Map<String, dynamic>?> watchGraduation() {
    return _db.select(_db.graduationInfo).watch().asyncMap((_) => _buildMap());
  }

  Future<bool> refresh({bool force = false}) async {
    if (!force && !await _isStale()) return true;

    final resp = await _api.getGraduation();
    if (resp['success'] != true) return false;

    await _write(resp);
    return true;
  }

  Future<void> clear() async {
    await _db.transaction(() async {
      await _db.delete(_db.graduationCredits).go();
      await _db.delete(_db.graduationInfo).go();
      await (_db.delete(_db.cacheMeta)
            ..where((t) => t.datasetKey.equals(_datasetKey)))
          .go();
    });
  }

  Future<bool> _isStale() async {
    final meta = await (_db.select(_db.cacheMeta)
          ..where((t) => t.datasetKey.equals(_datasetKey)))
        .getSingleOrNull();
    if (meta == null) return true;
    return DateTime.now().difference(meta.updatedAt) > _ttl;
  }

  Future<Map<String, dynamic>?> _buildMap() async {
    final info = await (_db.select(_db.graduationInfo)
          ..where((t) => t.id.equals(0)))
        .getSingleOrNull();
    if (info == null) return null;

    final creditRows = await _db.select(_db.graduationCredits).get();
    final breakdown = <String, Map<String, dynamic>>{};
    for (final row in creditRows) {
      (breakdown[row.groupName] ??= <String, dynamic>{})[row.category] =
          row.value;
    }

    return {
      'success': true,
      'graduation_info': {
        'total_credits': info.totalCredits,
        'english_threshold': info.englishThreshold,
        'internship_threshold': info.internshipThreshold,
        'credits_breakdown': breakdown,
        'missing_courses_text': info.missingCoursesText,
      },
    };
  }

  Future<void> _write(Map<String, dynamic> resp) async {
    final info = (resp['graduation_info'] as Map?) ?? const {};
    final breakdown = (info['credits_breakdown'] as Map?) ?? const {};

    await _db.transaction(() async {
      await _db.delete(_db.graduationCredits).go();
      await _db.delete(_db.graduationInfo).go();

      await _db.into(_db.graduationInfo).insert(
            GraduationInfoCompanion.insert(
              id: const Value(0),
              totalCredits: Value(_s(info['total_credits'])),
              englishThreshold: Value(_s(info['english_threshold'])),
              internshipThreshold: Value(_s(info['internship_threshold'])),
              missingCoursesText: Value(_s(info['missing_courses_text'])),
            ),
            mode: InsertMode.insertOrReplace,
          );

      for (final groupEntry in breakdown.entries) {
        final categories = groupEntry.value;
        if (categories is Map) {
          for (final catEntry in categories.entries) {
            await _db.into(_db.graduationCredits).insert(
                  GraduationCreditsCompanion.insert(
                    groupName: groupEntry.key.toString(),
                    category: catEntry.key.toString(),
                    value: Value(_s(catEntry.value)),
                  ),
                  mode: InsertMode.insertOrReplace,
                );
          }
        }
      }

      await _db.into(_db.cacheMeta).insert(
            CacheMetaCompanion.insert(
              datasetKey: _datasetKey,
              updatedAt: DateTime.now(),
            ),
            mode: InsertMode.insertOrReplace,
          );
    });
  }

  static String _s(dynamic v) => v?.toString() ?? '';
}
