import 'package:flutter/foundation.dart';

import '../models/calendar_event.dart';
import '../utils/ics.dart';
import '../utils/ics_launcher/ics_launcher.dart';
import 'server_time_service.dart';

/// 把事件交給使用者自己的行事曆。
///
/// 這一層刻意保持薄：iCalendar 文字怎麼寫在 [IcsCalendar]，檔案怎麼落地與怎麼
/// 交給系統在 `ics_launcher/`，這裡只負責「一筆學校資料要長成什麼樣的事件」。
class CalendarExportService {
  CalendarExportService._();

  /// 這個平台能不能把事件交給系統日曆。
  ///
  /// 依「有沒有檔案系統可以放 .ics」判斷 —— Web 沒有，其餘五個平台都有。
  static bool get isSupported => !kIsWeb;

  /// 匯出一批事件。呼叫端負責先確認 [isSupported]。
  static Future<void> export(
    List<IcsEvent> events, {
    required String filename,
  }) async {
    final text = IcsCalendar.build(
      events,
      now: ServerTimeService.instance.now(),
    );
    await openIcsFile(text, filename: filename);
  }

  /// 學校行事曆的一筆事件 → 一則全天事件。
  ///
  /// 只能是全天單日：學校只給單一日期，跨期間的事被寫成「期中考開始」／
  /// 「期中考結束」兩筆，沒有可靠的方式把它們配成一個區間。
  ///
  /// 標題就是事件原名，**不加來源前綴** —— 行事曆的格子很窄，前綴會把真正有用的
  /// 字擠掉。來源說明改放在描述欄，那裡有的是空間。
  ///
  /// 不帶提醒：App 自己已經有校曆通知（見 `CalendarReminderService`），再帶一個
  /// 進去會變成同一件事通知兩次。
  static IcsEvent fromCalendarEvent(
    CalendarEvent event, {
    required String sourceNote,
  }) {
    final description = [
      sourceNote,
      if (event.link.isNotEmpty) event.link,
    ].join('\n');

    return IcsEvent.allDay(
      uid: uidForCalendarEvent(event),
      summary: event.name,
      date: event.getDateTime(),
      description: description,
    );
  }

  /// 校曆事件的穩定 UID。
  ///
  /// 同一筆事件按兩次不該在行事曆上長出兩則，所以 UID 只能由事件本身決定，不能
  /// 用時間戳或隨機值。學校給的 `id`（`{行事曆項目 id}-{子事件序號}`）已經是穩定
  /// 的；把日期也放進去，是為了擋掉學校改動某一天的條目後序號位移的情況。
  static String uidForCalendarEvent(CalendarEvent event) =>
      'yuntech-calendar-${event.date}-${event.id}@nyust-app';
}
