import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../services/api_service.dart';

/// 課表資料的 Repository。將課表課程正規化寫入 [ScheduleCourses]，
/// 重建時還原成與 scraper 相同結構的 Map（`status` / `data.schedule`）。
///
/// 透過 [ApiService] facade 取得資料，使 demo/除錯模式的切換即時生效。
class CourseRepository {
  final AppDatabase _db;
  final ApiService _api;

  static const String _datasetKey = 'schedule';
  static const Duration _ttl = Duration(hours: 1);

  /// 上次線上抓取到的學期選項（value + label）與當前學期代碼。
  /// 只有實際發出網路請求時才會更新（快取命中時維持不變）。
  List<Map<String, String>> semesters = const [];
  String currentSemester = '';

  CourseRepository(this._db, this._api);

  Stream<Map<String, dynamic>?> watchSchedule() {
    return _db.select(_db.scheduleCourses).watch().asyncMap((_) => _buildMap());
  }

  Future<bool> refresh({bool force = false}) async {
    if (!force && !await _isStale()) return true;

    final resp = await _api.getSchedule();
    if (resp['status'] != 'success' || resp['data'] == null) return false;

    _captureMeta(resp);
    await _write(resp);
    return true;
  }

  /// 從回應擷取學期選項清單與當前學期代碼。
  void _captureMeta(Map<String, dynamic> resp) {
    final data = resp['data'] as Map?;
    final raw = (data?['semesters'] as List?) ?? const [];
    semesters = raw
        .map(
          (e) => (e as Map).map(
            (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
          ),
        )
        .toList();
    currentSemester = (data?['currentSemester'] ?? '').toString();
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

  /// 載入所有已持久化的「其他學期」課表（key = 學期下拉選單 value，
  /// value = 該學期課程陣列的原始 map 清單）。啟動時用來還原記憶體快取，
  /// 使歷史學期跨重啟仍可離線顯示。
  Future<Map<String, List<dynamic>>> loadCachedSemesters() async {
    final rows = await _db.select(_db.semesterScheduleCacheTable).get();
    final result = <String, List<dynamic>>{};
    for (final r in rows) {
      try {
        result[r.cacheKey] = jsonDecode(r.dataJson) as List<dynamic>;
      } catch (_) {
        // 略過毀損的一列。
      }
    }
    return result;
  }

  /// 持久化某「其他學期」的課表原始課程陣列。
  /// 當前學期不走這裡（由 [refresh]/[watchSchedule] 的正規化表負責）。
  Future<void> saveCachedSemester(String key, List<dynamic> courses) async {
    if (key.isEmpty) return;
    await _db
        .into(_db.semesterScheduleCacheTable)
        .insert(
          SemesterScheduleCacheTableCompanion.insert(
            cacheKey: key,
            dataJson: jsonEncode(courses),
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

  Future<Map<String, dynamic>?> _buildMap() async {
    final rows = await (_db.select(
      _db.scheduleCourses,
    )..orderBy([(t) => OrderingTerm(expression: t.sortOrder)])).get();
    if (rows.isEmpty) return null;

    final schedule = rows.map((c) {
      List<dynamic> times;
      try {
        times = jsonDecode(c.timesJson) as List<dynamic>;
      } catch (_) {
        times = const [];
      }
      return {
        'semesterCourseNo': c.semesterCourseNo,
        'deptCourseNo': c.deptCourseNo,
        'name': c.name,
        'nameEn': c.nameEn,
        'courseClass': c.courseClass,
        'classType': c.classType,
        'requiredType': c.requiredType,
        'credits': c.credits,
        'timeRoomStr': c.timeRoomStr,
        'teacher': c.teacher,
        'remark': c.remark,
        'weekday': c.weekday,
        'times': times,
        'room': c.room,
        'syllabusUrl': c.syllabusUrl,
        'year': c.year,
        'semester': c.semester,
        'courseNo': c.courseNo,
      };
    }).toList();

    return {
      'status': 'success',
      'data': {'schedule': schedule},
    };
  }

  Future<void> _write(Map<String, dynamic> resp) async {
    final List courses = (resp['data']?['schedule'] as List?) ?? const [];

    await _db.transaction(() async {
      await _db.delete(_db.scheduleCourses).go();

      for (var i = 0; i < courses.length; i++) {
        final c = courses[i] as Map;
        await _db
            .into(_db.scheduleCourses)
            .insert(
              ScheduleCoursesCompanion.insert(
                sortOrder: Value(i),
                semesterCourseNo: Value(_s(c['semesterCourseNo'])),
                deptCourseNo: Value(_s(c['deptCourseNo'])),
                name: Value(_s(c['name'])),
                nameEn: Value(_s(c['nameEn'] ?? c['name_en'])),
                courseClass: Value(_s(c['courseClass'])),
                classType: Value(_s(c['classType'])),
                requiredType: Value(_s(c['requiredType'])),
                credits: Value(_s(c['credits'])),
                timeRoomStr: Value(_s(c['timeRoomStr'])),
                teacher: Value(_s(c['teacher'])),
                remark: Value(_s(c['remark'])),
                weekday: Value(_s(c['weekday'])),
                timesJson: Value(jsonEncode(c['times'] ?? const [])),
                room: Value(_s(c['room'])),
                syllabusUrl: Value(_s(c['syllabusUrl'])),
                year: Value(_s(c['year'])),
                semester: Value(_s(c['semester'])),
                courseNo: Value(_s(c['courseNo'])),
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

  static String _s(dynamic v) => v?.toString() ?? '';
}
