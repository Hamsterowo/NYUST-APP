/// 學校行事曆與假日相關的服務介面。
abstract interface class CalendarService {
  /// 取得指定學年度的行事曆事件。
  Future<Map<String, dynamic>> getCalendarEvents(String year, {String? lang});

  /// 取得指定年份的假日。
  Future<Map<String, dynamic>> getHolidays(int year, {String? lang});

  /// 同時取得行事曆事件與假日，合併回傳。
  Future<Map<String, dynamic>> getCalendarCombined(String year, {String? lang});
}
