import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/schedule_event.dart';
import 'auth_provider.dart';

/// 集中管理所有已載入的 App 資料，避免切換頁面時重複呼叫 API。
/// 在使用者登入後自動預先載入所有資料。
class DataProvider with ChangeNotifier {
  final ApiService _api;

  DataProvider(this._api, AuthProvider authProvider) {
    // App 啟動時若已有登入的 Session，立即預先載入
    if (authProvider.isLoggedIn) {
      prefetchAll();
    }
    // 新登入時自動預先載入
    authProvider.onLoginSuccess = () => prefetchAll();
    // 登出時清除所有快取
    authProvider.onLogoutCallback = () => clearAll();
  }

  // ─── 成績 ───────────────────────────────────────────────────────
  Map<String, dynamic>? gradesData;
  bool isLoadingGrades = false;
  bool gradesFailed = false;

  // ─── 畢業學分 ─────────────────────────────────────────────────────
  Map<String, dynamic>? graduationData;
  bool isLoadingGraduation = false;
  bool graduationFailed = false;

  // ─── 課表 ─────────────────────────────────────────────────────────
  List<ScheduleEvent> scheduleData = [];
  bool isLoadingSchedule = false;
  bool scheduleFailed = false;

  /// 登入後呼叫，預先載入全部資料（逐一執行避免 CookieJar 競爭）
  Future<void> prefetchAll() async {
    await fetchGrades();
    await Future.delayed(const Duration(milliseconds: 200));
    await fetchGraduation();
    await fetchSchedule();
  }

  /// 清除所有快取（登出時呼叫）
  void clearAll() {
    gradesData = null;
    graduationData = null;
    scheduleData = [];
    gradesFailed = false;
    graduationFailed = false;
    scheduleFailed = false;
    notifyListeners();
  }

  // ─── 成績載入 ─────────────────────────────────────────────────────
  Future<void> fetchGrades() async {
    if (isLoadingGrades) return;
    isLoadingGrades = true;
    gradesFailed = false;
    notifyListeners();

    try {
      final response = await _api.getGrades();
      if (response['success'] == true) {
        gradesData = response;
        gradesFailed = false;
      } else {
        gradesFailed = true;
      }
    } catch (_) {
      gradesFailed = true;
    } finally {
      isLoadingGrades = false;
      notifyListeners();
    }
  }

  // ─── 畢業學分載入 ─────────────────────────────────────────────────
  Future<void> fetchGraduation() async {
    if (isLoadingGraduation) return;
    isLoadingGraduation = true;
    graduationFailed = false;
    notifyListeners();

    try {
      final response = await _api.getGraduation();
      if (response['success'] == true) {
        graduationData = response;
        graduationFailed = false;
      } else {
        graduationFailed = true;
      }
    } catch (_) {
      graduationFailed = true;
    } finally {
      isLoadingGraduation = false;
      notifyListeners();
    }
  }

  // ─── 課表載入 ─────────────────────────────────────────────────────
  Future<void> fetchSchedule() async {
    if (isLoadingSchedule) return;
    isLoadingSchedule = true;
    scheduleFailed = false;
    notifyListeners();

    try {
      final response = await _api.getSchedule();
      if (response['status'] == 'success' && response['data'] != null) {
        final List<dynamic> raw = response['data']['schedule'] ?? [];
        scheduleData = raw.map((e) => ScheduleEvent.fromJson(e)).toList();
        scheduleFailed = false;
      } else {
        scheduleFailed = true;
      }
    } catch (_) {
      scheduleFailed = true;
    } finally {
      isLoadingSchedule = false;
      notifyListeners();
    }
  }
}
