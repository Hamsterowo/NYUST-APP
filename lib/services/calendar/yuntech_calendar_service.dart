import '../api_client.dart';
import '../scrapers/calendar_scraper.dart';

/// 學校行事曆與假日。全校共用、與帳號無關，因此 demo 模式也用這一個實作，
/// 不需要介面（只有一個 adapter，沒有可換的第二個來源）。
class YunTechCalendarService {
  final ApiClient _client;
  late final CalendarScraper _calendarScraper;

  YunTechCalendarService(this._client) {
    _calendarScraper = CalendarScraper(_client.dio);
  }

  Future<Map<String, dynamic>> getCalendarEvents(
    String year, {
    String? lang,
  }) async {
    return _calendarScraper.getCalendarEvents(year, languageCode: lang);
  }

  Future<Map<String, dynamic>> getHolidays(int year, {String? lang}) async {
    return _calendarScraper.getHolidays(year, languageCode: lang);
  }

  Future<Map<String, dynamic>> getCalendarCombined(
    String year, {
    String? lang,
  }) async {
    final events = await getCalendarEvents(year, lang: lang);
    final holidays = await getHolidays(int.parse(year), lang: lang);

    return {
      'success': events['success'] == true && holidays['success'] == true,
      'events': events['events'] ?? [],
      'holidays': holidays['holidays'] ?? [],
      'holidayDetails': holidays['holidayDetails'] ?? {},
    };
  }
}
