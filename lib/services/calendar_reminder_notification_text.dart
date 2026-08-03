import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../utils/calendar_reminder_planner.dart';

/// 一則行事曆提醒通知的四段文字。
///
/// 版面拆在這裡而不是直接寫在排程呼叫裡，是為了讓「一天一件事」與「一天六件事」
/// 兩種呈現、以及中英兩種語言，都能不建 widget、不碰通知外掛就驗證。
class ReminderNotificationText {
  const ReminderNotificationText({
    required this.title,
    required this.collapsed,
    required this.expanded,
    required this.lead,
  });

  /// 通知標題，固定為「行事曆提醒」。
  final String title;

  /// 收合時顯示的單行預覽。
  ///
  /// 一天只有一件事時直接寫事件名（不寫「共 1 項」之類的贅詞），多件時收斂成
  /// 件數 —— 攤開列名字在通知欄一行的寬度內只會被系統攔腰截斷，反而看不出那天
  /// 到底有幾件事。
  ///
  /// 這一行是專門排過的，不是把 [expanded] 丟進去讓系統截斷：Android 收合狀態
  /// 只顯示 contentText，換行字元不會保留。
  final String collapsed;

  /// 展開後的內文：第一行是事件日期，其下逐行列出該日的事件名稱。
  ///
  /// 同日多事件不常見（三年 93 個命中日期裡只有 8 天），但最壞情況是開學日一天
  /// 六筆，所以多行是必要的而不是裝飾。
  final String expanded;

  /// 提前天數，放平台的副標欄位（Android subText／iOS subtitle），
  /// 不佔用內文行數。
  final String lead;

  factory ReminderNotificationText.from(
    PlannedReminder reminder,
    AppLocalizations l10n,
  ) {
    final dateText = _formatDate(reminder.eventDate, l10n.localeName);
    final names = reminder.eventNames;

    return ReminderNotificationText(
      title: l10n.calendarReminderTitle,
      collapsed: l10n.calendarReminderCollapsedBody(
        dateText,
        names.length == 1
            ? names.single
            : l10n.calendarReminderEventCount(names.length),
      ),
      expanded: [dateText, ...names].join('\n'),
      lead: _leadText(l10n, reminder.daysBefore),
    );
  }

  /// 事件日期。語系的日期符號由 `GlobalMaterialLocalizations` 在載入該語系時
  /// 註冊；萬一沒註冊到，退回不指定語系的格式而不是讓整則通知排不進去。
  static String _formatDate(DateTime date, String localeName) {
    try {
      return DateFormat.MMMMd(localeName).format(date);
    } catch (_) {
      return DateFormat.MMMMd().format(date);
    }
  }

  static String _leadText(AppLocalizations l10n, int daysBefore) =>
      switch (daysBefore) {
        0 => l10n.calendarReminderLeadToday,
        1 => l10n.calendarReminderLeadTomorrow,
        _ => l10n.calendarReminderLeadDays(daysBefore),
      };
}
