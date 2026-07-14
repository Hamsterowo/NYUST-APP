/// 一則成績異動：[title] 是通知標題（科目名或項目名，例如「微積分」「學期排名」），
/// [body] 是通知內文（變化內容，例如「成績更新：90 分」）。
class GradeChange {
  final String title;
  final String body;
  const GradeChange(this.title, this.body);
}

class GradesComparator {
  /// 比對新舊成績資料，回傳每個項目一則的異動清單。
  /// [oldData] 是先前的 `cache_grades` JSON Map
  /// [newData] 是新抓取的 `cache_grades` JSON Map
  /// [isEnglish] 控制回傳英文還是中文格式的訊息
  static List<GradeChange> compare(
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData, {
    bool isEnglish = false,
  }) {
    final List<GradeChange> changes = [];
    if (newData == null || newData['success'] != true) return changes;
    if (oldData == null || oldData['success'] != true) return changes;

    final oldSemesters = oldData['grades'] as List?;
    final newSemesters = newData['grades'] as List?;

    if (newSemesters == null) return changes;

    // 將舊學期清單整理成以 'academic_year-semester' 為 Key 的 Map，方便快速查詢
    final Map<String, Map<String, dynamic>> oldSemestersMap = {};
    if (oldSemesters != null) {
      for (var sem in oldSemesters) {
        if (sem is Map) {
          final year = sem['academic_year']?.toString() ?? '';
          final semester = sem['semester']?.toString() ?? '';
          if (year.isNotEmpty && semester.isNotEmpty) {
            oldSemestersMap['$year-$semester'] = Map<String, dynamic>.from(sem);
          }
        }
      }
    }

    for (var newSem in newSemesters) {
      if (newSem is! Map) continue;
      final year = newSem['academic_year']?.toString() ?? '';
      final semester = newSem['semester']?.toString() ?? '';
      if (year.isEmpty || semester.isEmpty) continue;

      final key = '$year-$semester';
      final oldSem = oldSemestersMap[key];

      if (oldSem == null) {
        // 全新學期：將所有科目當作新科目通知
        final newCourses = newSem['courses'] as List?;
        if (newCourses != null) {
          for (var course in newCourses) {
            if (course is Map) {
              final change = _courseChange(course, isEnglish);
              if (change != null) changes.add(change);
            }
          }
        }
      } else {
        // 已存在學期：比對科目分數
        final oldCourses = oldSem['courses'] as List?;
        final newCourses = newSem['courses'] as List?;

        final Map<String, Map<String, dynamic>> oldCoursesMap = {};
        if (oldCourses != null) {
          for (var c in oldCourses) {
            if (c is Map) {
              final code = c['code']?.toString() ?? '';
              if (code.isNotEmpty) {
                oldCoursesMap[code] = Map<String, dynamic>.from(c);
              }
            }
          }
        }

        if (newCourses != null) {
          for (var newCourse in newCourses) {
            if (newCourse is! Map) continue;
            final code = newCourse['code']?.toString() ?? '';
            if (code.isEmpty) continue;

            final oldCourse = oldCoursesMap[code];
            final oldScore = oldCourse?['score']?.toString() ?? '';
            final newScore = newCourse['score']?.toString() ?? '';

            // 新增科目，或分數有異動
            if (oldCourse == null || newScore != oldScore) {
              final change = _courseChange(newCourse, isEnglish);
              if (change != null) changes.add(change);
            }
          }
        }

        // 比對學期整體項目：排名、GPA、平均分數
        final oldSummary = oldSem['summary'] as Map?;
        final newSummary = newSem['summary'] as Map?;
        if (oldSummary != null && newSummary != null) {
          // 學期排名（rank 已是 "5 / 100" 格式）
          final newRank = newSummary['rank']?.toString() ?? '';
          if (newRank.isNotEmpty &&
              newRank != (oldSummary['rank']?.toString() ?? '')) {
            changes.add(
              GradeChange(
                isEnglish ? 'Semester Rank' : '學期排名',
                isEnglish ? 'Rank: $newRank' : '排名：$newRank',
              ),
            );
          }

          // 學期 GPA
          final newGpa = newSummary['gpa']?.toString() ?? '';
          if (newGpa.isNotEmpty &&
              newGpa != (oldSummary['gpa']?.toString() ?? '')) {
            changes.add(
              GradeChange(
                isEnglish ? 'Semester GPA' : '學期 GPA',
                isEnglish ? 'GPA updated: $newGpa' : 'GPA 更新：$newGpa',
              ),
            );
          }

          // 學期平均分數
          final newAvg = newSummary['average_score']?.toString() ?? '';
          if (newAvg.isNotEmpty &&
              newAvg != (oldSummary['average_score']?.toString() ?? '')) {
            changes.add(
              GradeChange(
                isEnglish ? 'Semester Average' : '學期平均',
                isEnglish ? 'Average updated: $newAvg' : '平均更新：$newAvg 分',
              ),
            );
          }
        }
      }
    }

    return changes;
  }

  /// 將單一科目轉成一則異動（標題=科目名、內文=成績更新）。
  static GradeChange? _courseChange(Map course, bool isEnglish) {
    final nameZh = course['name']?.toString() ?? '';
    final nameEn = course['name_en']?.toString() ?? '';
    final score = course['score']?.toString() ?? '';
    final displayName = isEnglish && nameEn.isNotEmpty ? nameEn : nameZh;
    if (displayName.isEmpty || score.isEmpty) return null;
    return GradeChange(
      displayName,
      isEnglish ? 'Grade updated: $score' : '成績更新：$score 分',
    );
  }
}
