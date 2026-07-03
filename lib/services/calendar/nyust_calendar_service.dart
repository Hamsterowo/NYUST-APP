import '../api_client.dart';
import '../scrapers/calendar_scraper.dart';
import 'calendar_service.dart';

/// 以 YunTech 網頁為後端的 [CalendarService] 實作。
class NyustCalendarService implements CalendarService {
  final ApiClient _client;
  late final CalendarScraper _calendarScraper;

  NyustCalendarService(this._client) {
    _calendarScraper = CalendarScraper(_client.dio);
  }

  @override
  Future<Map<String, dynamic>> getCalendarEvents(String year,
      {String? lang}) async {
    await _client.ensureInit();
    return _calendarScraper.getCalendarEvents(year, languageCode: lang);
  }

  @override
  Future<Map<String, dynamic>> getHolidays(int year, {String? lang}) async {
    await _client.ensureInit();
    return _calendarScraper.getHolidays(year, languageCode: lang);
  }

  @override
  Future<Map<String, dynamic>> getCalendarCombined(String year,
      {String? lang}) async {
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
