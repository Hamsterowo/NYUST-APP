import 'package:flutter/foundation.dart';

import 'notification_payload.dart';

/// 通知點擊後的導航目的地，先擱在這裡等畫面來取。
///
/// 為什麼不在收到當下直接導航：App 被完全關閉時點通知（冷啟動），外掛的點擊
/// callback **不會**為那一則觸發，資訊只能在啟動時主動向
/// `getNotificationAppLaunchDetails()` 要 —— 而那個時間點 router 與畫面都還
/// 沒建起來。
///
/// 所以兩條路徑一律先把目的地放進來、由畫面 drain：冷啟動與「App 已在執行時
/// 點通知」走完全同一段程式碼，不必去猜「router 準備好了沒」。使用者停在登入
/// 頁時沒有人來取，目的地就只是擱著，不會導到空白畫面。
class NotificationNavigator {
  NotificationNavigator._();

  /// 待處理的目的地；`null` 表示沒有。
  static final ValueNotifier<NotificationPayload?> pending =
      ValueNotifier<NotificationPayload?>(null);

  static void submit(NotificationPayload payload) => pending.value = payload;

  /// 取出並清掉待處理的目的地。
  static NotificationPayload? take() {
    final value = pending.value;
    pending.value = null;
    return value;
  }
}
