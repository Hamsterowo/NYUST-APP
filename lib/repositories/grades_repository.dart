import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../database/database.dart';
import '../services/api_service.dart';
import 'refresh_outcome.dart';

/// 成績資料的 Repository：網路 → 正規化寫入 Drift → 由 Drift stream 推給 UI。
///
/// - [watchGrades] 回傳 Stream，DB 一有變動就重建與 scraper 相同結構的 Map。
/// - [refresh] 依 TTL 決定是否重新抓取；成功後正規化寫入資料表，並同步更新
///   `cache_grades`（給背景成績檢查 isolate 比對用）。
///
/// 透過 [ApiService] facade 取得資料，使 demo/除錯模式的切換（於執行期）
/// 在每次呼叫時即時生效。
class GradesRepository {
  final AppDatabase _db;
  final ApiService _api;

  static const String _datasetKey = 'grades';
  static const Duration _ttl = Duration(hours: 1);
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  GradesRepository(this._db, this._api);

  Stream<Map<String, dynamic>?> watchGrades() {
    return _db.select(_db.gradesSemesters).watch().asyncMap((_) => _buildMap());
  }

  /// 依 TTL 抓取成績。回傳 [RefreshOutcome]，失敗時含原因分類（離線/服務異常）。
  /// [force] 為 true 時忽略 TTL。
  Future<RefreshOutcome> refresh({bool force = false}) async {
    if (!force && !await _isStale()) return RefreshOutcome.success;

    final resp = await _api.getGrades();
    if (resp['success'] != true) return classifyRefreshFailure(resp);

    await _write(resp);
    try {
      await _secureStorage.write(key: 'cache_grades', value: jsonEncode(resp));
    } catch (_) {}
    return RefreshOutcome.success;
  }

  Future<void> clear() async {
    await _db.transaction(() async {
      await _db.delete(_db.gradesCourses).go();
      await _db.delete(_db.gradesSemesters).go();
      await _db.delete(_db.gradesCumulative).go();
      await (_db.delete(
        _db.cacheMeta,
      )..where((t) => t.datasetKey.equals(_datasetKey))).go();
    });
    try {
      await _secureStorage.delete(key: 'cache_grades');
    } catch (_) {}
  }

  Future<bool> _isStale() async {
    final meta = await (_db.select(
      _db.cacheMeta,
    )..where((t) => t.datasetKey.equals(_datasetKey))).getSingleOrNull();
    if (meta == null) return true;
    return DateTime.now().difference(meta.updatedAt) > _ttl;
  }

  Future<Map<String, dynamic>?> _buildMap() async {
    final sems = await (_db.select(
      _db.gradesSemesters,
    )..orderBy([(t) => OrderingTerm(expression: t.sortOrder)])).get();
    final cumRow = await (_db.select(
      _db.gradesCumulative,
    )..where((t) => t.id.equals(0))).getSingleOrNull();

    if (sems.isEmpty && cumRow == null) return null;

    final grades = <Map<String, dynamic>>[];
    for (final s in sems) {
      final courseRows =
          await (_db.select(_db.gradesCourses)
                ..where(
                  (t) =>
                      t.academicYear.equals(s.academicYear) &
                      t.semester.equals(s.semester),
                )
                ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
              .get();

      grades.add({
        'academic_year': s.academicYear,
        'semester': s.semester,
        'semester_title': s.semesterTitle,
        'courses': courseRows
            .map(
              (c) => {
                'code': c.code,
                'courseNo': c.courseNo,
                'name': c.name,
                'name_en': c.nameEn,
                'type': c.type,
                'credits': c.credits,
                'score': c.score,
                'syllabusUrl': c.syllabusUrl,
              },
            )
            .toList(),
        'summary': {
          'average_score': s.averageScore,
          'rank': s.rank,
          'gpa': s.gpa,
          'conduct': s.conduct,
          'attempted_credits': s.attemptedCredits,
          'earned_credits': s.earnedCredits,
        },
      });
    }

    Map<String, dynamic>? cumulative;
    if (cumRow != null) {
      cumulative = {
        'attempted_credits': cumRow.attemptedCredits,
        'earned_credits': cumRow.earnedCredits,
        'average': cumRow.average,
        'rank': cumRow.rank,
        'total_students': cumRow.totalStudents,
        'gpa': cumRow.gpa,
      };
    }

    return {'success': true, 'grades': grades, 'cumulative': cumulative};
  }

  Future<void> _write(Map<String, dynamic> resp) async {
    final List grades = (resp['grades'] as List?) ?? [];
    final cumulative = resp['cumulative'];

    await _db.transaction(() async {
      await _db.delete(_db.gradesCourses).go();
      await _db.delete(_db.gradesSemesters).go();
      await _db.delete(_db.gradesCumulative).go();

      for (var i = 0; i < grades.length; i++) {
        final g = grades[i] as Map;
        final ay = _toInt(g['academic_year']);
        final sem = _toInt(g['semester']);
        final summary = (g['summary'] as Map?) ?? const {};

        await _db
            .into(_db.gradesSemesters)
            .insert(
              GradesSemestersCompanion.insert(
                academicYear: ay,
                semester: sem,
                sortOrder: Value(i),
                semesterTitle: Value(_s(g['semester_title'])),
                averageScore: Value(_s(summary['average_score'])),
                rank: Value(_s(summary['rank'])),
                gpa: Value(_s(summary['gpa'])),
                conduct: Value(_s(summary['conduct'])),
                attemptedCredits: Value(_s(summary['attempted_credits'])),
                earnedCredits: Value(_s(summary['earned_credits'])),
              ),
              mode: InsertMode.insertOrReplace,
            );

        final courses = (g['courses'] as List?) ?? const [];
        for (var j = 0; j < courses.length; j++) {
          final c = courses[j] as Map;
          await _db
              .into(_db.gradesCourses)
              .insert(
                GradesCoursesCompanion.insert(
                  academicYear: ay,
                  semester: sem,
                  sortOrder: Value(j),
                  code: Value(_s(c['code'])),
                  courseNo: Value(_s(c['courseNo'])),
                  name: Value(_s(c['name'])),
                  nameEn: Value(_s(c['name_en'] ?? c['nameEn'])),
                  type: Value(_s(c['type'])),
                  credits: Value(_s(c['credits'])),
                  score: Value(_s(c['score'])),
                  syllabusUrl: Value(_s(c['syllabusUrl'])),
                ),
              );
        }
      }

      if (cumulative is Map) {
        await _db
            .into(_db.gradesCumulative)
            .insert(
              GradesCumulativeCompanion.insert(
                id: const Value(0),
                attemptedCredits: Value(_s(cumulative['attempted_credits'])),
                earnedCredits: Value(_s(cumulative['earned_credits'])),
                average: Value(_s(cumulative['average'])),
                rank: Value(_s(cumulative['rank'])),
                totalStudents: Value(_s(cumulative['total_students'])),
                gpa: Value(_s(cumulative['gpa'])),
              ),
              mode: InsertMode.insertOrReplace,
            );
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

  static int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static String _s(dynamic v) => v?.toString() ?? '';
}
