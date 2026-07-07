import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'background_service.dart';
import 'notification_service.dart';

/// 設定成績通知的結果。
enum GradeNotificationResult {
  /// 已啟用。
  enabled,

  /// 已停用。
  disabled,

  /// 使用者拒絕通知權限，未啟用。
  permissionDenied,
}

/// 成績背景通知（workmanager 週期檢查）的開關邏輯。
///
/// 設定頁與成績頁的就地開關面板共用同一份邏輯，避免兩套 workmanager／
/// 權限／偏好設定各自實作而不同步。
class GradeNotificationService {
  GradeNotificationService._();

  static const String _prefKey = 'grade_notification_enabled';
  static const String _taskUniqueName = '1';

  /// 目前是否已啟用成績通知。
  static Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 啟用／停用成績背景通知。
  ///
  /// 啟用時會先請求通知權限，被拒則回傳 [GradeNotificationResult.permissionDenied]
  /// 且不改變狀態。呼叫端可依回傳值顯示提示。
  static Future<GradeNotificationResult> setEnabled(bool enabled) async {
    if (enabled) {
      final hasPermission = await NotificationService().requestPermissions();
      if (!hasPermission) return GradeNotificationResult.permissionDenied;

      await Workmanager().registerPeriodicTask(
        _taskUniqueName,
        checkGradesTask,
        frequency: const Duration(minutes: 30),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
      if (kDebugMode) {
        await Workmanager().registerOneOffTask(
          'test_oneoff_${DateTime.now().millisecondsSinceEpoch}',
          checkGradesTask,
        );
      }
    } else {
      await Workmanager().cancelByUniqueName(_taskUniqueName);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, enabled);
    } catch (_) {}

    return enabled
        ? GradeNotificationResult.enabled
        : GradeNotificationResult.disabled;
  }
}
