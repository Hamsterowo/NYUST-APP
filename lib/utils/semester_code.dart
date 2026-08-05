/// 學期代碼（`1142` = 114 學年第 2 學期）的比較。
library;

/// 把學年與學期併成一個可比較的數值；任一項不成形時回 `null`。
///
/// **必須用數值比較，不能逐字比字串。** 民國 99 學年的代碼是三碼的 `992`，
/// 逐字比會判成大於四碼的 `1142`，整個順序反過來。
int? semesterCodeOf({required String year, required String semester}) {
  final rocYear = int.tryParse(year.trim());
  final term = int.tryParse(semester.trim());
  if (rocYear == null || term == null) return null;
  return rocYear * 10 + term;
}

/// [year]／[semester] 這個學期是否**早於** [currentSemester]。
///
/// 用來收窄「課綱單週加入行事曆」的範圍：已經過去的學期不需要這個功能，從歷年
/// 成績點進舊課程時那顆按鈕只會是誤觸來源。
///
/// **未來學期不算早**，所以不會被擋 —— 下學期的課排進行事曆是合理的需求，而且
/// 校曆若還沒公布，錨點推導本來就會讓按鈕停用。
///
/// [currentSemester] 為 `null` 或不成形時回 `false`（**先放行**）：那代表課表
/// 資料還沒到（離線冷啟動、或還沒抓完就直接點進課程），不是「這是舊學期」。
/// 寧可短暫多顯示一顆按鈕，也不要讓主要情境在啟動那幾秒是壞的；值到了之後
/// `DataProvider` 會通知重畫，自然修正。
bool isSemesterBefore({
  required String year,
  required String semester,
  required String? currentSemester,
}) {
  if (currentSemester == null) return false;
  final current = int.tryParse(currentSemester.trim());
  final code = semesterCodeOf(year: year, semester: semester);
  if (current == null || code == null) return false;
  return code < current;
}
