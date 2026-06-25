import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:workmanager/workmanager.dart';
import 'api_service.dart';
import 'notification_service.dart';
import '../utils/grades_comparator.dart';

const String checkGradesTask = "tw.hamster.nyustplus.checkGradesTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    // 確保 Flutter 插件管道能在背景正確初始化
    WidgetsFlutterBinding.ensureInitialized();

    if (taskName == checkGradesTask) {
      try {
        if (kDebugMode) print('BackgroundService: Started grades checking task...');
        
        final apiService = ApiService();
        await apiService.init();

        // 檢查是否有儲存的 cookies
        final hasCookies = await apiService.hasSavedCookies();
        if (!hasCookies) {
          if (kDebugMode) print('BackgroundService: No saved cookies. Exiting.');
          return true;
        }

        // 除錯模式下，發送通知以證明背景任務成功啟動並正常運作
        if (kDebugMode) {
          final notificationService = NotificationService();
          await notificationService.init();
          final nowStr = DateTime.now().toLocal().toString().split('.').first;
          await notificationService.showNotification(
            id: DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
            title: '背景檢查執行中 (Debug Mode)',
            body: '最後檢查時間：$nowStr',
            payload: 'grades',
          );
        }

        // 呼叫 api 取得成績
        final result = await apiService.getGrades();

        // 如果 Session 逾期，或者抓取失敗
        if (result['success'] != true) {
          final isExpired = result['isExpired'] == true || 
                            result['message']?.toString().contains('Session expired') == true;
          if (isExpired) {
            // 登入已過期：根據使用者最新要求，靜默處理，不發通知直接結束
            if (kDebugMode) print('BackgroundService: Session expired. Exiting silently.');
            return true;
          }
          if (kDebugMode) print('BackgroundService: Failed to fetch grades: ${result['message']}');
          return false; // 回傳 false 使 Workmanager 依原則重試
        }

        // 抓取成功，比對新舊成績
        const secureStorage = FlutterSecureStorage();
        final cachedGradesStr = await secureStorage.read(key: 'cache_grades');
        
        if (cachedGradesStr != null) {
          final Map<String, dynamic> oldData = jsonDecode(cachedGradesStr);
          
          // 取得系統當前語系，由於是在 Isolate 中，我們可以用 Platform.localeName 來判斷
          final String locale = Platform.localeName;
          final bool isEnglish = locale.toLowerCase().startsWith('en');

          final changes = GradesComparator.compare(oldData, result, isEnglish: isEnglish);

          if (changes.isNotEmpty) {
            if (kDebugMode) print('BackgroundService: Found ${changes.length} changes. Sending notification.');
            final notificationService = NotificationService();
            await notificationService.init();

            final String title = isEnglish ? 'Grade Update Notification' : '成績更新通知';
            final String body = changes.join('\n');

            await notificationService.showNotification(
              id: DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
              title: title,
              body: body,
              payload: 'grades',
            );

            // 更新本地快取成績資料，確保下次不會重複發送相同通知
            await secureStorage.write(key: 'cache_grades', value: jsonEncode(result));
          } else {
            if (kDebugMode) print('BackgroundService: No grades changes found.');
          }
        } else {
          // 如果原本就沒有快取（例如使用者剛登入但尚未建立快取），先將當前結果存入
          if (kDebugMode) print('BackgroundService: No initial cache found, saving current grades.');
          await secureStorage.write(key: 'cache_grades', value: jsonEncode(result));
        }
      } catch (e) {
        if (kDebugMode) print('BackgroundService error: $e');
        return false;
      }
    }
    return true;
  });
}
