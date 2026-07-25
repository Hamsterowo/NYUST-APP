import 'dart:math';

import '../models/schedule_event.dart';

/// 課表格線中的一格。
///
/// [event] 為 null 代表該格沒有課。[span] 是這門課往下連續佔用的節數
/// （跨節合併後的高度），沒課時固定為 1。
class TimetableCell {
  final ScheduleEvent? event;
  final int span;

  const TimetableCell({required this.event, required this.span});

  bool get isEmpty => event == null;
}

/// 課表的排版結果：純粹由課程資料算出「哪幾天、哪幾節、每一格放什麼」，
/// 不碰 widget、不碰時鐘、不碰尺寸。畫面只負責把它畫出來。
///
/// 之所以回傳單一值物件而非數個純函式：串接邏輯（掃描節次、累加 span、
/// 組出每一欄）本身就是這裡最容易出錯的部分，留在畫面裡就等於沒有搬。
class TimetableLayout {
  /// 要顯示的星期欄（0 = 週一）。
  final List<int> dayIndices;

  /// 要顯示的節次代碼（依序）。
  final List<String> periods;

  /// 課程名稱去重後排序，供畫面決定配色。
  final List<String> courseNames;

  /// 與 [dayIndices] 等長且同序的每日格子。
  final List<List<TimetableCell>> columns;

  const TimetableLayout({
    required this.dayIndices,
    required this.periods,
    required this.courseNames,
    required this.columns,
  });

  /// 取得某個星期欄（0 = 週一）的格子。該日不在 [dayIndices] 內時回傳空清單。
  List<TimetableCell> column(int dayIndex) {
    final i = dayIndices.indexOf(dayIndex);
    return i == -1 ? const [] : columns[i];
  }

  /// 由課程算出排版。[allPeriods] 為完整節次代碼清單（如 X/A/B/…）。
  ///
  /// 格線範圍有刻意的下限：**至少**顯示週一到週五、**至少**顯示到第 8 個節次索引，
  /// 只有當課程落在該範圍之外時才往外擴。
  factory TimetableLayout.from(
    List<ScheduleEvent> courses, {
    required List<String> allPeriods,
  }) {
    final courseNames =
        courses
            .map((c) => c.name)
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    int minDayIndex = 0;
    int maxDayIndex = 4;
    int minPeriodIndex = 1;
    int maxPeriodIndex = 9;

    if (courses.isNotEmpty) {
      int minDay = 6;
      int maxDay = 0;
      int minP = allPeriods.length;
      int maxP = 0;
      bool hasClass = false;

      for (final course in courses) {
        if (course.name.isEmpty) continue;
        hasClass = true;
        final d = int.tryParse(course.weekday ?? '') ?? 1;
        final dIndex = d - 1;
        if (dIndex < minDay) minDay = dIndex;
        if (dIndex > maxDay) maxDay = dIndex;

        for (final t in course.times) {
          final pIndex = allPeriods.indexOf(t);
          if (pIndex != -1) {
            if (pIndex < minP) minP = pIndex;
            if (pIndex > maxP) maxP = pIndex;
          }
        }
      }

      if (hasClass) {
        minDayIndex = min(minDay, 0).clamp(0, 6);
        maxDayIndex = max(maxDay, 4).clamp(minDayIndex, 6);
        minPeriodIndex = min(minP, 1).clamp(0, allPeriods.length - 1);
        maxPeriodIndex = max(
          maxP,
          8,
        ).clamp(minPeriodIndex, allPeriods.length - 1);
      }
    }

    final dayIndices = List.generate(
      maxDayIndex - minDayIndex + 1,
      (i) => minDayIndex + i,
    );
    final periods = allPeriods.sublist(minPeriodIndex, maxPeriodIndex + 1);

    final columns = dayIndices
        .map((day) => _buildColumn(courses, day, periods))
        .toList();

    return TimetableLayout(
      dayIndices: dayIndices,
      periods: periods,
      courseNames: courseNames,
      columns: columns,
    );
  }

  /// 找出某天某節的課。同一格有多門課時**第一門勝出**（沿用既有行為：
  /// 衝堂的第二門不會被顯示，也不會有任何提示）。無課回傳 null。
  static ScheduleEvent? _eventAt(
    List<ScheduleEvent> courses,
    int dayIndex,
    String period,
  ) {
    final weekdayStr = (dayIndex + 1).toString();
    for (final c in courses) {
      if (c.name.isNotEmpty &&
          c.weekday == weekdayStr &&
          c.times.contains(period)) {
        return c;
      }
    }
    return null;
  }

  /// 掃描一整欄，把連續同一門課的節次合併成一格（span > 1）。
  static List<TimetableCell> _buildColumn(
    List<ScheduleEvent> courses,
    int dayIndex,
    List<String> periods,
  ) {
    final cells = <TimetableCell>[];

    for (int i = 0; i < periods.length; i++) {
      final event = _eventAt(courses, dayIndex, periods[i]);

      int span = 1;
      if (event != null) {
        while (i + span < periods.length) {
          final next = _eventAt(courses, dayIndex, periods[i + span]);
          if (next != null &&
              next.name == event.name &&
              next.semesterCourseNo == event.semesterCourseNo) {
            span++;
          } else {
            break;
          }
        }
      }

      cells.add(TimetableCell(event: event, span: span));
      i += span - 1;
    }

    return cells;
  }
}
