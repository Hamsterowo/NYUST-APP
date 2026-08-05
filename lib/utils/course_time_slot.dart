/// 解析課綱頁的「上課時間/教室」，並把節次併成實際的上課區塊。
library;

import '../data/class_periods.dart';

/// 一段連續的上課時間：某一天、某一段連續節次、某一間教室。
///
/// 「連續」是以 [ClassPeriods.all] 的順序判斷的 —— 3、4 節相鄰所以併成一塊
/// （10:10–12:00），但同一天的 C、D 與 G、H 之間隔著別的節次，是兩塊。
class CourseTimeSlot {
  /// 1 = 週一。
  final int weekday;

  /// 這一塊涵蓋的節次代碼，依上課先後排序。
  final List<String> periods;

  final String room;

  const CourseTimeSlot({
    required this.weekday,
    required this.periods,
    required this.room,
  });

  ClassPeriod get _first => ClassPeriods.byCode(periods.first)!;
  ClassPeriod get _last => ClassPeriods.byCode(periods.last)!;

  int get startHour => _first.startHour;
  int get startMinute => _first.startMinute;
  int get endHour => _last.endHour;
  int get endMinute => _last.endMinute;

  /// `10:10 - 12:00`
  String get timeText => '${_first.startText} - ${_last.endText}';

  /// 這一塊在 [day] 當天的起始時刻。
  DateTime startOn(DateTime day) =>
      DateTime(day.year, day.month, day.day, startHour, startMinute);

  /// 這一塊在 [day] 當天的結束時刻。
  DateTime endOn(DateTime day) =>
      DateTime(day.year, day.month, day.day, endHour, endMinute);

  @override
  bool operator ==(Object other) =>
      other is CourseTimeSlot &&
      other.weekday == weekday &&
      other.room == room &&
      other.periods.length == periods.length &&
      other.periods.every(periods.contains);

  @override
  int get hashCode => Object.hash(weekday, room, Object.hashAll(periods));

  @override
  String toString() => 'CourseTimeSlot($weekday, $periods, $room)';
}

/// 一個時段-教室項目，例如 `4-CDGH/EL108`。
final RegExp _entryPattern = RegExp(
  r'([1-7])\s*[-－]\s*([A-Za-z][A-Za-z,，、\s]*?)\s*/\s*([^\s,，、；;]+)',
);

/// 把課綱頁的「上課時間/教室」拆成實際的上課區塊。
///
/// 學校的寫法是 `星期-節次/教室`，多個時段以空白分隔，例如
/// `4-CD/EL108 4-GH/EL108 2-AB/EL205`。節次一般是連在一起的字母（`CD`），但
/// 也一併容忍中間有逗號或頓號的寫法。
///
/// **同一天內不連續的節次會拆成各自的區塊，跨天的也是。** 不能把同日不連續的
/// 節次併成一個大區塊 —— 那會把中間沒課的時間也一起佔掉，而且兩段可能在不同
/// 教室，併起來地點就是錯的。
///
/// 解析不出任何一段時回傳空清單，呼叫端據此停用按鈕。
List<CourseTimeSlot> parseCourseTimeRooms(String raw) {
  if (raw.trim().isEmpty) return const [];

  // 先照「星期 + 教室」收攏節次，再切連續段。之所以不逐項目各自切：同一天同一
  // 間教室被寫成兩個項目時（`1-AB/EL101 1-CD/EL101`），那其實是一整段連續的課，
  // 逐項目切會得到兩筆相鄰卻分開的事件。教室進分組鍵，不同教室就不會被併起來。
  final grouped = <({int weekday, String room}), List<String>>{};
  for (final match in _entryPattern.allMatches(raw)) {
    final key = (weekday: int.parse(match.group(1)!), room: match.group(3)!);

    // 節次是單一字母的序列；逗號、頓號與空白只是分隔，丟掉即可。
    final codes = match
        .group(2)!
        .toUpperCase()
        .replaceAll(RegExp(r'[,，、\s]'), '')
        .split('')
        .where((code) => ClassPeriods.byCode(code) != null);

    grouped.putIfAbsent(key, () => []).addAll(codes);
  }

  final slots = <CourseTimeSlot>[];
  grouped.forEach((key, codes) {
    // 一個項目的節次全是未知代碼時這裡會是空的 —— 不能往下走，`first` 會炸。
    // 該筆就是解析不出來，讓它不產生區塊，呼叫端據此停用按鈕。
    if (codes.isEmpty) return;

    // 去重並依上課先後排序後才切連續段，否則 `DC` 這種寫法會被當成兩塊。
    final sorted = codes.toSet().toList()
      ..sort(
        (a, b) => ClassPeriods.indexOf(a).compareTo(ClassPeriods.indexOf(b)),
      );

    var block = <String>[sorted.first];
    for (final code in sorted.skip(1)) {
      final isAdjacent =
          ClassPeriods.indexOf(code) == ClassPeriods.indexOf(block.last) + 1;
      if (isAdjacent) {
        block.add(code);
        continue;
      }
      slots.add(
        CourseTimeSlot(weekday: key.weekday, periods: block, room: key.room),
      );
      block = [code];
    }
    slots.add(
      CourseTimeSlot(weekday: key.weekday, periods: block, room: key.room),
    );
  });

  // 同一天內按時間先後、不同天按星期先後，確認面板才不會亂序。
  slots.sort((a, b) {
    final byDay = a.weekday.compareTo(b.weekday);
    if (byDay != 0) return byDay;
    return ClassPeriods.indexOf(
      a.periods.first,
    ).compareTo(ClassPeriods.indexOf(b.periods.first));
  });
  return slots;
}
