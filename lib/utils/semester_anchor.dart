/// 把「學年學期 + 課綱的第 N 週」換算成實際日期。
///
/// 整個「課綱單週加入行事曆」功能的正確性幾乎都壓在這裡：算錯一次不會有任何
/// 錯誤訊息，只會在使用者的行事曆上出現一則日期不對的事件。所以這一層是純
/// 函式、不讀時鐘、不碰網路，完全由傳入的行事曆事件決定結果。
library;

import '../models/calendar_event.dart';

/// 學校行事曆上「實際開始上課」那一天的事件名稱。
///
/// **只認這一個，不放寬到「學期開始」** —— 後者是行政上的學期起日（第 1 學期
/// 是 8/1、第 2 學期是 2/1），放寬進去會抓到 8/1，整批課程歪掉六週。
const String _classStartKeyword = '上課開始';

/// 學年（民國）+ 學期 → 該學期上課開始所在的西元年。
///
/// 上學期（`1`）在學年當年的秋天：西元年 = 學年 + 1911。
/// 下學期（`2`）在隔年的春天：西元年 = 學年 + 1912。
///
/// 例：114 學年第 1 學期 → 2025 年秋；114 學年第 2 學期 → 2026 年春。
int? gregorianYearOf({required String year, required String semester}) {
  final rocYear = int.tryParse(year.trim());
  if (rocYear == null) return null;
  return switch (semester.trim()) {
    '1' => rocYear + 1911,
    '2' => rocYear + 1912,
    _ => null,
  };
}

/// 該學期的「上課開始」可能落在哪幾個月。
///
/// 這個限制不是保險，是**必要條件**：同一個西元年的行事曆裡會同時出現 2 月與
/// 9 月兩筆「上課開始」（春天那筆屬於前一學年的下學期，秋天那筆屬於新學年的
/// 上學期）。只靠年份挑會挑到其中隨便一筆，整批事件就差了半年。
List<int>? _monthsOf(String semester) => switch (semester.trim()) {
  '1' => const [8, 9, 10],
  '2' => const [1, 2, 3],
  _ => null,
};

/// 從行事曆找出該學期實際上課的第一天；找不到回 `null`。
///
/// [events] 必須是**中文**行事曆 —— 判斷依據是中文事件名稱，與 UI 語言無關。
///
/// 同一學期若有多筆命中（學校偶爾會在同一格裡把「上課開始」與別的事寫在一起，
/// 切分後就成了多筆），取**最早**那一筆：上課開始的定義就是第一天。
DateTime? findClassStart(
  List<CalendarEvent> events, {
  required String year,
  required String semester,
}) {
  final gregorianYear = gregorianYearOf(year: year, semester: semester);
  final months = _monthsOf(semester);
  if (gregorianYear == null || months == null) return null;

  DateTime? earliest;
  for (final event in events) {
    if (!event.name.contains(_classStartKeyword)) continue;

    final DateTime date;
    try {
      date = event.getDateTime();
    } catch (_) {
      continue; // 日期壞掉的事件跳過，不讓整批推導失敗。
    }

    if (date.year != gregorianYear) continue;
    if (!months.contains(date.month)) continue;

    if (earliest == null || date.isBefore(earliest)) earliest = date;
  }
  return earliest == null
      ? null
      : DateTime(earliest.year, earliest.month, earliest.day);
}

/// 第 1 週的週一 —— 也就是開學日**所在那一週**的週一。
///
/// 已知代價：開學日不是週一時，那一週的週一（甚至週二…）會落在開學前幾天，
/// 所以週一／週二的課第 1 週會算到開學之前。第 2 週起全部正確。這是刻意接受的
/// ——「沒有手動校正」比「多一個大部分人不會去調、調錯還更難發現的設定」好。
DateTime firstWeekMonday(DateTime classStart) => DateTime(
  classStart.year,
  classStart.month,
  classStart.day - (classStart.weekday - DateTime.monday),
);

/// 第 [week] 週、星期 [weekday]（1 = 週一）那一天。
///
/// 用 `DateTime` 建構子做日期加法而不是 `Duration` —— 跨月、跨年由它處理，
/// 也不會被日光節約時間的時數差影響（雖然台灣沒有，但相加的語意本來就該是
/// 「往後幾天」而不是「往後幾小時」）。
DateTime dateOfWeek(
  DateTime firstMonday, {
  required int week,
  required int weekday,
}) => DateTime(
  firstMonday.year,
  firstMonday.month,
  firstMonday.day + (week - 1) * 7 + (weekday - 1),
);
