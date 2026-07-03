import 'calendar_service.dart';

/// Demo / 除錯模式使用的 [CalendarService]，回傳固定的 mock 行事曆與假日。
///
/// 事件日期會依傳入的年份動態產生，讓 Demo 模式在任何年份看起來都合理。
class MockCalendarService implements CalendarService {
  @override
  Future<Map<String, dynamic>> getCalendarEvents(String year,
      {String? lang}) async {
    final events = [
      {
        'id': 'mock-1-0',
        'date': '$year-09-11',
        'name': '第一學期開學',
        'link': '',
        'isImportant': true,
      },
      {
        'id': 'mock-2-0',
        'date': '$year-10-10',
        'name': '國慶日放假',
        'link': '',
        'isImportant': false,
      },
      {
        'id': 'mock-3-0',
        'date': '$year-11-15',
        'name': '期中考週',
        'link': '',
        'isImportant': true,
      },
    ];
    return {
      'success': true,
      'year': year,
      'count': events.length,
      'events': events,
    };
  }

  @override
  Future<Map<String, dynamic>> getHolidays(int year, {String? lang}) async {
    final holidays = ['$year-10-10', '$year-01-01'];
    return {
      'success': true,
      'year': year,
      'count': holidays.length,
      'holidays': holidays,
      'holidayDetails': {
        '$year-10-10': 'national',
        '$year-01-01': 'national',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> getCalendarCombined(String year,
      {String? lang}) async {
    final events = await getCalendarEvents(year, lang: lang);
    final holidays = await getHolidays(int.parse(year), lang: lang);
    return {
      'success': true,
      'events': events['events'] ?? [],
      'holidays': holidays['holidays'] ?? [],
      'holidayDetails': holidays['holidayDetails'] ?? {},
    };
  }
}
