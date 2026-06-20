import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'base_scraper.dart';

/// 處理行事曆與假日爬取的類別
class CalendarScraper extends BaseScraper {
  CalendarScraper(super.dio);

  /// 獲取特定年份的行事曆事件
  Future<Map<String, dynamic>> getCalendarEvents(String year, {String? languageCode}) async {
    try {
      String langValue = 'zh-tw';
      if (languageCode != null) {
        langValue = languageCode.toLowerCase() == 'en' ? 'en' : 'zh-tw';
      } else {
        String detectedCode = 'zh';
        try {
          if (Intl.defaultLocale != null && Intl.defaultLocale!.isNotEmpty) {
            detectedCode = Intl.defaultLocale!.split('_').first.split('-').first.toLowerCase();
          } else {
            detectedCode = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
          }
        } catch (_) {
          try {
            detectedCode = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
          } catch (_) {}
        }
        langValue = detectedCode == 'en' ? 'en' : 'zh-tw';
      }

      final calendarUrl = 'https://events.yuntech.edu.tw/?&y=$year&view=YunTech&lang=$langValue';
      if (kDebugMode) print('CalendarScraper: Fetching events from $calendarUrl');

      final response = await dio.get(
        calendarUrl,
        options: Options(
          headers: commonHeaders,
        ),
      );

      final document = parseHtml(response.data);
      final List<Map<String, dynamic>> events = [];

      final links = document.querySelectorAll('a');
      for (var element in links) {
        final href = element.attributes['href'];
        if (href != null && href.contains('eventdatetime_id=')) {
          final name = element.text.trim();

          try {
            final baseUri = Uri.parse('https://events.yuntech.edu.tw/');
            final uri = href.startsWith('http')
                ? Uri.parse(href)
                : baseUri.resolve(href);
            final eventYear = uri.queryParameters['y'];
            final eventMonth = uri.queryParameters['m'];
            final eventDay = uri.queryParameters['d'];
            final eventId = uri.queryParameters['eventdatetime_id'];

            final htmlStr = element.innerHtml.toLowerCase();
            final styleStr = (element.attributes['style'] ?? '').toLowerCase();
            final isImportant = htmlStr.contains('ff0000') || styleStr.contains('ff0000');

            if (eventYear != null && eventMonth != null && eventDay != null && name.isNotEmpty) {

              Iterable<String> eventNames;
              if (langValue == 'en') {
                final tempNames = name.split('；').map((n) => n.trim()).where((n) => n.isNotEmpty);
                final List<String> splitNames = [];
                final commaRegex = RegExp(r', \s*(?=[A-Z\u4e00-\u9fa5])');
                for (var tempName in tempNames) {
                  splitNames.addAll(tempName.split(commaRegex).map((n) => n.trim()).where((n) => n.isNotEmpty));
                }
                eventNames = splitNames;
              } else {
                eventNames = name.split('；').map((n) => n.trim()).where((n) => n.isNotEmpty);
              }

              int index = 0;
              for (var singleName in eventNames) {
                events.add({
                  'id': '$eventId-${index++}',
                  'date': '$eventYear-${eventMonth.padLeft(2, '0')}-${eventDay.padLeft(2, '0')}',
                  'name': singleName,
                  'link': uri.toString(),
                  'isImportant': isImportant
                });
              }
            }
          } catch (e) {

          }
        }
      }

      return {
        'success': true,
        'year': year,
        'count': events.length,
        'events': events
      };
    } catch (e) {
      return {
        'success': false,
        'message': '獲取行事曆失敗: $e',
      };
    }
  }

  /// 獲取特定年份的假日 (包含國定假日與寒暑假)
  Future<Map<String, dynamic>> getHolidays(int year, {String? languageCode}) async {
    try {
      if (kDebugMode) print('CalendarScraper: Fetching holidays for $year');

      final List<String> nationalHolidays = [];

      try {
        final holidayRes = await dio.get(
          'https://cdn.jsdelivr.net/gh/ruyut/TaiwanCalendar/data/$year.json',
        );
        if (holidayRes.statusCode == 200 && holidayRes.data is List) {
          for (var item in holidayRes.data) {
            if (item['isHoliday'] == true) {
              final String dateStr = item['date'].toString();
              if (dateStr.length == 8) {
                nationalHolidays.add('${dateStr.substring(0, 4)}-${dateStr.substring(4, 6)}-${dateStr.substring(6, 8)}');
              }
            }
          }
        }
      } catch (e) {
        if (kDebugMode) print('CalendarScraper: Failed to fetch national holidays: $e');
      }

      final winterHolidays = <String>[];
      final summerHolidays = <String>[];

      try {
        final calendarUrl = 'https://events.yuntech.edu.tw/?&y=$year&view=YunTech&lang=zh-tw';
        final response = await dio.get(calendarUrl);
        final document = parseHtml(response.data);

        String? winterStart, winterEnd, summerStart, summerEnd;

        final links = document.querySelectorAll('a');
        for (var element in links) {
          final href = element.attributes['href'];
          if (href != null && href.contains('eventdatetime_id=')) {
            final name = element.text.trim();
            final baseUri = Uri.parse('https://events.yuntech.edu.tw/');
            final uri = href.startsWith('http')
                ? Uri.parse(href)
                : baseUri.resolve(href);
            final evYear = uri.queryParameters['y'];
            final evMonth = uri.queryParameters['m'];
            final evDay = uri.queryParameters['d'];

            if (evYear != null && evMonth != null && evDay != null) {
              final dateStr = '$evYear-${evMonth.padLeft(2, '0')}-${evDay.padLeft(2, '0')}';
              final eventNames = name.split('；');
              for (var n in eventNames) {
                if (n.contains('寒假開始')) winterStart = dateStr;
                if (n.contains('寒假結束')) winterEnd = dateStr;
                if (n.contains('暑假開始')) summerStart = dateStr;
                if (n.contains('暑假結束')) summerEnd = dateStr;
              }
            }
          }
        }

        if (winterStart != null && winterEnd != null) {
          winterHolidays.addAll(_getDatesInRange(winterStart, winterEnd));
        }
        if (summerStart != null && summerEnd != null) {
          summerHolidays.addAll(_getDatesInRange(summerStart, summerEnd));
        }
      } catch (e) {
        if (kDebugMode) print('CalendarScraper: Failed to fetch school vacations: $e');
      }

      final allHolidaysSet = <String>{...nationalHolidays, ...winterHolidays, ...summerHolidays};
      final finalHolidays = allHolidaysSet.toList()..sort();

      final holidayDetails = <String, String>{};
      for (var d in nationalHolidays) {
        holidayDetails[d] = 'national';
      }
      for (var d in winterHolidays) {
        if (!holidayDetails.containsKey(d)) holidayDetails[d] = 'winter_vacation';
      }
      for (var d in summerHolidays) {
        if (!holidayDetails.containsKey(d)) holidayDetails[d] = 'summer_vacation';
      }

      return {
        'success': true,
        'year': year,
        'count': finalHolidays.length,
        'holidays': finalHolidays,
        'holidayDetails': holidayDetails
      };
    } catch (e) {
      return {
        'success': false,
        'message': '獲取假日資訊失敗: $e',
      };
    }
  }

  /// 輔助方法：生成日期範圍內的日期列表
  List<String> _getDatesInRange(String startStr, String endStr) {
    final dates = <String>[];
    DateTime current = DateTime.parse(startStr);
    final DateTime end = DateTime.parse(endStr);

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      final y = current.year;
      final m = current.month.toString().padLeft(2, '0');
      final d = current.day.toString().padLeft(2, '0');
      dates.add('$y-$m-$d');
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }
}
