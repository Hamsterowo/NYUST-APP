import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:yun_tool/l10n/app_localizations.dart';
import 'package:yun_tool/services/calendar_reminder_notification_text.dart';
import 'package:yun_tool/utils/calendar_reminder_planner.dart';

/// Locks ticket 04: the notification's layout — the date line, one event per
/// line below it, the collapsed one-line preview, and the lead time in the
/// platform's sub-text field — in both languages.
void main() {
  setUpAll(initializeDateFormatting);

  final zh = lookupAppLocalizations(const Locale('zh'));
  final en = lookupAppLocalizations(const Locale('en'));

  PlannedReminder reminder({
    required List<String> names,
    int daysBefore = 1,
    DateTime? eventDate,
  }) => PlannedReminder(
    id: 1,
    triggerTime: DateTime(2026, 9, 6, 8),
    eventDate: eventDate ?? DateTime(2026, 9, 7),
    daysBefore: daysBefore,
    eventNames: names,
  );

  group('title', () {
    test('is the fixed "calendar reminders" string in both languages', () {
      expect(
        ReminderNotificationText.from(reminder(names: ['上課開始']), zh).title,
        '行事曆提醒',
      );
      expect(
        ReminderNotificationText.from(reminder(names: ['上課開始']), en).title,
        'Calendar reminders',
      );
    });
  });

  group('expanded body', () {
    test('starts with the event date, then one event per line', () {
      final text = ReminderNotificationText.from(
        reminder(names: ['上課開始', '第1學期開始', '全校加退選開始']),
        zh,
      );

      expect(text.expanded.split('\n'), ['9月7日', '上課開始', '第1學期開始', '全校加退選開始']);
    });

    test('a single event still gets the date line and nothing extra', () {
      final text = ReminderNotificationText.from(
        reminder(names: ['期中考開始']),
        zh,
      );

      expect(text.expanded.split('\n'), ['9月7日', '期中考開始']);
    });

    test('the worst case — six events on the first day of class — fits', () {
      final names = [
        '上課開始',
        '第1學期開始',
        '全校加退選開始',
        '第1學期註冊',
        '學雜費繳費開始',
        '就學貸款申請開始',
      ];
      final text = ReminderNotificationText.from(reminder(names: names), zh);

      expect(text.expanded.split('\n'), ['9月7日', ...names]);
    });

    test('the date follows the display language', () {
      final text = ReminderNotificationText.from(
        reminder(names: ['Classes begin']),
        en,
      );

      expect(text.expanded.split('\n'), ['September 7', 'Classes begin']);
    });
  });

  group('collapsed preview', () {
    test('a single event reads plainly, with no count phrasing', () {
      final text = ReminderNotificationText.from(
        reminder(names: ['期中考開始']),
        zh,
      );

      expect(text.collapsed, '9月7日 · 期中考開始');
    });

    test('more than one event collapses to a count, not a list of names', () {
      final text = ReminderNotificationText.from(
        reminder(names: ['上課開始', '第1學期開始']),
        zh,
      );

      expect(text.collapsed, '9月7日 · 2 個事項');
      expect(text.collapsed.contains('上課開始'), isFalse);
    });

    test('the worst case reads as a count too', () {
      final text = ReminderNotificationText.from(
        reminder(
          names: ['上課開始', '第1學期開始', '全校加退選開始', '第1學期註冊', '學雜費繳費開始', '就學貸款申請開始'],
        ),
        zh,
      );

      expect(text.collapsed, '9月7日 · 6 個事項');
    });

    test('is always a single line', () {
      final text = ReminderNotificationText.from(
        reminder(names: ['上課開始', '第1學期開始']),
        zh,
      );

      expect(text.collapsed.contains('\n'), isFalse);
    });

    test('English shows the name for one event and a count for several', () {
      expect(
        ReminderNotificationText.from(
          reminder(names: ['Classes begin']),
          en,
        ).collapsed,
        'September 7 · Classes begin',
      );
      expect(
        ReminderNotificationText.from(
          reminder(names: ['Classes begin', 'Semester begins']),
          en,
        ).collapsed,
        'September 7 · 2 items',
      );
    });
  });

  group('lead time', () {
    test('the day of the events reads as "today"', () {
      expect(
        ReminderNotificationText.from(
          reminder(names: ['上課開始'], daysBefore: 0),
          zh,
        ).lead,
        '今天',
      );
      expect(
        ReminderNotificationText.from(
          reminder(names: ['Classes begin'], daysBefore: 0),
          en,
        ).lead,
        'Today',
      );
    });

    test('one day ahead reads as "tomorrow"', () {
      expect(
        ReminderNotificationText.from(
          reminder(names: ['上課開始'], daysBefore: 1),
          zh,
        ).lead,
        '明天',
      );
      expect(
        ReminderNotificationText.from(
          reminder(names: ['Classes begin'], daysBefore: 1),
          en,
        ).lead,
        'Tomorrow',
      );
    });

    test('two or more days ahead counts the days', () {
      expect(
        ReminderNotificationText.from(
          reminder(names: ['上課開始'], daysBefore: 3),
          zh,
        ).lead,
        '3 天後',
      );
      expect(
        ReminderNotificationText.from(
          reminder(names: ['Classes begin'], daysBefore: 7),
          en,
        ).lead,
        'In 7 days',
      );
    });

    test('the lead time never leaks into the body', () {
      final text = ReminderNotificationText.from(
        reminder(names: ['上課開始'], daysBefore: 3),
        zh,
      );

      expect(text.expanded.contains('天後'), isFalse);
      expect(text.collapsed.contains('天後'), isFalse);
    });
  });
}
