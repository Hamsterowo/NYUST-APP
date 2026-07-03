import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database/database.dart';
import '../repositories/grades_repository.dart';
import '../repositories/graduation_repository.dart';
import '../repositories/course_repository.dart';
import '../services/api_service.dart';
import '../services/course_detail_cache.dart';
import '../services/calendar_cache_service.dart';
import '../models/schedule_event.dart';
import 'auth_provider.dart';

/// 集中管理所有已載入的 App 資料，避免切換頁面時重複呼叫 API。
///
/// Stage 3B 起改為架在 Repository 之上：資料流為 網路 → Drift → stream → UI。
/// 本類別不再自行做 JSON 快取或成績新鮮度判斷（已下放到各 Repository + Drift），
/// 只負責訂閱 Repository 的 stream、維持既有的對外欄位與 loading 狀態給畫面使用。
class DataProvider with ChangeNotifier {
  final ApiService _api;
  final AuthProvider _auth;

  late final GradesRepository _gradesRepo;
  late final GraduationRepository _graduationRepo;
  late final CourseRepository _courseRepo;

  StreamSubscription<Map<String, dynamic>?>? _gradesSub;
  StreamSubscription<Map<String, dynamic>?>? _graduationSub;
  StreamSubscription<Map<String, dynamic>?>? _scheduleSub;

  bool _isCacheLoaded = false;
  bool get isCacheLoaded => _isCacheLoaded;

  Map<String, dynamic>? gradesData;
  bool isLoadingGrades = false;
  bool gradesFailed = false;

  Map<String, dynamic>? graduationData;
  bool isLoadingGraduation = false;
  bool graduationFailed = false;

  List<ScheduleEvent> scheduleData = [];
  bool isLoadingSchedule = false;
  bool scheduleFailed = false;

  bool _isPrefetching = false;
  bool get isPrefetching => _isPrefetching;

  DataProvider(this._api, this._auth) {
    final db = AppDatabase.instance;
    _gradesRepo = GradesRepository(db, _api);
    _graduationRepo = GraduationRepository(db, _api);
    _courseRepo = CourseRepository(db, _api);
    _subscribe();
    _init();
  }

  /// 訂閱各 Repository 的 Drift stream。訂閱當下即會收到目前 DB 中的快取資料
  /// （離線也能顯示上次結果），之後 refresh 寫入 DB 時會自動再次推送。
  void _subscribe() {
    _gradesSub = _gradesRepo.watchGrades().listen((map) {
      gradesData = map;
      _markCacheLoaded();
      notifyListeners();
    });
    _graduationSub = _graduationRepo.watchGraduation().listen((map) {
      graduationData = map;
      _markCacheLoaded();
      notifyListeners();
    });
    _scheduleSub = _courseRepo.watchSchedule().listen((map) {
      scheduleData = _parseSchedule(map);
      _markCacheLoaded();
      notifyListeners();
    });
  }

  void _markCacheLoaded() {
    if (!_isCacheLoaded) _isCacheLoaded = true;
  }

  List<ScheduleEvent> _parseSchedule(Map<String, dynamic>? map) {
    if (map == null) return [];
    final raw = (map['data']?['schedule'] as List?) ?? const [];
    return raw
        .map((e) => ScheduleEvent.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  void _init() {
    if (_auth.isLoggedIn) {
      prefetchAll();
    }
    _auth.onLoginSuccess = () => prefetchAll();
    _auth.onLogoutCallback = () => clearAll();
  }

  /// 登入後呼叫，預先載入全部資料（逐一執行避免 CookieJar 競爭）。
  Future<void> prefetchAll({bool force = false}) async {
    _isPrefetching = true;
    notifyListeners();
    try {
      await fetchUserInfo();
      await Future.delayed(const Duration(milliseconds: 200));
      await fetchGrades(force: force);
      await Future.delayed(const Duration(milliseconds: 200));
      await fetchGraduation(force: force);
      await fetchSchedule(force: force);
    } finally {
      _isPrefetching = false;
      notifyListeners();
    }
  }

  /// 強制重新抓取（忽略 TTL）。
  Future<void> forceFetchAll() async {
    await prefetchAll(force: true);
  }

  Future<void> fetchUserInfo() async {
    try {
      final response = await _api.getUserInfo();
      if (response['success'] == true) {
        _auth.updateUserInfo(response);
      }
    } catch (e) {
      if (kDebugMode) print('DataProvider: fetchUserInfo error: $e');
    }
  }

  /// 清除所有快取（登出時呼叫）。清空 DB 後 stream 會自動推 null 回來重置欄位。
  Future<void> clearAll() async {
    gradesFailed = false;
    graduationFailed = false;
    scheduleFailed = false;
    _isPrefetching = false;
    notifyListeners();

    await _gradesRepo.clear();
    await _graduationRepo.clear();
    await _courseRepo.clear();
    await CourseDetailCache.clearAll();
    await CalendarCacheService.clearAllCache();
  }

  Future<void> fetchGrades({bool force = false}) async {
    if (isLoadingGrades) return;
    isLoadingGrades = true;
    gradesFailed = false;
    notifyListeners();
    try {
      final ok = await _gradesRepo.refresh(force: force);
      if (!ok && gradesData == null) gradesFailed = true;
    } catch (_) {
      if (gradesData == null) gradesFailed = true;
    } finally {
      isLoadingGrades = false;
      notifyListeners();
    }
  }

  Future<void> fetchGraduation({bool force = false}) async {
    if (isLoadingGraduation) return;
    isLoadingGraduation = true;
    graduationFailed = false;
    notifyListeners();
    try {
      final ok = await _graduationRepo.refresh(force: force);
      if (!ok && graduationData == null) graduationFailed = true;
    } catch (_) {
      if (graduationData == null) graduationFailed = true;
    } finally {
      isLoadingGraduation = false;
      notifyListeners();
    }
  }

  Future<void> fetchSchedule({bool force = false}) async {
    if (isLoadingSchedule) return;
    isLoadingSchedule = true;
    scheduleFailed = false;
    notifyListeners();
    try {
      final ok = await _courseRepo.refresh(force: force);
      if (!ok && scheduleData.isEmpty) scheduleFailed = true;
    } catch (_) {
      if (scheduleData.isEmpty) scheduleFailed = true;
    } finally {
      isLoadingSchedule = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _gradesSub?.cancel();
    _graduationSub?.cancel();
    _scheduleSub?.cancel();
    super.dispose();
  }
}
