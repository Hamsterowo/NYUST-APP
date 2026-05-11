import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/course_detail_cache.dart';
import '../services/calendar_cache_service.dart';
import '../models/schedule_event.dart';
import 'auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 集中管理所有已載入的 App 資料，避免切換頁面時重複呼叫 API。
/// 在使用者登入後自動預先載入所有資料。
class DataProvider with ChangeNotifier {
  final ApiService _api;
  final AuthProvider _auth;

  DataProvider(this._api, this._auth) {
    _init();
  }

  void _init() {
    // App 啟動時若已有登入的 Session，立即預先載入
    if (_auth.isLoggedIn) {
      prefetchAll();
    }
    // 新登入時自動預先載入
    _auth.onLoginSuccess = () => prefetchAll();
    // 登出時清除所有快取
    _auth.onLogoutCallback = () => clearAll();
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
    await fetchUserInfo();
    await Future.delayed(const Duration(milliseconds: 200));
    await fetchGrades();
    await Future.delayed(const Duration(milliseconds: 200));
    await fetchGraduation();
    await fetchSchedule();
  }

  /// 強制重新抓取（不使用快取）
  Future<void> forceFetchAll() async {
    // 清除記憶體快取
    gradesData = null;
    graduationData = null;
    scheduleData = [];
    
    // 清除本地存儲快取
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cache_grades');
    await prefs.remove('cache_graduation');
    await prefs.remove('cache_schedule');
    
    await prefetchAll();
  }

  // ─── 個人資料 ─────────────────────────────────────────────────────
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

  /// 清除所有快取（登出時呼叫）
  Future<void> clearAll() async {
    gradesData = null;
    graduationData = null;
    scheduleData = [];
    gradesFailed = false;
    graduationFailed = false;
    scheduleFailed = false;
    // 清除課程詳細與行事曆的本地快取
    await CourseDetailCache.clearAll();
    await CalendarCacheService.clearAllCache();
    notifyListeners();

    // 清空本地存儲
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cache_grades');
    await prefs.remove('cache_graduation');
    await prefs.remove('cache_schedule');
  }

  // ─── 成績載入 ─────────────────────────────────────────────────────
  Future<void> fetchGrades() async {
    if (isLoadingGrades) return;

    // 1. 嘗試載入本地快取
    if (gradesData == null) {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cache_grades');
      if (cached != null) {
        try {
          final map = jsonDecode(cached) as Map;
          final newMap = <String, dynamic>{};
          map.forEach((key, value) {
            newMap[key.toString()] = value;
          });
          gradesData = newMap;
          gradesFailed = false;
          notifyListeners(); // 優先顯示快取畫面
        } catch (e) {
          if (kDebugMode) print('Parse grades cache error: $e');
        }
      }
    }

    isLoadingGrades = true;
    gradesFailed = false;
    notifyListeners();

    try {
      final response = await _api.getGrades();
      if (response['success'] == true) {
        gradesData = response;
        gradesFailed = false;
        // 2. 儲存最新快取
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cache_grades', jsonEncode(response));
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

    // 1. 嘗試載入本地快取
    if (graduationData == null) {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cache_graduation');
      if (cached != null) {
        try {
          final map = jsonDecode(cached) as Map;
          final newMap = <String, dynamic>{};
          map.forEach((key, value) {
            newMap[key.toString()] = value;
          });
          graduationData = newMap;
          graduationFailed = false;
          notifyListeners(); // 優先顯示快取畫面
        } catch (e) {
          if (kDebugMode) print('Parse graduation cache error: $e');
        }
      }
    }

    isLoadingGraduation = true;
    graduationFailed = false;
    notifyListeners();

    try {
      final response = await _api.getGraduation();
      if (response['success'] == true) {
        graduationData = response;
        graduationFailed = false;
        // 2. 儲存最新快取
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cache_graduation', jsonEncode(response));
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

    // 1. 嘗試載入本地快取
    if (scheduleData.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cache_schedule');
      if (cached != null) {
        try {
          final List<dynamic> raw = jsonDecode(cached);
          scheduleData = raw.map((e) {
            final map = e as Map;
            final newMap = <String, dynamic>{};
            map.forEach((key, value) {
              newMap[key.toString()] = value;
            });
            return ScheduleEvent.fromJson(newMap);
          }).toList();
          scheduleFailed = false;
          notifyListeners(); // 優先顯示快取畫面
        } catch (e) {
          if (kDebugMode) print('Parse schedule cache error: $e');
        }
      }
    }

    isLoadingSchedule = true;
    scheduleFailed = false;
    notifyListeners();

    try {
      final response = await _api.getSchedule();
      if (response['status'] == 'success' && response['data'] != null) {
        final List<dynamic> raw = response['data']['schedule'] ?? [];
        scheduleData = raw
            .map(
              (e) =>
                  ScheduleEvent.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
        scheduleFailed = false;
        // 2. 儲存最新快取
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cache_schedule', jsonEncode(raw));
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
