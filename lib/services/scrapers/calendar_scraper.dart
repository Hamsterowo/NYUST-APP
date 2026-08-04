import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../utils/network_error.dart';
import 'base_scraper.dart';

/// 處理行事曆與假日爬取的類別
class CalendarScraper extends BaseScraper {
  CalendarScraper(super.dio);

  /// 把行事曆一格的原文拆成獨立的事件名稱。
  ///
  /// 中文以 `；` 分隔，明確可靠。英文版**從來不用 `；`** —— 2022–2027 六年 715
  /// 筆英文原文裡出現 0 次，一律用逗號，而且事件名稱**內部**的並列也用逗號。
  /// 所以英文的切分本質上只能靠「逗號後面接什麼」判斷，是啟發式而不是解析。
  ///
  /// 三個邊界訊號，各自對應學校真的寫過、舊規則切不開的形態：
  /// - 逗號後接大寫或中文：`...(for all students),Application for tuition...`
  ///   —— 逗號後**不一定有空格**，2023 年整年都是這種寫法。
  /// - 逗號後接學年度前綴：`Winter vacation begins, 113-2 The application...`
  ///   —— 只認 `113-2` 這種形態，不是任何數字都算。放寬成任意數字的話，
  ///   `...on January 13, 2013 (Sat), the election of...` 會被從日期中間切成兩半。
  /// - 句點後直接接大寫：`...teacher ends.Reporting/uploading of GEPT...`
  ///   —— 學校漏打分隔符時的黏連。
  ///
  /// 反過來，名稱**內部**的並列在英文寫成「逗號 + 空格 + 小寫」
  /// （`credit waivers, and transference`），三個訊號都不命中，所以不會被切開。
  ///
  /// 相對舊規則是嚴格改善：六年真實行事曆實測多切出 175 個片段、讓 252 筆事件
  /// 得以配到英文名稱，而原本就配對正確的 867 筆沒有任何一筆結果改變。
  static List<String> splitEventNames(String name, {required bool isEnglish}) {
    final entries = name
        .split('；')
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty);
    if (!isEnglish) return entries.toList();

    return [
      for (final entry in entries)
        ...entry
            .split(_englishSeparator)
            .map((n) => n.replaceAll(_danglingSeparator, ''))
            .where((n) => n.isNotEmpty),
    ];
  }

  /// 片段頭尾殘留的逗號與空白。
  ///
  /// 學校偶爾會在一整格的結尾多打一個分隔符 —— 中文結尾的 `；` 被切分自然吃掉，
  /// 英文結尾的逗號沒有，於是最後一個事件名變成 `On-line course add/drop begins,`。
  /// 在通知裡它會長成 `begins, / Delivery of...`，讀起來像兩個事件黏在一起。
  /// 六年真實資料裡有 2 筆（2024-09-06、2026-09-07）。
  ///
  /// 只刮逗號，不動句點：`...students ends.` 的句點是句子本身的一部分。
  static final RegExp _danglingSeparator = RegExp(r'^[,\s]+|[,\s]+$');

  static final RegExp _englishSeparator = RegExp(
    r',\s*(?=[A-Z\u4e00-\u9fa5]|\d{3}-\d)|\.(?=[A-Z])',
  );

  /// 獲取特定年份的行事曆事件
  Future<Map<String, dynamic>> getCalendarEvents(
    String year, {
    String? languageCode,
  }) async {
    try {
      String langValue = 'zh-tw';
      if (languageCode != null) {
        langValue = languageCode.toLowerCase() == 'en' ? 'en' : 'zh-tw';
      } else {
        String detectedCode = 'zh';
        try {
          if (Intl.defaultLocale != null && Intl.defaultLocale!.isNotEmpty) {
            detectedCode = Intl.defaultLocale!
                .split('_')
                .first
                .split('-')
                .first
                .toLowerCase();
          } else {
            detectedCode = ui.PlatformDispatcher.instance.locale.languageCode
                .toLowerCase();
          }
        } catch (_) {
          try {
            detectedCode = ui.PlatformDispatcher.instance.locale.languageCode
                .toLowerCase();
          } catch (_) {}
        }
        langValue = detectedCode == 'en' ? 'en' : 'zh-tw';
      }

      final calendarUrl =
          'https://events.yuntech.edu.tw/?&y=$year&view=YunTech&lang=$langValue';
      if (kDebugMode)
        print('CalendarScraper: Fetching events from $calendarUrl');

      final response = await dio.get(
        calendarUrl,
        options: Options(headers: commonHeaders),
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
            final isImportant =
                htmlStr.contains('ff0000') || styleStr.contains('ff0000');

            if (eventYear != null &&
                eventMonth != null &&
                eventDay != null &&
                name.isNotEmpty) {
              final eventNames = splitEventNames(
                name,
                isEnglish: langValue == 'en',
              );

              int index = 0;
              for (var singleName in eventNames) {
                events.add({
                  'id': '$eventId-${index++}',
                  'date':
                      '$eventYear-${eventMonth.padLeft(2, '0')}-${eventDay.padLeft(2, '0')}',
                  'name': singleName,
                  'link': uri.toString(),
                  'isImportant': isImportant,
                });
              }
            }
          } catch (e) {}
        }
      }

      return {
        'success': true,
        'year': year,
        'count': events.length,
        'events': events,
      };
    } catch (e) {
      // 先判離線再歸類其他錯誤；message 僅供除錯 log，不進 UI。
      if (isNetworkError(e)) {
        return {
          'success': false,
          'status': 'network_error',
          'message': 'Network error fetching calendar: $e',
        };
      }
      return {
        'success': false,
        'status': 'error',
        'message': 'Failed to fetch calendar: $e',
      };
    }
  }

  /// 獲取特定年份的假日 (包含國定假日與寒暑假)
  Future<Map<String, dynamic>> getHolidays(
    int year, {
    String? languageCode,
  }) async {
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
                nationalHolidays.add(
                  '${dateStr.substring(0, 4)}-${dateStr.substring(4, 6)}-${dateStr.substring(6, 8)}',
                );
              }
            }
          }
        }
      } catch (e) {
        if (kDebugMode)
          print('CalendarScraper: Failed to fetch national holidays: $e');
      }

      final winterHolidays = <String>[];
      final summerHolidays = <String>[];

      try {
        final calendarUrl =
            'https://events.yuntech.edu.tw/?&y=$year&view=YunTech&lang=zh-tw';
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
              final dateStr =
                  '$evYear-${evMonth.padLeft(2, '0')}-${evDay.padLeft(2, '0')}';
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
        if (kDebugMode)
          print('CalendarScraper: Failed to fetch school vacations: $e');
      }

      final allHolidaysSet = <String>{
        ...nationalHolidays,
        ...winterHolidays,
        ...summerHolidays,
      };
      final finalHolidays = allHolidaysSet.toList()..sort();

      final holidayDetails = <String, String>{};
      for (var d in nationalHolidays) {
        holidayDetails[d] = 'national';
      }
      for (var d in winterHolidays) {
        if (!holidayDetails.containsKey(d))
          holidayDetails[d] = 'winter_vacation';
      }
      for (var d in summerHolidays) {
        if (!holidayDetails.containsKey(d))
          holidayDetails[d] = 'summer_vacation';
      }

      return {
        'success': true,
        'year': year,
        'count': finalHolidays.length,
        'holidays': finalHolidays,
        'holidayDetails': holidayDetails,
      };
    } catch (e) {
      // 先判離線再歸類其他錯誤；message 僅供除錯 log，不進 UI。
      if (isNetworkError(e)) {
        return {
          'success': false,
          'status': 'network_error',
          'message': 'Network error fetching holidays: $e',
        };
      }
      return {
        'success': false,
        'status': 'error',
        'message': 'Failed to fetch holidays: $e',
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
