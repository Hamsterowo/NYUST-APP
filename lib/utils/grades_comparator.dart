class GradesComparator {
  /// 比對新舊成績資料，回傳具體異動說明清單。
  /// [oldData] 是先前的 `cache_grades` JSON Map
  /// [newData] 是新抓取的 `cache_grades` JSON Map
  /// [isEnglish] 控制回傳英文還是中文格式的訊息
  static List<String> compare(
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData, {
    bool isEnglish = false,
  }) {
    final List<String> changes = [];
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
              final nameZh = course['name']?.toString() ?? '';
              final nameEn = course['name_en']?.toString() ?? '';
              final score = course['score']?.toString() ?? '';
              final displayName = isEnglish && nameEn.isNotEmpty ? nameEn : nameZh;
              if (displayName.isNotEmpty && score.isNotEmpty) {
                if (isEnglish) {
                  changes.add('[$displayName] Grade updated: $score');
                } else {
                  changes.add('【$displayName】成績更新：$score 分');
                }
              }
            }
          }
        }
      } else {
        // 已存在學期：比對科目分數與排名
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

            final nameZh = newCourse['name']?.toString() ?? '';
            final nameEn = newCourse['name_en']?.toString() ?? '';
            final newScore = newCourse['score']?.toString() ?? '';
            final displayName = isEnglish && nameEn.isNotEmpty ? nameEn : nameZh;

            final oldCourse = oldCoursesMap[code];
            if (oldCourse == null) {
              // 新增科目
              if (displayName.isNotEmpty && newScore.isNotEmpty) {
                if (isEnglish) {
                  changes.add('[$displayName] Grade updated: $newScore');
                } else {
                  changes.add('【$displayName】成績更新：$newScore 分');
                }
              }
            } else {
              // 比對分數
              final oldScore = oldCourse['score']?.toString() ?? '';
              if (newScore != oldScore && newScore.isNotEmpty) {
                if (isEnglish) {
                  changes.add('[$displayName] Grade updated: $oldScore -> $newScore');
                } else {
                  changes.add('【$displayName】成績更新：$oldScore -> $newScore 分');
                }
              }
            }
          }
        }

        // 比對學期排名
        final oldSummary = oldSem['summary'] as Map?;
        final newSummary = newSem['summary'] as Map?;
        if (oldSummary != null && newSummary != null) {
          final oldRank = oldSummary['rank']?.toString() ?? '';
          final newRank = newSummary['rank']?.toString() ?? '';
          if (newRank.isNotEmpty && newRank != oldRank) {
            if (isEnglish) {
              changes.add('Semester rank updated to: $newRank');
            } else {
              changes.add('學期排名更新為：$newRank');
            }
          }
        }
      }
    }

    return changes;
  }
}
