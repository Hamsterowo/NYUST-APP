import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database/database.dart';
import '../repositories/grades_repository.dart';
import '../repositories/graduation_repository.dart';
import '../repositories/course_repository.dart';
import '../repositories/refresh_outcome.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
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
  StreamSubscription<bool>? _connSub;

  /// 追蹤上一個已知的連線狀態,只在「離線→上線」的瞬間觸發重抓。
  bool _wasOnline = true;

  bool _isCacheLoaded = false;
  bool get isCacheLoaded => _isCacheLoaded;

  Map<String, dynamic>? gradesData;
  bool isLoadingGrades = false;
  bool gradesFailed = false;

  /// 最近一次成績抓取失敗的原因（networkError/serviceError），供 UI 顯示
  /// 「無法連線至成績系統」或通用載入失敗。成功或未失敗時為 null。
  RefreshOutcome? gradesFailReason;

  Map<String, dynamic>? graduationData;
  bool isLoadingGraduation = false;
  bool graduationFailed = false;
  RefreshOutcome? graduationFailReason;

  List<ScheduleEvent> scheduleData = [];
  bool isLoadingSchedule = false;
  bool scheduleFailed = false;
  RefreshOutcome? scheduleFailReason;

  // ── 多學期課表 ──────────────────────────────────────────────
  /// 可切換的學期選項（[{value,label}]），線上抓到才有值。
  List<Map<String, String>> scheduleSemesters = [];

  /// 學校目前的當前學期代碼（例：1142）。
  String? currentSemester;

  /// 使用者正在查看的學期代碼（null 或等於 [currentSemester] 時看當前學期）。
  String? selectedSemester;

  /// 切換到非當前學期時的載入狀態。
  bool isLoadingScheduleSemester = false;

  /// 最近一次「切換到其他學期」的抓取是否失敗（且無快取可顯示）。
  /// 供課表畫面顯示失敗提示與重試,而非默默顯示空白/錯誤學期的資料。
  bool semesterLoadFailed = false;
  RefreshOutcome? semesterLoadFailReason;

  /// 非當前學期的課表快取（僅記憶體，歷史資料可重抓）。
  final Map<String, List<ScheduleEvent>> _semesterCache = {};

  bool _loadingSemesterList = false;

  /// 目前應顯示的課表：當前學期直接讀 Drift 快取的 [scheduleData]，
  /// 其他學期讀記憶體快取。
  List<ScheduleEvent> get displayedSchedule {
    final sel = selectedSemester;
    if (sel == null || sel == currentSemester) return scheduleData;
    return _semesterCache[sel] ?? scheduleData;
  }

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
    _hydrateSemesterCache();
    if (_auth.isLoggedIn) {
      prefetchAll();
    }
    _auth.onLoginSuccess = () => prefetchAll();
    _auth.onLogoutCallback = () => clearAll();
    _watchConnectivity();
  }

  /// 啟動時從 Drift 還原「其他學期」課表到記憶體快取，
  /// 使歷史學期在網路預抓完成前、甚至離線時也能立即切換顯示。
  Future<void> _hydrateSemesterCache() async {
    try {
      final cached = await _courseRepo.loadCachedSemesters();
      if (cached.isEmpty) return;
      cached.forEach((key, rawList) {
        _semesterCache[key] = _parseSchedule({
          'data': {'schedule': rawList},
        });
      });
      notifyListeners();
    } catch (_) {
      // 還原失敗不影響當前學期顯示。
    }
  }

  /// 從課表回應取出原始課程陣列（供持久化）。
  List<dynamic> _rawSchedule(Map<String, dynamic> resp) =>
      (resp['data']?['schedule'] as List?) ?? const [];

  /// 監聽連線狀態:從「離線」恢復到「上線」時,若已登入就重新抓取一次。
  /// 這也會順帶重新驗證 session(prefetchAll → fetchUserInfo),
  /// 若期間 session 真的過期,會在此時被登出。
  void _watchConnectivity() {
    _connSub = ConnectivityService.instance.onStatusChange.listen((online) {
      final cameBackOnline = online && !_wasOnline;
      _wasOnline = online;
      if (cameBackOnline && _auth.isLoggedIn && !_isPrefetching) {
        prefetchAll();
      }
    });
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
      await _prefetchOtherSemesters(force: force);
    } finally {
      _isPrefetching = false;
      notifyListeners();
    }
  }

  /// 預先載入「其他學期」的課表（當前學期已由 [fetchSchedule] 抓好），
  /// 讓使用者切換學期時無需等待。逐一抓取並加小延遲，避免 CookieJar 競爭；
  /// 任一學期失敗都不影響其他（切換時仍可按需重抓）。
  Future<void> _prefetchOtherSemesters({bool force = false}) async {
    // 先確保已知道學期清單（cache-hit 時 fetchSchedule 不會帶回清單）。
    if (scheduleSemesters.isEmpty) {
      await ensureScheduleSemesters();
    }
    for (final s in scheduleSemesters) {
      final value = s['value'] ?? '';
      if (value.isEmpty || value == currentSemester) continue;
      if (!force && _semesterCache.containsKey(value)) continue;
      try {
        await Future.delayed(const Duration(milliseconds: 200));
        final resp = await _api.getSchedule(semester: value);
        if (resp['status'] == 'success') {
          final respMap = Map<String, dynamic>.from(resp);
          _semesterCache[value] = _parseSchedule(respMap);
          await _courseRepo.saveCachedSemester(value, _rawSchedule(respMap));
        }
      } catch (_) {
        // 略過此學期，使用者實際切換時會再按需抓一次。
      }
    }
    notifyListeners();
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
      } else if (response['status'] == 'session_expired') {
        // 線上但伺服器確認未登入 → session 過期,主動登出。
        // (離線會回 network_error,不會走到這裡,快取與登入狀態得以保留。)
        await _auth.handleSessionExpired();
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
    gradesFailReason = null;
    graduationFailReason = null;
    scheduleFailReason = null;
    scheduleSemesters = [];
    currentSemester = null;
    selectedSemester = null;
    _semesterCache.clear();
    isLoadingScheduleSemester = false;
    semesterLoadFailed = false;
    semesterLoadFailReason = null;
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
    gradesFailReason = null;
    notifyListeners();
    try {
      final outcome = await _gradesRepo.refresh(force: force);
      if (!outcome.isSuccess && gradesData == null) {
        gradesFailed = true;
        gradesFailReason = outcome;
      }
    } catch (_) {
      if (gradesData == null) {
        gradesFailed = true;
        gradesFailReason = RefreshOutcome.serviceError;
      }
    } finally {
      isLoadingGrades = false;
      notifyListeners();
    }
  }

  Future<void> fetchGraduation({bool force = false}) async {
    if (isLoadingGraduation) return;
    isLoadingGraduation = true;
    graduationFailed = false;
    graduationFailReason = null;
    notifyListeners();
    try {
      final outcome = await _graduationRepo.refresh(force: force);
      if (!outcome.isSuccess && graduationData == null) {
        graduationFailed = true;
        graduationFailReason = outcome;
      }
    } catch (_) {
      if (graduationData == null) {
        graduationFailed = true;
        graduationFailReason = RefreshOutcome.serviceError;
      }
    } finally {
      isLoadingGraduation = false;
      notifyListeners();
    }
  }

  Future<void> fetchSchedule({bool force = false}) async {
    if (isLoadingSchedule) return;
    isLoadingSchedule = true;
    scheduleFailed = false;
    scheduleFailReason = null;
    notifyListeners();
    try {
      final outcome = await _courseRepo.refresh(force: force);
      if (!outcome.isSuccess && scheduleData.isEmpty) {
        scheduleFailed = true;
        scheduleFailReason = outcome;
      }
      _captureSemesterMeta();
    } catch (_) {
      if (scheduleData.isEmpty) {
        scheduleFailed = true;
        scheduleFailReason = RefreshOutcome.serviceError;
      }
    } finally {
      isLoadingSchedule = false;
      notifyListeners();
    }
  }

  /// 從 repository 擷取學期清單（僅在剛完成一次線上抓取時有值）。
  void _captureSemesterMeta() {
    if (_courseRepo.semesters.isNotEmpty) {
      scheduleSemesters = _courseRepo.semesters;
    }
    if (_courseRepo.currentSemester.isNotEmpty) {
      currentSemester = _courseRepo.currentSemester;
      selectedSemester ??= currentSemester;
    }
  }

  /// 課表畫面開啟時呼叫：若尚不知道學期清單且在線上，補抓一次以填入切換器。
  Future<void> ensureScheduleSemesters() async {
    if (scheduleSemesters.isNotEmpty || _loadingSemesterList) return;
    if (!await ConnectivityService.instance.checkOnline()) return;
    _loadingSemesterList = true;
    try {
      final resp = await _api.getSchedule();
      if (resp['status'] == 'success') {
        final data = resp['data'] as Map?;
        final raw = (data?['semesters'] as List?) ?? const [];
        scheduleSemesters = raw
            .map(
              (e) => (e as Map).map(
                (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
              ),
            )
            .toList();
        currentSemester = (data?['currentSemester'] ?? '').toString();
        selectedSemester ??= currentSemester;
        notifyListeners();
      }
    } catch (_) {
      // 靜默失敗：切換器沒出現而已，不影響當前學期課表顯示。
    } finally {
      _loadingSemesterList = false;
    }
  }

  /// 是否已有指定學期的記憶體快取。
  bool hasSemesterCache(String? value) =>
      value != null && _semesterCache.containsKey(value);

  /// 切換到指定學期。當前學期直接切換；其他學期若未快取則按需抓取。
  /// 已選中但上次抓取失敗時,再次呼叫視為「重試」。
  Future<void> selectSemester(String value) async {
    if (value == selectedSemester && !semesterLoadFailed) return;
    selectedSemester = value;
    semesterLoadFailed = false;
    semesterLoadFailReason = null;

    if (value == currentSemester || _semesterCache.containsKey(value)) {
      notifyListeners();
      return;
    }

    isLoadingScheduleSemester = true;
    notifyListeners();
    try {
      final resp = await _api.getSchedule(semester: value);
      if (resp['status'] == 'success') {
        final respMap = Map<String, dynamic>.from(resp);
        _semesterCache[value] = _parseSchedule(respMap);
        await _courseRepo.saveCachedSemester(value, _rawSchedule(respMap));
      } else if (selectedSemester == value) {
        // 記錄失敗讓 UI 顯示提示與重試（使用者已切走則不覆蓋）。
        semesterLoadFailed = true;
        semesterLoadFailReason = classifyRefreshFailure(resp);
      }
    } catch (_) {
      if (selectedSemester == value) {
        semesterLoadFailed = true;
        semesterLoadFailReason = RefreshOutcome.serviceError;
      }
    } finally {
      isLoadingScheduleSemester = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _gradesSub?.cancel();
    _graduationSub?.cancel();
    _scheduleSub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }
}
