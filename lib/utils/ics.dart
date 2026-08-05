/// iCalendar（RFC 5545）文字產生。
///
/// 這一層是純文字處理，不碰檔案、不碰平台，因為它是整個「加入行事曆」功能裡
/// 唯一會安靜地錯掉的部分：跳脫或折行寫錯時，系統日曆只會說「無法匯入」，
/// 不會告訴你錯在哪一行、哪一個字元。所以它獨立成可測試的模組。
library;

import 'dart:convert';

/// 一則要匯出的事件。
///
/// 只有兩種形態：整天（[IcsEvent.allDay]）與有起訖時刻（[IcsEvent.timed]）。
/// 學校行事曆只給單一日期，所以校曆事件一律是前者。
class IcsEvent {
  /// 穩定識別碼。同一筆事件重複匯出時，日曆會視為同一則而更新，不會長出第二則。
  final String uid;

  final String summary;
  final String description;
  final String location;

  /// 事件起點。整天事件只看日期部分。
  final DateTime start;

  /// 事件終點（不含）。整天事件為隔天的日期。
  final DateTime end;

  final bool isAllDay;

  const IcsEvent._({
    required this.uid,
    required this.summary,
    required this.description,
    required this.location,
    required this.start,
    required this.end,
    required this.isAllDay,
  });

  /// 單日的全天事件。[date] 的時刻部分會被忽略。
  factory IcsEvent.allDay({
    required String uid,
    required String summary,
    required DateTime date,
    String description = '',
    String location = '',
  }) {
    final day = DateTime(date.year, date.month, date.day);
    return IcsEvent._(
      uid: uid,
      summary: summary,
      description: description,
      location: location,
      start: day,
      // DTEND 在 RFC 5545 是「不含」的，全天事件因此要指到隔天。
      // 用 DateTime 建構子加一天（而不是 Duration）以正確跨月、跨年。
      end: DateTime(day.year, day.month, day.day + 1),
      isAllDay: true,
    );
  }

  /// 有起訖時刻的事件。時間視為**浮動當地時間**，見 [IcsCalendar.build]。
  factory IcsEvent.timed({
    required String uid,
    required String summary,
    required DateTime start,
    required DateTime end,
    String description = '',
    String location = '',
  }) {
    return IcsEvent._(
      uid: uid,
      summary: summary,
      description: description,
      location: location,
      start: start,
      end: end,
      isAllDay: false,
    );
  }
}

/// 把 [IcsEvent] 組成一份可交給系統日曆的 iCalendar 文字。
class IcsCalendar {
  IcsCalendar._();

  /// 產品識別碼。RFC 5545 要求要有，內容由產生者自訂。
  static const String prodId = '-//YunTool//NYUST-APP//ZH-TW';

  /// 產生完整的 VCALENDAR 文字。
  ///
  /// **時間一律不帶時區**（沒有 `Z`、沒有 `TZID`）—— RFC 5545 稱之為浮動時間，
  /// 意思是「就是牆上時鐘的那個時刻」。這正是上課時間該有的語意，而且省下在
  /// 檔案裡塞一份 VTIMEZONE。台灣沒有日光節約時間，不會有換算歧義。
  ///
  /// [now] 用於 `DTSTAMP`（該欄位依規格必須是 UTC）。由呼叫端傳入，讓輸出對
  /// 相同輸入是決定性的、可以寫 golden 測試。
  static String build(List<IcsEvent> events, {required DateTime now}) {
    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:$prodId',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
    ];

    final stamp = _formatUtc(now);
    for (final event in events) {
      lines.addAll([
        'BEGIN:VEVENT',
        'UID:${escapeText(event.uid)}',
        'DTSTAMP:$stamp',
        if (event.isAllDay) ...[
          'DTSTART;VALUE=DATE:${_formatDate(event.start)}',
          'DTEND;VALUE=DATE:${_formatDate(event.end)}',
        ] else ...[
          'DTSTART:${_formatLocal(event.start)}',
          'DTEND:${_formatLocal(event.end)}',
        ],
        'SUMMARY:${escapeText(event.summary)}',
        if (event.description.isNotEmpty)
          'DESCRIPTION:${escapeText(event.description)}',
        if (event.location.isNotEmpty) 'LOCATION:${escapeText(event.location)}',
        'END:VEVENT',
      ]);
    }

    lines.add('END:VCALENDAR');

    // 規格要求 CRLF，且結尾也要有一個。
    return '${lines.map(foldLine).join('\r\n')}\r\n';
  }

  /// RFC 5545 §3.3.11 的 TEXT 跳脫。
  ///
  /// 反斜線必須**先**處理，否則後面補上的跳脫反斜線會被自己再跳脫一次。
  /// 換行寫成字面上的 `\n`。冒號**不跳脫** —— 規格只要求跳脫這四個。
  static String escapeText(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll(';', '\\;')
      .replaceAll(',', '\\,')
      .replaceAll('\r\n', '\\n')
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\n');

  /// RFC 5545 §3.1 的折行：一行最多 75 個 octet，後續行以一個空白開頭。
  ///
  /// 算的是 **UTF-8 的 octet 數而不是字元數** —— 中文一個字佔三個 octet，照字元
  /// 數折的話一行會超長。而且切點必須落在字元邊界上：從多位元組字元中間切開會
  /// 產生無效的 UTF-8，日曆同樣只會回一句「無法匯入」。
  static String foldLine(String line) {
    final bytes = utf8.encode(line);
    if (bytes.length <= _maxOctets) return line;

    final buffer = StringBuffer();
    var lineOctets = 0;
    var isContinuation = false;

    for (final rune in line.runes) {
      final char = String.fromCharCode(rune);
      final width = utf8.encode(char).length;

      // 後續行開頭那個空白也算進 75 個 octet 裡。
      final limit = isContinuation ? _maxOctets - 1 : _maxOctets;
      if (lineOctets + width > limit) {
        buffer.write('\r\n ');
        lineOctets = 0;
        isContinuation = true;
      }

      buffer.write(char);
      lineOctets += width;
    }

    return buffer.toString();
  }

  static const int _maxOctets = 75;

  /// `20260217`
  static String _formatDate(DateTime date) =>
      '${_pad4(date.year)}${_pad2(date.month)}${_pad2(date.day)}';

  /// `20260217T101000`（浮動當地時間，無時區標示）
  static String _formatLocal(DateTime time) =>
      '${_formatDate(time)}T${_pad2(time.hour)}${_pad2(time.minute)}${_pad2(time.second)}';

  /// `20260217T021000Z`（DTSTAMP 專用，規格要求 UTC）
  static String _formatUtc(DateTime time) {
    final utc = time.toUtc();
    return '${_formatLocal(utc)}Z';
  }

  static String _pad2(int value) => value.toString().padLeft(2, '0');
  static String _pad4(int value) => value.toString().padLeft(4, '0');
}
