import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../l10n/app_localizations.dart';

/// 一組 Android 通知 channel 的識別與顯示資訊。
///
/// Android 把每個 channel 在系統通知設定裡分別列出、各自可獨立開關，所以性質
/// 不同的通知（成績更新／行事曆提醒）必須各自帶一組 id 與名稱。過去發送通知時
/// 這三個值是寫死的成績那一組，行事曆提醒若沿用，使用者會看到一個叫「學期成績
/// 更新通知」的 channel 發出行事曆內容，而且沒辦法只關掉其中一種。
class NotificationChannelSpec {
  const NotificationChannelSpec({
    required this.id,
    required this.name,
    required this.description,
    this.importance = Importance.high,
    this.priority = Priority.high,
  });

  final String id;
  final String name;
  final String description;
  final Importance importance;
  final Priority priority;

  /// 學期成績更新通知。
  ///
  /// id 與顯示名稱沿用最初版本且刻意維持中文寫死 —— 換掉 id 會讓既有使用者
  /// 在系統設定裡調過的開關被重置成一組全新的 channel。
  static const gradeUpdates = NotificationChannelSpec(
    id: 'grade_updates_channel_id',
    name: '學期成績更新通知',
    description: '當期末/學期成績有更新時發出通知',
    importance: Importance.max,
  );

  /// 行事曆提醒。
  ///
  /// 名稱與描述隨 App 語言走；Android 的 `createNotificationChannel` 對既有
  /// channel 會就地更新名稱與描述，所以換語言後重新建立即可跟著改。
  static NotificationChannelSpec calendarReminders(AppLocalizations l10n) =>
      NotificationChannelSpec(
        id: 'calendar_reminders_channel_id',
        name: l10n.notificationChannelCalendarName,
        description: l10n.notificationChannelCalendarDescription,
      );

  AndroidNotificationDetails toAndroidDetails({
    StyleInformation? styleInformation,
    String? subText,
  }) => AndroidNotificationDetails(
    id,
    name,
    channelDescription: description,
    importance: importance,
    priority: priority,
    styleInformation: styleInformation,
    subText: subText,
  );

  AndroidNotificationChannel toAndroidChannel() => AndroidNotificationChannel(
    id,
    name,
    description: description,
    importance: importance,
  );
}
