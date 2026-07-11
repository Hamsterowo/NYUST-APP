import 'package:flutter_test/flutter_test.dart';
import 'package:yun_tool/utils/clock_drift.dart';

void main() {
  group('parseHttpDate', () {
    test('parses a well-formed RFC 1123 Date header to UTC', () {
      final parsed = parseHttpDate('Wed, 21 Oct 2015 07:28:00 GMT');
      expect(parsed, isNotNull);
      expect(parsed!.isUtc, isTrue);
      expect(parsed, DateTime.utc(2015, 10, 21, 7, 28, 0));
    });

    test('round-trips a freshly formatted header', () {
      final serverUtc = DateTime.now().toUtc().subtract(
        const Duration(hours: 1),
      );
      final parsed = parseHttpDate(_formatHttpDate(serverUtc));
      expect(parsed, isNotNull);
      // 秒級精度（header 不含毫秒），允許 1 秒內誤差。
      expect(
        parsed!.difference(serverUtc).inSeconds.abs(),
        lessThanOrEqualTo(1),
      );
    });

    test('returns null for unparseable input', () {
      expect(parseHttpDate('not a date'), isNull);
      expect(parseHttpDate(''), isNull);
      expect(parseHttpDate('   '), isNull);
    });
  });
}

/// 產生 RFC 1123 格式的 Date header 字串（UTC / GMT）。
String _formatHttpDate(DateTime utc) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  String two(int n) => n.toString().padLeft(2, '0');
  final d = days[utc.weekday - 1];
  final m = months[utc.month - 1];
  return '$d, ${two(utc.day)} $m ${utc.year} '
      '${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)} GMT';
}
