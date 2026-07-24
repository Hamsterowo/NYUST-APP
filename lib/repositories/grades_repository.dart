import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../database/database.dart';
import '../models/grade_report.dart';
import '../services/api_service.dart';
import 'refresh_outcome.dart';

/// 成績資料的 Repository：網路 → 正規化寫入 Drift → 由 Drift stream 推給 UI。
///
/// - [watchGrades] 回傳 `Stream<GradeReport?>`，DB 一有變動就重建型別化模型。
/// - [refresh] 依 TTL 決定是否重新抓取；成功後正規化寫入資料表，並同步更新
///   `cache_grades`（給背景成績檢查 isolate 比對用，以 [GradeReport.toJson] 的
///   wire 形狀持久化，維持與 `grades_comparator` 相容）。
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

  Stream<GradeReport?> watchGrades() {
    return _db
        .select(_db.gradesSemesters)
        .watch()
        .asyncMap((_) => _buildReport());
  }

  /// 依 TTL 抓取成績。回傳 [RefreshOutcome]，失敗時含原因分類（離線/服務異常）。
  /// [force] 為 true 時忽略 TTL。
  Future<RefreshOutcome> refresh({bool force = false}) async {
    if (!force && !await _isStale()) return RefreshOutcome.success;

    final result = await _api.getGrades();
    if (!result.status.isSuccess) return result.status;

    final report = result.data!;
    await _write(report);
    try {
      await _secureStorage.write(
        key: 'cache_grades',
        value: jsonEncode(report.toJson()),
      );
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

  Future<GradeReport?> _buildReport() async {
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

    return GradeReport.fromJson({
      'success': true,
      'grades': grades,
      'cumulative': cumulative,
    });
  }

  Future<void> _write(GradeReport report) async {
    await _db.transaction(() async {
      await _db.delete(_db.gradesCourses).go();
      await _db.delete(_db.gradesSemesters).go();
      await _db.delete(_db.gradesCumulative).go();

      for (var i = 0; i < report.semesters.length; i++) {
        final g = report.semesters[i];
        final ay = _toInt(g.academicYear);
        final sem = _toInt(g.semester);

        await _db
            .into(_db.gradesSemesters)
            .insert(
              GradesSemestersCompanion.insert(
                academicYear: ay,
                semester: sem,
                sortOrder: Value(i),
                semesterTitle: Value(g.semesterTitle),
                averageScore: Value(g.averageScore),
                rank: Value(g.rank),
                gpa: Value(g.gpa),
                conduct: Value(g.conduct),
                attemptedCredits: Value(g.attemptedCredits),
                earnedCredits: Value(g.earnedCredits),
              ),
              mode: InsertMode.insertOrReplace,
            );

        for (var j = 0; j < g.courses.length; j++) {
          final c = g.courses[j];
          await _db
              .into(_db.gradesCourses)
              .insert(
                GradesCoursesCompanion.insert(
                  academicYear: ay,
                  semester: sem,
                  sortOrder: Value(j),
                  code: Value(c.code),
                  courseNo: Value(c.courseNo),
                  name: Value(c.name),
                  nameEn: Value(c.nameEn),
                  type: Value(c.type),
                  credits: Value(c.credits),
                  score: Value(c.score),
                  syllabusUrl: Value(c.syllabusUrl),
                ),
              );
        }
      }

      final cumulative = report.cumulative;
      if (cumulative != null) {
        await _db
            .into(_db.gradesCumulative)
            .insert(
              GradesCumulativeCompanion.insert(
                id: const Value(0),
                attemptedCredits: Value(cumulative.attemptedCredits),
                earnedCredits: Value(cumulative.earnedCredits),
                average: Value(cumulative.average),
                rank: Value(cumulative.rank),
                totalStudents: Value(cumulative.totalStudents),
                gpa: Value(cumulative.gpa),
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

  static int _toInt(String v) => int.tryParse(v) ?? 0;
}
