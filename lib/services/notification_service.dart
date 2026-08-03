import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'notification_channel.dart';
import 'notification_navigator.dart';
import 'notification_payload.dart';

/// [DateTime]（當地時間）轉成通知外掛要的 [tz.TZDateTime]。
///
/// 一律掛在 `tz.UTC` 這個 Location 上：外掛把 TZDateTime 換算成 epoch 毫秒再交給
/// AlarmManager／UNCalendarNotificationTrigger，決定觸發時機的是**時刻**而不是
/// 牆上時間，而 Dart 的 [DateTime] 已經用作業系統真正的時區規則（含日光節約）
/// 算好了那個時刻。因此不需要 `initializeTimeZones()` 載入整份時區資料庫，也
/// 不需要額外的裝置時區外掛去查 IANA 時區名稱。
tz.TZDateTime toScheduleTime(DateTime localTime) =>
    tz.TZDateTime.from(localTime, tz.UTC);

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
        final payload = NotificationPayload.decode(details.payload);
        if (payload != null) NotificationNavigator.submit(payload);
      },
    );
  }

  /// App 是被點通知啟動的嗎？是的話把目的地交給 [NotificationNavigator]。
  ///
  /// [init] 註冊的點擊 callback **不會**為「啟動 App 的那一則通知」觸發（外掛
  /// 文件明說了），冷啟動只能在這裡主動問啟動來源。少了這一步，App 完全關閉時
  /// 點通知就只會開啟 App、停在首頁。
  Future<void> handleAppLaunchNotification() async {
    try {
      final details = await _flutterLocalNotificationsPlugin
          .getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp != true) return;

      final payload = NotificationPayload.decode(
        details!.notificationResponse?.payload,
      );
      if (payload != null) NotificationNavigator.submit(payload);
    } catch (_) {
      // 取不到啟動來源就當成一般啟動，不影響 App 開啟。
    }
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

  /// 目前是否被允許發通知。**不會**跳出授權視窗，純查詢。
  ///
  /// 與 [requestPermissions] 的差別在於這個可以隨時呼叫 —— 例如每次進前景時
  /// 確認使用者有沒有中途去系統設定把通知關掉或打開。
  Future<bool> areNotificationsEnabled() async {
    final android = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }

    final ios = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final options = await ios?.checkPermissions();
    return options?.isEnabled ?? false;
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

  /// 排定一則在 [scheduledDate]（當地時間）發出的通知。
  ///
  /// Android 使用**非精確**鬧鐘：這是提前一天的提醒不是鬧鐘，20 分鐘誤差沒有
  /// 意義，不值得換一個使用者八成不會完成的 `SCHEDULE_EXACT_ALARM` 授權跳轉，
  /// 或 `USE_EXACT_ALARM` 帶來的 Google Play 送審風險。`allowWhileIdle` 讓它在
  /// 手機整夜閒置進入 Doze 時仍會發出 —— 早上八點的提醒正是這個情境。
  Future<void> zonedSchedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required NotificationChannelSpec channel,
    String? payload,
    StyleInformation? styleInformation,
    String? subText,
    String? iosSubtitle,
  }) async {
    final DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
          subtitle: iosSubtitle,
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: channel.toAndroidDetails(
        styleInformation: styleInformation,
        subText: subText,
      ),
      iOS: darwinNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: toScheduleTime(scheduledDate),
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  /// 取消一則已排定（或已顯示）的通知。
  Future<void> cancel(int id) =>
      _flutterLocalNotificationsPlugin.cancel(id: id);

  /// 目前還沒發出的排程，供除錯與驗證使用。
  Future<List<PendingNotificationRequest>> pendingRequests() =>
      _flutterLocalNotificationsPlugin.pendingNotificationRequests();
}
