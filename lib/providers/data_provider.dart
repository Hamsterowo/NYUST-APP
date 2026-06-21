import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/course_detail_cache.dart';
import '../services/calendar_cache_service.dart';
import '../models/schedule_event.dart';
import 'auth_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

/// 集中管理所有已載入的 App 資料，避免切換頁面時重複呼叫 API。
/// 在使用者登入後自動預先載入所有資料。
class DataProvider with ChangeNotifier {
  final ApiService _api;
  final AuthProvider _auth;

  Future<void>? _cacheLoadingFuture;

  final _secureStorage = const FlutterSecureStorage();

  Future<String?> _loadDataCache(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> _saveDataCache(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<void> _clearDataCaches() async {
    await _secureStorage.delete(key: 'cache_grades');
    await _secureStorage.delete(key: 'cache_graduation');
    await _secureStorage.delete(key: 'cache_schedule');
  }

  DataProvider(this._api, this._auth) {
    _cacheLoadingFuture = _loadCache();
    _init();
  }

  void _init() {

    if (_auth.isLoggedIn) {
      prefetchAll();
    }

    _auth.onLoginSuccess = () => prefetchAll();

    _auth.onLogoutCallback = () => clearAll();
  }

  Future<void> _loadCache() async {
    try {
      // Load grades cache
      final cachedGrades = await _loadDataCache('cache_grades');
      if (cachedGrades != null && gradesData == null) {
        final map = jsonDecode(cachedGrades) as Map;
        final newMap = <String, dynamic>{};
        map.forEach((key, value) {
          newMap[key.toString()] = value;
        });
        gradesData = newMap;
      }

      // Load graduation cache
      final cachedGraduation = await _loadDataCache('cache_graduation');
      if (cachedGraduation != null && graduationData == null) {
        final map = jsonDecode(cachedGraduation) as Map;
        final newMap = <String, dynamic>{};
        map.forEach((key, value) {
          newMap[key.toString()] = value;
        });
        graduationData = newMap;
      }

      // Load schedule cache
      final cachedSchedule = await _loadDataCache('cache_schedule');
      if (cachedSchedule != null && scheduleData.isEmpty) {
        final List<dynamic> raw = jsonDecode(cachedSchedule);
        scheduleData = raw.map((e) {
          final map = e as Map;
          final newMap = <String, dynamic>{};
          map.forEach((key, value) {
            newMap[key.toString()] = value;
          });
          return ScheduleEvent.fromJson(newMap);
        }).toList();
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('DataProvider: _loadCache error: $e');
    }
  }

  Map<String, dynamic>? gradesData;
  bool isLoadingGrades = false;
  bool gradesFailed = false;

  Map<String, dynamic>? graduationData;
  bool isLoadingGraduation = false;
  bool graduationFailed = false;

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
    gradesData = null;
    graduationData = null;
    scheduleData = [];

    await _clearDataCaches();
    await prefetchAll();
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

  /// 清除所有快取（登出時呼叫）
  Future<void> clearAll() async {
    gradesData = null;
    graduationData = null;
    scheduleData = [];
    gradesFailed = false;
    graduationFailed = false;
    scheduleFailed = false;

    await CourseDetailCache.clearAll();
    await CalendarCacheService.clearAllCache();
    notifyListeners();

    await _clearDataCaches();
  }

  Future<void> fetchGrades() async {
    if (isLoadingGrades) return;

    if (_cacheLoadingFuture != null) await _cacheLoadingFuture;

    if (gradesData == null) {
      final cached = await _loadDataCache('cache_grades');
      if (cached != null) {
        try {
          final map = jsonDecode(cached) as Map;
          final newMap = <String, dynamic>{};
          map.forEach((key, value) {
            newMap[key.toString()] = value;
          });
          gradesData = newMap;
          gradesFailed = false;
          notifyListeners();
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
        await _saveDataCache('cache_grades', jsonEncode(response));
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

  Future<void> fetchGraduation() async {
    if (isLoadingGraduation) return;

    if (_cacheLoadingFuture != null) await _cacheLoadingFuture;

    if (graduationData == null) {
      final cached = await _loadDataCache('cache_graduation');
      if (cached != null) {
        try {
          final map = jsonDecode(cached) as Map;
          final newMap = <String, dynamic>{};
          map.forEach((key, value) {
            newMap[key.toString()] = value;
          });
          graduationData = newMap;
          graduationFailed = false;
          notifyListeners();
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
        await _saveDataCache('cache_graduation', jsonEncode(response));
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

  Future<void> fetchSchedule() async {
    if (isLoadingSchedule) return;

    if (_cacheLoadingFuture != null) await _cacheLoadingFuture;

    if (scheduleData.isEmpty) {
      final cached = await _loadDataCache('cache_schedule');
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
          notifyListeners();
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
        await _saveDataCache('cache_schedule', jsonEncode(raw));
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
