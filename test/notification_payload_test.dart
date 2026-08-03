import 'package:flutter_test/flutter_test.dart';
import 'package:yun_tool/services/notification_payload.dart';

/// Locks ticket 07: the payload a notification carries is a typed, extensible
/// record rather than one more hardcoded string comparison, and it still reads
/// the format shipped before it.
void main() {
  group('round trip', () {
    test('a grades payload survives encode and decode', () {
      const payload = NotificationPayload(type: NotificationPayload.typeGrades);
      final decoded = NotificationPayload.decode(payload.encode())!;

      expect(decoded.type, NotificationPayload.typeGrades);
      expect(decoded.date, isNull);
    });

    test('a calendar payload keeps the day it points at', () {
      final payload = NotificationPayload(
        type: NotificationPayload.typeCalendar,
        date: DateTime(2026, 9, 7),
      );
      final decoded = NotificationPayload.decode(payload.encode())!;

      expect(decoded.type, NotificationPayload.typeCalendar);
      expect(decoded.date, DateTime(2026, 9, 7));
    });

    test('the date is encoded as a plain calendar day, not an instant', () {
      final payload = NotificationPayload(
        type: NotificationPayload.typeCalendar,
        date: DateTime(2026, 1, 3),
      );

      expect(payload.encode(), contains('"date":"2026-01-03"'));
    });
  });

  group('backward compatibility', () {
    test('the bare "grades" string shipped before still decodes', () {
      final decoded = NotificationPayload.decode('grades')!;

      expect(decoded.type, NotificationPayload.typeGrades);
      expect(decoded.date, isNull);
    });
  });

  group('extensibility', () {
    test('an unknown type is preserved rather than rejected', () {
      // A payload written by a newer build must survive the trip; deciding
      // what to do with it belongs to the navigation layer, not the parser.
      final decoded = NotificationPayload.decode('{"type":"something-new"}')!;

      expect(decoded.type, 'something-new');
    });

    test('an unrecognised extra field does not break parsing', () {
      final decoded = NotificationPayload.decode(
        '{"type":"calendar","date":"2026-09-07","extra":42}',
      )!;

      expect(decoded.type, NotificationPayload.typeCalendar);
      expect(decoded.date, DateTime(2026, 9, 7));
    });
  });

  group('malformed input', () {
    test('null and empty decode to nothing', () {
      expect(NotificationPayload.decode(null), isNull);
      expect(NotificationPayload.decode(''), isNull);
    });

    test('non-JSON decodes to nothing rather than throwing', () {
      expect(NotificationPayload.decode('not json at all'), isNull);
    });

    test('JSON that is not an object decodes to nothing', () {
      expect(NotificationPayload.decode('[1,2,3]'), isNull);
      expect(NotificationPayload.decode('"grades"'), isNull);
    });

    test('a missing or empty type decodes to nothing', () {
      expect(NotificationPayload.decode('{"date":"2026-09-07"}'), isNull);
      expect(NotificationPayload.decode('{"type":""}'), isNull);
      expect(NotificationPayload.decode('{"type":7}'), isNull);
    });

    test('an unusable date leaves the type intact and the date empty', () {
      final decoded = NotificationPayload.decode(
        '{"type":"calendar","date":"tomorrow-ish"}',
      )!;

      expect(decoded.type, NotificationPayload.typeCalendar);
      expect(decoded.date, isNull);
    });
  });
}
