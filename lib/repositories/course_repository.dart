import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/schedule_event.dart';
import '../services/api_service.dart';
import 'refresh_outcome.dart';

/// 一次 [CourseRepository.refresh] 的結果。
///
/// [snapshot] **只在真的發出網路請求時**才非 null；TTL 命中快取而直接成功時為
/// null。學期清單與當前學期只隨真實抓取而來，這個可空性即是該規則本身。
typedef ScheduleRefreshResult = ({
  RefreshOutcome outcome,
  ScheduleSnapshot? snapshot,
});

/// 課表資料的 Repository。課表課程正規化寫入 [ScheduleCourses]，
/// 重建時直接還原成型別化的 [ScheduleEvent]。
///
/// 透過 [ApiService] facade 取得資料，使 demo/除錯模式的切換即時生效。
class CourseRepository {
  final AppDatabase _db;
  final ApiService _api;

  static const String _datasetKey = 'schedule';
  static const Duration _ttl = Duration(hours: 1);

  CourseRepository(this._db, this._api);

  Stream<List<ScheduleEvent>> watchSchedule() {
    return _db
        .select(_db.scheduleCourses)
        .watch()
        .asyncMap((_) => _buildList());
  }

  /// 依 TTL 抓取課表。回傳失敗分類，以及（僅在實際抓取時）該次的
  /// [ScheduleSnapshot]，其中含學期清單與當前學期。
  Future<ScheduleRefreshResult> refresh({bool force = false}) async {
    if (!force && !await _isStale()) {
      return (outcome: RefreshOutcome.success, snapshot: null);
    }

    final result = await _api.getSchedule();
    if (!result.status.isSuccess) {
      return (outcome: result.status, snapshot: null);
    }

    final snapshot = result.data!;
    await _write(snapshot.courses);
    return (outcome: RefreshOutcome.success, snapshot: snapshot);
  }

  Future<void> clear() async {
    await _db.transaction(() async {
      await _db.delete(_db.scheduleCourses).go();
      await _db.delete(_db.semesterScheduleCacheTable).go();
      await (_db.delete(
        _db.cacheMeta,
      )..where((t) => t.datasetKey.equals(_datasetKey))).go();
    });
  }

  /// 載入所有已持久化的「其他學期」課表（key = 學期下拉選單 value）。
  /// 啟動時用來還原記憶體快取，使歷史學期跨重啟仍可離線顯示。
  Future<Map<String, List<ScheduleEvent>>> loadCachedSemesters() async {
    final rows = await _db.select(_db.semesterScheduleCacheTable).get();
    final result = <String, List<ScheduleEvent>>{};
    for (final r in rows) {
      try {
        final raw = jsonDecode(r.dataJson) as List<dynamic>;
        result[r.cacheKey] = raw
            .map(
              (e) =>
                  ScheduleEvent.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
      } catch (_) {
        // 略過毀損的一列。
      }
    }
    return result;
  }

  /// 持久化某「其他學期」的課表。
  /// 當前學期不走這裡（由 [refresh]/[watchSchedule] 的正規化表負責）。
  Future<void> saveCachedSemester(
    String key,
    List<ScheduleEvent> courses,
  ) async {
    if (key.isEmpty) return;
    await _db
        .into(_db.semesterScheduleCacheTable)
        .insert(
          SemesterScheduleCacheTableCompanion.insert(
            cacheKey: key,
            dataJson: jsonEncode(courses.map((c) => c.toJson()).toList()),
            updatedAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<bool> _isStale() async {
    final meta = await (_db.select(
      _db.cacheMeta,
    )..where((t) => t.datasetKey.equals(_datasetKey))).getSingleOrNull();
    if (meta == null) return true;
    return DateTime.now().difference(meta.updatedAt) > _ttl;
  }

  Future<List<ScheduleEvent>> _buildList() async {
    final rows = await (_db.select(
      _db.scheduleCourses,
    )..orderBy([(t) => OrderingTerm(expression: t.sortOrder)])).get();

    return rows.map((c) {
      List<dynamic> times;
      try {
        times = jsonDecode(c.timesJson) as List<dynamic>;
      } catch (_) {
        times = const [];
      }
      return ScheduleEvent(
        semesterCourseNo: c.semesterCourseNo,
        deptCourseNo: c.deptCourseNo,
        name: c.name,
        nameEn: c.nameEn,
        courseClass: c.courseClass,
        classType: c.classType,
        requiredType: c.requiredType,
        credits: c.credits,
        timeRoomStr: c.timeRoomStr,
        teacher: c.teacher,
        remark: c.remark,
        weekday: c.weekday,
        times: times.map((t) => t.toString()).toList(),
        room: c.room,
        syllabusUrl: c.syllabusUrl,
        year: c.year,
        semester: c.semester,
        courseNo: c.courseNo,
      );
    }).toList();
  }

  Future<void> _write(List<ScheduleEvent> courses) async {
    await _db.transaction(() async {
      await _db.delete(_db.scheduleCourses).go();

      for (var i = 0; i < courses.length; i++) {
        final c = courses[i];
        await _db
            .into(_db.scheduleCourses)
            .insert(
              ScheduleCoursesCompanion.insert(
                sortOrder: Value(i),
                semesterCourseNo: Value(c.semesterCourseNo),
                deptCourseNo: Value(c.deptCourseNo),
                name: Value(c.name),
                nameEn: Value(c.nameEn ?? ''),
                courseClass: Value(c.courseClass),
                classType: Value(c.classType),
                requiredType: Value(c.requiredType),
                credits: Value(c.credits),
                timeRoomStr: Value(c.timeRoomStr),
                teacher: Value(c.teacher),
                remark: Value(c.remark),
                weekday: Value(c.weekday ?? ''),
                timesJson: Value(jsonEncode(c.times)),
                room: Value(c.room ?? ''),
                syllabusUrl: Value(c.syllabusUrl ?? ''),
                year: Value(c.year ?? ''),
                semester: Value(c.semester ?? ''),
                courseNo: Value(c.courseNo ?? ''),
              ),
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
}
