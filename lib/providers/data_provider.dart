import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database/database.dart';
import '../repositories/grades_repository.dart';
import '../repositories/graduation_repository.dart';
import '../repositories/course_repository.dart';
import '../repositories/refresh_outcome.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/academic_cache.dart';
import '../models/grade_report.dart';
import '../models/graduation_report.dart';
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

  StreamSubscription<GradeReport?>? _gradesSub;
  StreamSubscription<GraduationReport?>? _graduationSub;
  StreamSubscription<List<ScheduleEvent>>? _scheduleSub;
  StreamSubscription<bool>? _connSub;

  /// 追蹤上一個已知的連線狀態,只在「離線→上線」的瞬間觸發重抓。
  bool _wasOnline = true;

  bool _isCacheLoaded = false;
  bool get isCacheLoaded => _isCacheLoaded;

  GradeReport? gradesData;
  bool isLoadingGrades = false;
  bool gradesFailed = false;

  /// 最近一次成績抓取失敗的原因（networkError/serviceError），供 UI 顯示
  /// 「無法連線至成績系統」或通用載入失敗。成功或未失敗時為 null。
  RefreshOutcome? gradesFailReason;

  GraduationReport? graduationData;
  bool isLoadingGraduation = false;
  bool graduationFailed = false;
  RefreshOutcome? graduationFailReason;

  List<ScheduleEvent> scheduleData = [];
  bool isLoadingSchedule = false;
  bool scheduleFailed = false;
  RefreshOutcome? scheduleFailReason;

  // ── 多學期課表 ──────────────────────────────────────────────
  /// 可切換的學期選項，線上抓到才有值。
  List<SemesterOption> scheduleSemesters = [];

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
    _gradesSub = _gradesRepo.watchGrades().listen((report) {
      gradesData = report;
      _markCacheLoaded();
      notifyListeners();
    });
    _graduationSub = _graduationRepo.watchGraduation().listen((report) {
      graduationData = report;
      _markCacheLoaded();
      notifyListeners();
    });
    _scheduleSub = _courseRepo.watchSchedule().listen((courses) {
      scheduleData = courses;
      _markCacheLoaded();
      notifyListeners();
    });
  }

  void _markCacheLoaded() {
    if (!_isCacheLoaded) _isCacheLoaded = true;
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
      // 學期清單：離線／TTL 命中時不會有網路抓取，只能靠這份還原，
      // 否則切換器不會出現，其他學期的課即使有快取也到不了。
      final meta = await _courseRepo.loadSemesterList();
      if (meta != null && meta.semesters.isNotEmpty) {
        if (scheduleSemesters.isEmpty) scheduleSemesters = meta.semesters;
        if (currentSemester == null && meta.currentSemester.isNotEmpty) {
          currentSemester = meta.currentSemester;
          selectedSemester ??= currentSemester;
        }
      }

      // 這支與 prefetchAll 併行執行：只補上還沒有的學期，
      // 避免比較舊的快取蓋掉剛抓回來的資料。
      final cached = await _courseRepo.loadCachedSemesters();
      for (final entry in cached.entries) {
        _semesterCache.putIfAbsent(entry.key, () => entry.value);
      }

      notifyListeners();
    } catch (_) {
      // 還原失敗不影響當前學期顯示。
    }
  }

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
  ///
  /// 這裡是「課表快取要備齊」的**唯一保證**：課表畫面切到該分頁時也會補抓一次
  /// 學期清單，但那只是加速，使用者從未點進課表頁時整份快取仍必須完整。
  Future<void> _prefetchOtherSemesters({bool force = false}) async {
    // 先確保已知道學期清單（cache-hit 時 fetchSchedule 不會帶回清單）。
    if (scheduleSemesters.isEmpty) {
      await ensureScheduleSemesters();
    }
    for (final s in scheduleSemesters) {
      final value = s.value;
      if (value.isEmpty || value == currentSemester) continue;
      if (!force && _semesterCache.containsKey(value)) continue;
      try {
        await Future.delayed(const Duration(milliseconds: 200));
        final result = await _api.getSchedule(semester: value);
        if (result.isSuccess) {
          final courses = result.data!.courses;
          _semesterCache[value] = courses;
          await _courseRepo.saveCachedSemester(value, courses);
        } else if (kDebugMode) {
          print('DataProvider: prefetch of semester $value → ${result.status}');
        }
      } catch (e) {
        // 略過此學期，使用者實際切換時會再按需抓一次。
        // 但不再完全靜默 —— 這類失敗曾讓「其他學期沒被快取」查不出原因。
        if (kDebugMode) print('DataProvider: prefetch of semester $value: $e');
      }
    }

    // 預抓結束時一律把清單寫回快取。清單可能來自這次的網路抓取、也可能是啟動時
    // 從快取還原的；後者若因故沒有落地（例如上一版還沒有這份持久化），這裡會補上，
    // 使「離線也看得到學期切換器」不必等使用者點進課表頁。
    _persistSemesterList();

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

    // 實際的資料清除交給 [AcademicCache]（不依賴任何 provider，登出時
    // AuthProvider 也會直接呼叫）。這裡只負責重置自己的記憶體狀態。
    await AcademicCache.clearAll();
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
      final result = await _courseRepo.refresh(force: force);
      if (!result.outcome.isSuccess && scheduleData.isEmpty) {
        scheduleFailed = true;
        scheduleFailReason = result.outcome;
      }
      _captureSemesterMeta(result.snapshot);
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

  /// 擷取學期清單。[snapshot] 只在剛完成一次線上抓取時非 null
  /// （TTL 命中快取時為 null，維持既有的學期清單不變）。
  void _captureSemesterMeta(ScheduleSnapshot? snapshot) {
    if (snapshot == null) return;
    if (snapshot.semesters.isNotEmpty) {
      scheduleSemesters = snapshot.semesters;
    }
    if (snapshot.currentSemester.isNotEmpty) {
      currentSemester = snapshot.currentSemester;
      selectedSemester ??= currentSemester;
    }
    _persistSemesterList();
  }

  /// 把學期清單存進快取，供離線／TTL 命中時的冷啟動還原（失敗不影響顯示）。
  void _persistSemesterList() {
    if (scheduleSemesters.isEmpty) return;
    _courseRepo
        .saveSemesterList(scheduleSemesters, currentSemester ?? '')
        .catchError((Object e) {
          if (kDebugMode)
            print('DataProvider: saving semester list failed: $e');
        });
  }

  /// 若尚不知道學期清單就補抓一次，以填入切換器。
  /// 由預抓流程與「切到課表分頁」兩處呼叫。
  ///
  /// 這裡刻意**不**先問連線狀態：啟動當下 connectivity 往往還沒解析完，
  /// 會回報離線而讓這唯一一次補抓被跳過，於是學期清單只剩「使用者點進課表頁」
  /// 才會取得。連線旗標只反映網路介面、不代表真的連得到，依專案慣例只能當
  /// UX 最佳化用；真正的判斷交給請求結果本身 —— 離線時請求會立刻失敗並被
  /// 下面的 catch 靜默吃掉，成本極低。
  Future<void> ensureScheduleSemesters() async {
    if (scheduleSemesters.isNotEmpty || _loadingSemesterList) return;
    _loadingSemesterList = true;
    try {
      final result = await _api.getSchedule();
      if (result.isSuccess) {
        final snapshot = result.data!;
        scheduleSemesters = snapshot.semesters;
        currentSemester = snapshot.currentSemester;
        selectedSemester ??= currentSemester;
        _persistSemesterList();
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
      final result = await _api.getSchedule(semester: value);
      if (result.isSuccess) {
        final courses = result.data!.courses;
        _semesterCache[value] = courses;
        await _courseRepo.saveCachedSemester(value, courses);
      } else if (selectedSemester == value) {
        // 記錄失敗讓 UI 顯示提示與重試（使用者已切走則不覆蓋）。
        semesterLoadFailed = true;
        semesterLoadFailReason = result.status;
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
