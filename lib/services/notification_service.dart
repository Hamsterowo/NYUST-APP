import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../router/app_router.dart';
import 'notification_channel.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Android initialization settings - uses ic_launcher or similar app icon
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        if (details.payload == 'grades') {
          _navigateToGrades();
        }
      },
    );
  }

  /// 請求發送通知的權限
  Future<bool> requestPermissions() async {
    // Android 13+ (SDK 33+) 請求 POST_NOTIFICATIONS 權限
    final androidResolved = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final bool? androidGranted = await androidResolved
        ?.requestNotificationsPermission();

    // iOS 請求權限
    final iosResolved = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final bool? iosGranted = await iosResolved?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return (androidGranted == true) || (iosGranted == true);
  }

  /// 先行建立（或更新）一個 Android channel。
  ///
  /// channel 要等到第一則通知發出後才會出現在系統通知設定裡；使用者剛打開某類
  /// 通知時往往想先去調整音效／重要性，所以啟用當下就把 channel 建起來。
  /// 非 Android 平台為 no-op。
  Future<void> ensureChannel(NotificationChannelSpec channel) async {
    final android = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(channel.toAndroidChannel());
  }

  /// 顯示通知
  ///
  /// [channel] 決定這則通知掛在哪一個系統 channel 底下 —— 使用者可在系統通知
  /// 設定裡分別關閉成績與行事曆兩類通知，互不影響。
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationChannelSpec channel = NotificationChannelSpec.gradeUpdates,
  }) async {
    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: channel.toAndroidDetails(),
      iOS: darwinNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  void _navigateToGrades() {
    // 透過 go_router 導航（背景通知點擊為 App 外部進入點）。
    if (rootNavigatorKey.currentState != null) {
      appRouter.push('/grades');
    }
  }
}
