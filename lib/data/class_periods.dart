/// 上課節次與其起訖時刻——全 App 唯一的一份定義。
///
/// 課表頁、總覽頁的「下一堂課」、以及課綱加入行事曆算事件起訖時間，都讀這裡。
/// 之前課表頁與總覽頁各存了一份一模一樣的複本，改一邊忘另一邊時兩頁會顯示
/// 不同的時間，而且不會有任何錯誤提示。
library;

/// 單一節次：代碼與起訖時刻。
class ClassPeriod {
  /// 節次代碼（`X`／`A`／`B`…）。
  final String code;

  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  const ClassPeriod(
    this.code,
    this.startHour,
    this.startMinute,
    this.endHour,
    this.endMinute,
  );

  /// 起／訖時刻換算成當日的分鐘數，供「現在上到哪一堂」之類的比較使用。
  int get startMinutes => startHour * 60 + startMinute;
  int get endMinutes => endHour * 60 + endMinute;

  /// `08:10`
  String get startText => _hhmm(startHour, startMinute);

  /// `09:00`
  String get endText => _hhmm(endHour, endMinute);

  /// `08:10 - 09:00`
  String get rangeText => '$startText - $endText';

  static String _hhmm(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// 節次時刻表。
class ClassPeriods {
  ClassPeriods._();

  /// 依上課先後排序的完整節次。順序本身是有意義的：課表格線的列序、
  /// 以及「連續節次」的判斷都以它為準。
  static const List<ClassPeriod> all = [
    ClassPeriod('X', 7, 10, 8, 0),
    ClassPeriod('A', 8, 10, 9, 0),
    ClassPeriod('B', 9, 10, 10, 0),
    ClassPeriod('C', 10, 10, 11, 0),
    ClassPeriod('D', 11, 10, 12, 0),
    ClassPeriod('Y', 12, 10, 13, 0),
    ClassPeriod('E', 13, 10, 14, 0),
    ClassPeriod('F', 14, 10, 15, 0),
    ClassPeriod('G', 15, 10, 16, 0),
    ClassPeriod('H', 16, 10, 17, 0),
    ClassPeriod('Z', 17, 10, 18, 0),
    ClassPeriod('I', 18, 25, 19, 15),
    ClassPeriod('J', 19, 20, 20, 10),
    ClassPeriod('K', 20, 15, 21, 5),
    ClassPeriod('L', 21, 10, 22, 0),
  ];

  /// 依序的節次代碼。
  static final List<String> codes = List.unmodifiable([
    for (final period in all) period.code,
  ]);

  static final Map<String, ClassPeriod> _byCode = {
    for (final period in all) period.code: period,
  };

  /// 查一個節次；未知代碼回 `null`。
  static ClassPeriod? byCode(String code) => _byCode[code];

  /// 節次在 [all] 中的順序；未知代碼回 `-1`。用來判斷兩節是否相鄰。
  static int indexOf(String code) => codes.indexOf(code);

  /// `08:10 - 09:00`；未知代碼回空字串。
  static String rangeText(String code) => byCode(code)?.rangeText ?? '';
}
