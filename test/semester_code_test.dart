import 'package:flutter_test/flutter_test.dart';
import 'package:yun_tool/utils/semester_code.dart';

void main() {
  group('semesterCodeOf', () {
    test('學年與學期併成一個數', () {
      expect(semesterCodeOf(year: '114', semester: '2'), 1142);
      expect(semesterCodeOf(year: '114', semester: '1'), 1141);
      expect(semesterCodeOf(year: '113', semester: '2'), 1132);
    });

    test('三碼學年也算得出來', () {
      expect(semesterCodeOf(year: '99', semester: '2'), 992);
    });

    test('頭尾空白不影響', () {
      expect(semesterCodeOf(year: ' 114 ', semester: ' 2 '), 1142);
    });

    test('不成形時回 null', () {
      expect(semesterCodeOf(year: '', semester: '2'), isNull);
      expect(semesterCodeOf(year: '114', semester: ''), isNull);
      expect(semesterCodeOf(year: 'abc', semester: '2'), isNull);
    });
  });

  group('isSemesterBefore', () {
    bool before(String year, String semester, String? current) =>
        isSemesterBefore(
          year: year,
          semester: semester,
          currentSemester: current,
        );

    test('比當前早的學期會被擋', () {
      expect(before('113', '2', '1142'), isTrue);
      expect(before('114', '1', '1142'), isTrue);
      expect(before('112', '1', '1142'), isTrue);
    });

    test('當前學期本身不算早', () {
      expect(before('114', '2', '1142'), isFalse);
    });

    test('未來學期不算早 —— 下學期的課排進行事曆是合理的', () {
      expect(before('115', '1', '1142'), isFalse);
      expect(before('115', '2', '1142'), isFalse);
    });

    test('三碼學年不會因為字串長度較短而被判成比較大', () {
      // 逐字比字串的話 '992' > '1142'，會把 99 學年判成未來學期。
      expect(before('99', '2', '1142'), isTrue);
      expect(before('114', '2', '992'), isFalse);
    });

    test('還不知道當前學期時放行', () {
      expect(before('113', '2', null), isFalse);
      expect(before('113', '2', ''), isFalse);
      expect(before('113', '2', 'abc'), isFalse);
    });

    test('課程本身的學年學期壞掉時放行，不會靜靜藏掉按鈕', () {
      expect(before('', '2', '1142'), isFalse);
      expect(before('114', '', '1142'), isFalse);
    });

    test('跨學年的相鄰兩期順序正確', () {
      // 114-2 的下一期是 115-1，不是 114-3。
      expect(before('114', '2', '1151'), isTrue);
      expect(before('115', '1', '1142'), isFalse);
    });
  });
}
