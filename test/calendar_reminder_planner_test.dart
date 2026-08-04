import 'package:flutter_test/flutter_test.dart';
import 'package:yun_tool/models/calendar_event.dart';
import 'package:yun_tool/utils/calendar_reminder_planner.dart';

/// Locks ticket 02: every decision the calendar-reminder feature can get wrong
/// lives in this pure module, so it is exercised without building a widget and
/// without touching the network or storage.
///
/// Event names below are real strings from the YunTech calendar, including the
/// known spelling drift between years.
void main() {
  var nextId = 0;

  /// The scraper's ids look like `<eventdatetime_id>-<index>`; only their
  /// stability matters here, so they are generated unless a test pins one.
  CalendarEvent event(String date, String name, {String? id}) => CalendarEvent(
    id: id ?? 'e${nextId++}-0',
    date: date,
    name: name,
    link: '',
  );

  setUp(() => nextId = 0);

  const allCategories = {
    ReminderCategory.courseSelection,
    ReminderCategory.exam,
    ReminderCategory.registration,
    ReminderCategory.semester,
  };

  const dayBefore8am = ReminderRule(daysBefore: 1, hour: 8, minute: 0);

  List<PlannedReminder> plan(
    List<CalendarEvent> events, {
    Set<ReminderCategory> categories = allCategories,
    List<ReminderRule> rules = const [dayBefore8am],
    DateTime? now,
    int limit = 64,
    List<CalendarEvent>? displayEvents,
  }) => CalendarReminderPlanner.plan(
    events: events,
    categories: categories,
    rules: rules,
    now: now ?? DateTime(2026, 1, 1),
    limit: limit,
    displayEvents: displayEvents,
  );

  group('name normalisation', () {
    test('full-width brackets, quotes and commas become half-width', () {
      expect(CalendarReminderPlanner.normalizeName('截止（含校際選課）'), '截止(含校際選課)');
      expect(CalendarReminderPlanner.normalizeName('「試辦」，、'), '｢試辦｣,､');
    });

    test('every kind of whitespace is removed', () {
      expect(CalendarReminderPlanner.normalizeName('學雜費 減免'), '學雜費減免');
      expect(CalendarReminderPlanner.normalizeName('學雜費\t減免　申請'), '學雜費減免申請');
    });

    test('half-width input is already normalised and stays put', () {
      expect(CalendarReminderPlanner.normalizeName('截止(含校際選課)'), '截止(含校際選課)');
    });

    test('the two written forms of one event normalise to the same string', () {
      expect(
        CalendarReminderPlanner.normalizeName('全校加退選截止（含校際選課）'),
        CalendarReminderPlanner.normalizeName('全校加退選截止(含校際選課)'),
      );
    });
  });

  group('category matching', () {
    bool inCategory(String name, ReminderCategory category) =>
        CalendarReminderPlanner.matchesAny(name, {category});

    test('course selection covers 預選 / 加退選 / 退選', () {
      expect(inCategory('第1次預選開始', ReminderCategory.courseSelection), isTrue);
      expect(inCategory('全校加退選開始', ReminderCategory.courseSelection), isTrue);
      expect(
        inCategory('全校加退選截止（含校際選課）', ReminderCategory.courseSelection),
        isTrue,
      );
      expect(
        inCategory('期中考後停修(退選)截止', ReminderCategory.courseSelection),
        isTrue,
      );
      expect(inCategory('上課開始', ReminderCategory.courseSelection), isFalse);
    });

    test('exams cover 期中考 and 學期考試 — there is no 期末考 string', () {
      expect(inCategory('期中考開始', ReminderCategory.exam), isTrue);
      // Same event, different year's wording.
      expect(inCategory('期中考試開始', ReminderCategory.exam), isTrue);
      expect(inCategory('學期考試開始', ReminderCategory.exam), isTrue);
      expect(inCategory('學期考試結束', ReminderCategory.exam), isTrue);
      expect(inCategory('期末考開始', ReminderCategory.exam), isFalse);
    });

    test(
      '退選 excludes an event from exams but keeps it in course selection',
      () {
        const name = '期中考後停修(退選)截止';
        expect(inCategory(name, ReminderCategory.exam), isFalse);
        expect(inCategory(name, ReminderCategory.courseSelection), isTrue);
      },
    );

    test('registration covers 註冊 / 學雜費 / 就學貸款 / 退費', () {
      expect(inCategory('第1學期註冊', ReminderCategory.registration), isTrue);
      expect(inCategory('學雜費繳費截止日', ReminderCategory.registration), isTrue);
      expect(inCategory('就學貸款申請開始', ReminderCategory.registration), isTrue);
      expect(inCategory('學雜費退費截止日', ReminderCategory.registration), isTrue);
    });

    test('減免 excludes the fee-waiver rounds from registration', () {
      expect(inCategory('學雜費減免申請開始', ReminderCategory.registration), isFalse);
      // Drift: this one has a stray space in the middle.
      expect(
        inCategory('學雜費 減免第2梯次申請截止', ReminderCategory.registration),
        isFalse,
      );
    });

    test('減免 does not catch 免學雜費, which is a real registration event', () {
      expect(
        inCategory('學生辦休退學免學雜費截止日', ReminderCategory.registration),
        isTrue,
      );
    });

    test('semester bounds cover the four start/end strings plus vacations', () {
      expect(inCategory('第1學期開始', ReminderCategory.semester), isTrue);
      expect(inCategory('第1學期結束', ReminderCategory.semester), isTrue);
      expect(inCategory('上課開始', ReminderCategory.semester), isTrue);
      expect(inCategory('寒假開始', ReminderCategory.semester), isTrue);
      expect(inCategory('暑假結束', ReminderCategory.semester), isTrue);
      expect(inCategory('第1次預選開始', ReminderCategory.semester), isFalse);
    });

    test('an unrelated event belongs to no category at all', () {
      expect(
        CalendarReminderPlanner.matchesAny('校慶運動會', allCategories),
        isFalse,
      );
    });

    test('no subscribed categories means nothing matches', () {
      expect(CalendarReminderPlanner.matchesAny('第1次預選開始', {}), isFalse);
    });
  });

  group('subscription filtering', () {
    test('only events hit by a subscribed category are planned', () {
      final result = plan(
        [
          event('2026-09-01', '第1次預選開始'),
          event('2026-09-08', '期中考開始'),
          event('2026-09-15', '校慶運動會'),
        ],
        categories: {ReminderCategory.courseSelection},
      );

      expect(result, hasLength(1));
      expect(result.single.eventNames, ['第1次預選開始']);
    });

    test('no categories at all produces nothing', () {
      final result = plan([event('2026-09-01', '第1次預選開始')], categories: {});
      expect(result, isEmpty);
    });

    test('an empty reminder list produces nothing', () {
      final result = plan([event('2026-09-01', '第1次預選開始')], rules: const []);
      expect(result, isEmpty);
    });
  });

  group('same-day merging and de-duplication', () {
    test('several events on one day become a single notification', () {
      final result = plan([
        event('2026-09-07', '上課開始'),
        event('2026-09-07', '第1學期開始'),
        event('2026-09-07', '全校加退選開始'),
      ]);

      expect(result, hasLength(1));
      expect(result.single.eventNames, ['上課開始', '第1學期開始', '全校加退選開始']);
    });

    test('an event hit by two categories still appears once', () {
      // 註冊 (registration) and 加退選 (course selection) both hit this string.
      final result = plan([event('2026-09-07', '註冊、加退選截止')]);

      expect(result, hasLength(1));
      expect(result.single.eventNames, ['註冊、加退選截止']);
    });

    test('the same event id repeated in the feed is counted once', () {
      final result = plan([
        event('2026-09-07', '上課開始', id: '12345-0'),
        event('2026-09-07', '上課開始', id: '12345-0'),
      ]);

      expect(result.single.eventNames, ['上課開始']);
    });

    test('different days stay in separate notifications', () {
      final result = plan([
        event('2026-09-07', '上課開始'),
        event('2026-09-08', '全校加退選開始'),
      ]);

      expect(result, hasLength(2));
      expect(result.map((r) => r.eventNames.single), ['上課開始', '全校加退選開始']);
    });
  });

  group('reminder rules', () {
    test('each rule expands into its own notification per event day', () {
      final result = plan(
        [event('2026-09-07', '上課開始')],
        rules: const [
          ReminderRule(daysBefore: 7, hour: 9, minute: 0),
          ReminderRule(daysBefore: 1, hour: 8, minute: 0),
          ReminderRule(daysBefore: 0, hour: 8, minute: 0),
        ],
      );

      expect(result.map((r) => r.triggerTime), [
        DateTime(2026, 8, 31, 9, 0),
        DateTime(2026, 9, 6, 8, 0),
        DateTime(2026, 9, 7, 8, 0),
      ]);
      expect(result.map((r) => r.daysBefore), [7, 1, 0]);
    });

    test('every planned reminder carries the event day it belongs to', () {
      final result = plan([event('2026-09-07', '上課開始')]);
      expect(result.single.eventDate, DateTime(2026, 9, 7));
    });

    test('day arithmetic crosses a month and a year boundary correctly', () {
      final result = plan(
        [event('2027-01-03', '寒假開始')],
        rules: const [ReminderRule(daysBefore: 7, hour: 8, minute: 0)],
      );

      expect(result.single.triggerTime, DateTime(2026, 12, 27, 8, 0));
    });

    test('a rule pointing after the event is rejected as invalid', () {
      final result = plan(
        [event('2026-09-07', '上課開始')],
        rules: const [ReminderRule(daysBefore: -1, hour: 8, minute: 0)],
      );

      expect(result, isEmpty);
    });

    test('an out-of-range time of day is rejected as invalid', () {
      final result = plan(
        [event('2026-09-07', '上課開始')],
        rules: const [ReminderRule(daysBefore: 1, hour: 24, minute: 0)],
      );

      expect(result, isEmpty);
    });

    test('invalid rules are dropped without taking the valid ones down', () {
      final result = plan(
        [event('2026-09-07', '上課開始')],
        rules: const [
          ReminderRule(daysBefore: -3, hour: 8, minute: 0),
          dayBefore8am,
        ],
      );

      expect(result, hasLength(1));
      expect(result.single.triggerTime, DateTime(2026, 9, 6, 8, 0));
    });
  });

  group('past reminders', () {
    test('a trigger time already gone is not planned and not backfilled', () {
      final result = plan([
        event('2026-09-07', '上課開始'),
      ], now: DateTime(2026, 9, 6, 8, 1));

      expect(result, isEmpty);
    });

    test('a trigger time exactly now is treated as already gone', () {
      final result = plan([
        event('2026-09-07', '上課開始'),
      ], now: DateTime(2026, 9, 6, 8, 0));

      expect(result, isEmpty);
    });

    test('only the rules that have not fired yet survive', () {
      final result = plan(
        [event('2026-09-07', '上課開始')],
        rules: const [
          ReminderRule(daysBefore: 7, hour: 9, minute: 0),
          ReminderRule(daysBefore: 1, hour: 8, minute: 0),
        ],
        now: DateTime(2026, 9, 1),
      );

      expect(result, hasLength(1));
      expect(result.single.daysBefore, 1);
    });
  });

  group('ordering and truncation', () {
    test('results run from the nearest trigger to the furthest', () {
      final result = plan([
        event('2026-12-25', '寒假開始'),
        event('2026-09-07', '上課開始'),
        event('2026-11-02', '期中考開始'),
      ]);

      expect(result.map((r) => r.eventNames.single), ['上課開始', '期中考開始', '寒假開始']);
    });

    test('the list is cut to the caller-supplied limit', () {
      final result = plan([
        event('2026-09-07', '上課開始'),
        event('2026-11-02', '期中考開始'),
        event('2026-12-25', '寒假開始'),
      ], limit: 2);

      expect(result, hasLength(2));
      expect(result.map((r) => r.eventNames.single), ['上課開始', '期中考開始']);
    });

    test('a zero limit produces nothing', () {
      expect(plan([event('2026-09-07', '上課開始')], limit: 0), isEmpty);
    });

    test('two reminders landing on the same instant keep a stable order', () {
      final events = [
        event('2026-09-10', '第1次預選開始'),
        event('2026-09-04', '上課開始'),
      ];
      const rules = [
        ReminderRule(daysBefore: 7, hour: 8, minute: 0),
        ReminderRule(daysBefore: 1, hour: 8, minute: 0),
      ];

      final first = plan(events, rules: rules);
      final second = plan(events.reversed.toList(), rules: rules);

      // 9/10 D-7 and 9/4 D-1 both fire at 9/3 08:00.
      expect(first.map((r) => r.id), second.map((r) => r.id));
    });
  });

  group('notification ids', () {
    test('the same event day and rule always produce the same id', () {
      final a = CalendarReminderPlanner.notificationIdFor(
        DateTime(2026, 9, 7),
        dayBefore8am,
      );
      final b = CalendarReminderPlanner.notificationIdFor(
        DateTime(2026, 9, 7),
        const ReminderRule(daysBefore: 1, hour: 8, minute: 0),
      );

      expect(a, b);
    });

    test('a different day or a different rule produces a different id', () {
      final base = CalendarReminderPlanner.notificationIdFor(
        DateTime(2026, 9, 7),
        dayBefore8am,
      );

      expect(
        CalendarReminderPlanner.notificationIdFor(
          DateTime(2026, 9, 8),
          dayBefore8am,
        ),
        isNot(base),
      );
      expect(
        CalendarReminderPlanner.notificationIdFor(
          DateTime(2026, 9, 7),
          const ReminderRule(daysBefore: 2, hour: 8, minute: 0),
        ),
        isNot(base),
      );
      expect(
        CalendarReminderPlanner.notificationIdFor(
          DateTime(2026, 9, 7),
          const ReminderRule(daysBefore: 1, hour: 9, minute: 0),
        ),
        isNot(base),
      );
      expect(
        CalendarReminderPlanner.notificationIdFor(
          DateTime(2026, 9, 7),
          const ReminderRule(daysBefore: 1, hour: 8, minute: 30),
        ),
        isNot(base),
      );
    });

    test('ids stay inside the calendar namespace and fit a 32-bit int', () {
      final result = plan([
        event('2026-09-07', '上課開始'),
        event('2026-11-02', '期中考開始'),
      ]);

      for (final reminder in result) {
        expect(
          reminder.id & CalendarReminderPlanner.idNamespace,
          CalendarReminderPlanner.idNamespace,
        );
        expect(reminder.id, lessThan(0x7FFFFFFF));
      }
    });

    test('the id does not depend on which events fall on that day', () {
      final withOne = plan([event('2026-09-07', '上課開始')]);
      final withThree = plan([
        event('2026-09-07', '上課開始'),
        event('2026-09-07', '第1學期開始'),
        event('2026-09-07', '全校加退選開始'),
      ]);

      expect(withOne.single.id, withThree.single.id);
    });
  });

  group('display-language names', () {
    test('display names are matched by event id', () {
      final result = plan(
        [event('2026-09-07', '上課開始', id: '9001-0')],
        displayEvents: [event('2026-09-07', 'Classes begin', id: '9001-0')],
      );

      expect(result.single.eventNames, ['Classes begin']);
    });

    test('a Chinese item holding two clauses consumes two English pieces', () {
      // The scraper splits Chinese on ；but English on ", ", so 「上課開始，註冊」
      // stays one Chinese item while becoming two English ones. Pairing by
      // index alone would shift every later item onto the previous one's
      // translation.
      final result = plan(
        [
          event('2026-09-07', '上課開始，註冊', id: '10411-0'),
          event('2026-09-07', '全校加退選(網路選課)開始', id: '10411-1'),
        ],
        displayEvents: [
          event('2026-09-07', 'Spring semester classes begins', id: '10411-0'),
          event('2026-09-07', 'Enrollment', id: '10411-1'),
          event('2026-09-07', 'On-line course add/drop begins', id: '10411-2'),
        ],
      );

      expect(result.single.eventNames, [
        'Spring semester classes begins, Enrollment',
        'On-line course add/drop begins',
      ]);
    });

    test('an ideographic comma is not a split point', () {
      // 「輔系、雙主修、抵免申請」 is one item in both languages — English does
      // not split there, so counting 、 would make the group fail to line up.
      final result = plan(
        [
          event('2026-09-07', '上課開始', id: '10411-0'),
          event('2026-09-07', '註冊、加退選截止', id: '10411-1'),
        ],
        displayEvents: [
          event('2026-09-07', 'Classes begin', id: '10411-0'),
          event(
            '2026-09-07',
            'Enrollment, course add/drop deadline',
            id: '10411-1',
          ),
        ],
      );

      expect(result.single.eventNames, [
        'Classes begin',
        'Enrollment, course add/drop deadline',
      ]);
    });

    test('a group whose pieces do not add up falls back entirely', () {
      // The English feed merged two items, so nothing in this group lines up —
      // showing Chinese beats showing the previous event's translation.
      final result = plan(
        [
          event('2026-09-07', '第2學期結束', id: '10461-0'),
          event('2026-09-07', '學期考試結束', id: '10461-1'),
          event('2026-09-07', '暑假開始', id: '10461-2'),
        ],
        displayEvents: [
          event('2026-09-07', 'End of the spring semester', id: '10461-0'),
          event(
            '2026-09-07',
            'Exams ends.Summer vacation begins.',
            id: '10461-1',
          ),
        ],
      );

      expect(result.single.eventNames, ['第2學期結束', '學期考試結束', '暑假開始']);
    });

    test(
      'a full-width comma the English feed did not split still lines up',
      () {
        // 「…截止日，日後不予退費」 is one item in both languages — English keeps
        // it as a single sentence. The fixed rule counts the comma and expects
        // two pieces, so only the search layer can resolve this one.
        final result = plan(
          [event('2026-09-07', '學生辦休退學學雜費退1/3截止日，日後不予退費', id: '10374-0')],
          displayEvents: [
            event(
              '2026-09-07',
              'Reimbursement of 1/3 tuition/miscellaneous fees for '
                  'suspended/dropout students ends.',
              id: '10374-0',
            ),
          ],
        );

        expect(result.single.eventNames, [
          'Reimbursement of 1/3 tuition/miscellaneous fees for '
              'suspended/dropout students ends.',
        ]);
      },
    );

    test('an ideographic comma the English feed did split still lines up', () {
      // The mirror image of the test above: here 「、」 *is* a split point in
      // English, which the fixed rule refuses to consider.
      final result = plan(
        [
          event('2026-09-07', '國際新生報到', id: '10337-0'),
          event('2026-09-07', '註冊、加退選開始', id: '10337-1'),
        ],
        displayEvents: [
          event(
            '2026-09-07',
            'New international students check in',
            id: '10337-0',
          ),
          event('2026-09-07', 'Enrollment', id: '10337-1'),
          event('2026-09-07', 'Course add/drop begins', id: '10337-2'),
        ],
      );

      // 只有第二筆命中分類；它必須吃掉兩個英文片段才是對的。
      expect(result.single.eventNames, ['Enrollment, Course add/drop begins']);
    });

    test('a group with more than one possible split falls back to Chinese', () {
      // Two items, each holding one 、, and three English pieces: either item
      // could be the one that was split. Guessing would be a coin flip, and a
      // wrong English name reads as authoritative in a way Chinese does not.
      final result = plan(
        [
          event('2026-09-07', '寒假結束、宿舍入住', id: '10037-0'),
          event('2026-09-07', '註冊、加退選開始', id: '10037-1'),
        ],
        displayEvents: [
          event('2026-09-07', 'Winter vacation ends', id: '10037-0'),
          event('2026-09-07', 'Dormitory check-in', id: '10037-1'),
          event('2026-09-07', 'Enrollment, add/drop begins', id: '10037-2'),
        ],
      );

      expect(result.single.eventNames, ['寒假結束、宿舍入住', '註冊、加退選開始']);
    });

    test('one group falling back does not affect another that lines up', () {
      final result = plan(
        [
          event('2026-09-07', '上課開始', id: '10411-0'),
          event('2026-09-08', '寒假結束', id: '10037-0'),
          event('2026-09-08', '暑假開始', id: '10037-1'),
        ],
        displayEvents: [
          event('2026-09-07', 'Classes begin', id: '10411-0'),
          event('2026-09-08', 'Winter vacation ends', id: '10037-0'),
        ],
      );

      expect(result.first.eventNames, ['Classes begin']);
      expect(result.last.eventNames, ['寒假結束', '暑假開始']);
    });

    test('a group missing from the display feed falls back to Chinese', () {
      final result = plan(
        [event('2026-09-07', '上課開始', id: '9001-0')],
        displayEvents: [event('2026-09-08', 'Something else', id: '9002-0')],
      );

      expect(result.single.eventNames, ['上課開始']);
    });

    test('no display feed at all leaves every name in Chinese', () {
      final result = plan([event('2026-09-07', '上課開始', id: '9001-0')]);
      expect(result.single.eventNames, ['上課開始']);
    });

    test('classification reads the Chinese feed, never the display one', () {
      // The English name contains none of the keywords; it must still be
      // planned, because the Chinese feed is what decides the category.
      final result = plan(
        [event('2026-09-07', '第1次預選開始', id: '9001-0')],
        categories: {ReminderCategory.courseSelection},
        displayEvents: [
          event('2026-09-07', 'Course pre-registration begins', id: '9001-0'),
        ],
      );

      expect(result.single.eventNames, ['Course pre-registration begins']);
    });
  });

  group('malformed input', () {
    test('an unparsable date is skipped without failing the whole batch', () {
      final result = plan([
        event('not-a-date', '上課開始'),
        event('2026-09-07', '全校加退選開始'),
      ]);

      expect(result, hasLength(1));
      expect(result.single.eventNames, ['全校加退選開始']);
    });

    test('an empty event feed produces nothing', () {
      expect(plan(const []), isEmpty);
    });
  });

  group('ReminderRule serialisation', () {
    test('a rule survives a round trip through JSON', () {
      const rule = ReminderRule(daysBefore: 3, hour: 9, minute: 30);
      expect(ReminderRule.fromJson(rule.toJson()), rule);
    });

    test('the default rule is one day before at 08:00', () {
      expect(ReminderRule.defaultRule.daysBefore, 1);
      expect(ReminderRule.defaultRule.hour, 8);
      expect(ReminderRule.defaultRule.minute, 0);
    });
  });

  group('ReminderRule.normalizeList', () {
    test('orders the list from the furthest ahead to the nearest', () {
      final result = ReminderRule.normalizeList(const [
        ReminderRule(daysBefore: 0, hour: 8, minute: 0),
        ReminderRule(daysBefore: 7, hour: 9, minute: 0),
        ReminderRule(daysBefore: 1, hour: 8, minute: 0),
      ]);

      expect(result.map((r) => r.daysBefore), [7, 1, 0]);
    });

    test('breaks a same-day tie by time of day', () {
      final result = ReminderRule.normalizeList(const [
        ReminderRule(daysBefore: 1, hour: 20, minute: 0),
        ReminderRule(daysBefore: 1, hour: 8, minute: 30),
        ReminderRule(daysBefore: 1, hour: 8, minute: 0),
      ]);

      expect(result.map((r) => '${r.hour}:${r.minute}'), [
        '8:0',
        '8:30',
        '20:0',
      ]);
    });

    test('drops duplicates, which would collide on the same id', () {
      final result = ReminderRule.normalizeList(const [
        ReminderRule(daysBefore: 1, hour: 8, minute: 0),
        ReminderRule(daysBefore: 1, hour: 8, minute: 0),
      ]);

      expect(result, hasLength(1));
    });

    test('drops rules pointing after the event or outside a day', () {
      final result = ReminderRule.normalizeList(const [
        ReminderRule(daysBefore: -1, hour: 8, minute: 0),
        ReminderRule(daysBefore: 1, hour: 24, minute: 0),
        ReminderRule(daysBefore: 1, hour: 8, minute: 60),
        ReminderRule(daysBefore: 1, hour: 8, minute: 0),
      ]);

      expect(result, [const ReminderRule(daysBefore: 1, hour: 8, minute: 0)]);
    });

    test('an empty list stays empty rather than falling back to a default', () {
      expect(ReminderRule.normalizeList(const []), isEmpty);
    });
  });
}
