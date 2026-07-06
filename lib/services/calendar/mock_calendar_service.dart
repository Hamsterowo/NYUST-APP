import 'calendar_service.dart';
import '../mock/mock_data.dart';

/// Demo 模式使用的 [CalendarService]，回傳 [MockData] 中的行事曆與假日。
///
/// 事件日期依傳入年份動態產生，讓 demo 模式在任何年份看起來都合理。
class MockCalendarService implements CalendarService {
  @override
  Future<Map<String, dynamic>> getCalendarEvents(
    String year, {
    String? lang,
  }) async =>
      MockData.calendarEvents(year, lang: lang);

  @override
  Future<Map<String, dynamic>> getHolidays(int year, {String? lang}) async =>
      MockData.holidays(year, lang: lang);

  @override
  Future<Map<String, dynamic>> getCalendarCombined(
    String year, {
    String? lang,
  }) async =>
      MockData.calendarCombined(year, lang: lang);
}
