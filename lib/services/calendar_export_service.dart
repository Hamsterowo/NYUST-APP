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

  /// 課綱某一週的某一個上課時段 → 一則有起訖時刻的事件。
  ///
  /// 一週有多個時段時，那一週的進度內容會**複製到每一個時段**上，而不是只掛在
  /// 第一筆。課綱的「第 N 週」描述的是那一週要上的內容，不是某一堂；而且兩個
  /// 時段可能在不同教室，合併成一筆地點就會是錯的。
  ///
  /// 所有文字都由呼叫端傳入已經在地化的成品 —— 這一層不認識 `AppLocalizations`。
  static IcsEvent fromSyllabusSession({
    required String uid,
    required String courseName,
    required String weekLabel,
    required String content,
    required DateTime start,
    required DateTime end,
    required String room,
    String method = '',
    String remark = '',
    String teacher = '',
    String syllabusUrl = '',
    String methodLabel = '',
    String remarkLabel = '',
    String teacherLabel = '',
  }) {
    // 摘要取進度內容的第一行，**不截字數** —— 截掉的那一半正好是使用者在行事曆
    // 上唯一看得到的資訊。行事曆自己會依欄寬省略，那是它該做的事。
    final headline = content.split('\n').first.trim();
    final summary = [
      courseName,
      weekLabel,
      if (headline.isNotEmpty) headline,
    ].join('・');

    final description = [
      if (content.trim().isNotEmpty) content.trim(),
      if (method.trim().isNotEmpty) '$methodLabel：${method.trim()}',
      if (remark.trim().isNotEmpty) '$remarkLabel：${remark.trim()}',
      if (teacher.trim().isNotEmpty) '$teacherLabel：${teacher.trim()}',
      // 已知這個連結需要登入才打得開，仍然附上：使用者自己有帳號，
      // 而「知道去哪裡找原文」比「連結乾淨」有用。
      if (syllabusUrl.trim().isNotEmpty) syllabusUrl.trim(),
    ].join('\n');

    return IcsEvent.timed(
      uid: uid,
      summary: summary,
      description: description,
      location: room,
      start: start,
      end: end,
    );
  }

  /// 課綱單週單時段的穩定 UID。
  ///
  /// 同一週按兩次不該長出兩筆，所以只由「哪一門課的哪一學期、第幾週、哪一個
  /// 時段」決定。時段以星期與起始節次識別 —— 同一天的兩個時段起始節次必然不同，
  /// 否則它們早就被併成同一塊了。
  static String uidForSyllabusSession({
    required String year,
    required String semester,
    required String courseNo,
    required int week,
    required int weekday,
    required String startPeriod,
  }) =>
      'yuntech-syllabus-$year$semester-$courseNo-w$week-d$weekday-$startPeriod'
      '@nyust-app';

  /// 校曆事件的穩定 UID。
  ///
  /// 同一筆事件按兩次不該在行事曆上長出兩則，所以 UID 只能由事件本身決定，不能
  /// 用時間戳或隨機值。學校給的 `id`（`{行事曆項目 id}-{子事件序號}`）已經是穩定
  /// 的；把日期也放進去，是為了擋掉學校改動某一天的條目後序號位移的情況。
  static String uidForCalendarEvent(CalendarEvent event) =>
      'yuntech-calendar-${event.date}-${event.id}@nyust-app';
}
