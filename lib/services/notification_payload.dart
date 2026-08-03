import 'dart:convert';

/// 一則通知點下去之後要去哪裡。
///
/// 以 JSON 承載而不是比對字串常數。原本是 `payload == 'grades'`：每多一種通知
/// 就得在同一條 if 鏈上再加一段，而且沒有地方掛額外資料 —— 行事曆提醒要帶著
/// 「是哪一天」，字串常數放不下。
class NotificationPayload {
  const NotificationPayload({required this.type, this.date});

  /// 成績更新通知：開啟成績頁。
  static const String typeGrades = 'grades';

  /// 行事曆提醒：切到行事曆分頁並選中 [date] 那一天。
  static const String typeCalendar = 'calendar';

  final String type;

  /// 這則通知指向的日期（僅 [typeCalendar] 會帶）。
  final DateTime? date;

  String encode() =>
      jsonEncode({'type': type, if (date != null) 'date': _formatDate(date!)});

  /// 解析 payload；無法解析時回傳 `null`，呼叫端就只開啟 App、不做導航。
  ///
  /// 也吃得下舊版的裸字串 `'grades'` —— 更新前發出、還留在通知欄裡的成績通知
  /// 帶的是舊格式，點下去仍然要能導航。
  static NotificationPayload? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw == typeGrades) return const NotificationPayload(type: typeGrades);

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;

      final type = decoded['type'];
      if (type is! String || type.isEmpty) return null;

      final date = decoded['date'];
      return NotificationPayload(
        type: type,
        date: date is String ? DateTime.tryParse(date) : null,
      );
    } catch (_) {
      return null;
    }
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  String toString() =>
      'NotificationPayload($type${date == null ? '' : ' @$date'})';
}
