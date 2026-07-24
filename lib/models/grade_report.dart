/// 成績的型別化領域模型。取代過去在 scraper、repository、UI、mock 之間流動的
/// `Map<String, dynamic>`，成為唯一契約。
///
/// 欄位一律為 String（沿用 [ScheduleEvent] 典範）：爬下來的文字不保證是數字
/// （score/credits 可能是「抵免」「通過」「W」或空字串），GPA 的 double 解析留在 UI。
///
/// - [fromJson] 吃 scraper / mock / Drift 重建的 wire map（snake_case key），是唯一進料口。
/// - [toJson] 忠實輸出 scraper 的 wire 形狀，讓 `cache_grades` 與背景比對
///   (`grades_comparator`) 位元組相容、無需改動。
library;

class CourseGrade {
  final String code;
  final String courseNo;
  final String name;
  final String nameEn;
  final String type;
  final String credits;
  final String score;
  final String syllabusUrl;

  const CourseGrade({
    required this.code,
    required this.courseNo,
    required this.name,
    required this.nameEn,
    required this.type,
    required this.credits,
    required this.score,
    required this.syllabusUrl,
  });

  factory CourseGrade.fromJson(Map<String, dynamic> json) {
    return CourseGrade(
      code: json['code']?.toString() ?? '',
      courseNo: json['courseNo']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nameEn: (json['name_en'] ?? json['nameEn'])?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      credits: json['credits']?.toString() ?? '',
      score: json['score']?.toString() ?? '',
      syllabusUrl: json['syllabusUrl']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'courseNo': courseNo,
    'name': name,
    'name_en': nameEn,
    'type': type,
    'credits': credits,
    'score': score,
    'syllabusUrl': syllabusUrl,
  };
}

class SemesterGrades {
  final String academicYear;
  final String semester;
  final String semesterTitle;
  final List<CourseGrade> courses;

  // summary 展平（與 Drift gradesSemesters 表欄位對齊）。
  final String averageScore;
  final String rank;
  final String gpa;
  final String conduct;
  final String attemptedCredits;
  final String earnedCredits;

  const SemesterGrades({
    required this.academicYear,
    required this.semester,
    required this.semesterTitle,
    required this.courses,
    required this.averageScore,
    required this.rank,
    required this.gpa,
    required this.conduct,
    required this.attemptedCredits,
    required this.earnedCredits,
  });

  factory SemesterGrades.fromJson(Map<String, dynamic> json) {
    final summary = (json['summary'] as Map?) ?? const {};
    final rawCourses = (json['courses'] as List?) ?? const [];
    return SemesterGrades(
      academicYear: json['academic_year']?.toString() ?? '',
      semester: json['semester']?.toString() ?? '',
      semesterTitle: json['semester_title']?.toString() ?? '',
      courses: rawCourses
          .map((c) => CourseGrade.fromJson(Map<String, dynamic>.from(c as Map)))
          .toList(),
      averageScore: summary['average_score']?.toString() ?? '',
      rank: summary['rank']?.toString() ?? '',
      gpa: summary['gpa']?.toString() ?? '',
      conduct: summary['conduct']?.toString() ?? '',
      attemptedCredits: summary['attempted_credits']?.toString() ?? '',
      earnedCredits: summary['earned_credits']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'academic_year': academicYear,
    'semester': semester,
    'semester_title': semesterTitle,
    'courses': courses.map((c) => c.toJson()).toList(),
    'summary': {
      'average_score': averageScore,
      'rank': rank,
      'gpa': gpa,
      'conduct': conduct,
      'attempted_credits': attemptedCredits,
      'earned_credits': earnedCredits,
    },
  };
}

class CumulativeGrades {
  final String attemptedCredits;
  final String earnedCredits;
  final String average;
  final String rank;
  final String totalStudents;
  final String gpa;

  const CumulativeGrades({
    required this.attemptedCredits,
    required this.earnedCredits,
    required this.average,
    required this.rank,
    required this.totalStudents,
    required this.gpa,
  });

  factory CumulativeGrades.fromJson(Map<String, dynamic> json) {
    return CumulativeGrades(
      attemptedCredits: json['attempted_credits']?.toString() ?? '',
      earnedCredits: json['earned_credits']?.toString() ?? '',
      average: json['average']?.toString() ?? '',
      rank: json['rank']?.toString() ?? '',
      totalStudents: json['total_students']?.toString() ?? '',
      gpa: json['gpa']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'attempted_credits': attemptedCredits,
    'earned_credits': earnedCredits,
    'average': average,
    'rank': rank,
    'total_students': totalStudents,
    'gpa': gpa,
  };
}

class GradeReport {
  final List<SemesterGrades> semesters;
  final CumulativeGrades? cumulative;

  const GradeReport({required this.semesters, this.cumulative});

  factory GradeReport.fromJson(Map<String, dynamic> json) {
    final rawGrades = (json['grades'] as List?) ?? const [];
    final rawCumulative = json['cumulative'];
    return GradeReport(
      semesters: rawGrades
          .map(
            (s) => SemesterGrades.fromJson(Map<String, dynamic>.from(s as Map)),
          )
          .toList(),
      cumulative: rawCumulative is Map
          ? CumulativeGrades.fromJson(Map<String, dynamic>.from(rawCumulative))
          : null,
    );
  }

  /// 輸出與 scraper 相同的 wire 形狀（含 `success: true`），供 `cache_grades`
  /// 持久化與背景比對使用，保持位元組相容。
  Map<String, dynamic> toJson() => {
    'success': true,
    'grades': semesters.map((s) => s.toJson()).toList(),
    'cumulative': cumulative?.toJson(),
  };
}
