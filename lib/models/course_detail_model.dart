class CourseSyllabus {
  final String week;
  final String content;
  final String method;
  final String remark;

  CourseSyllabus({
    required this.week,
    required this.content,
    required this.method,
    required this.remark,
  });

  factory CourseSyllabus.fromJson(Map<String, dynamic> json) {
    return CourseSyllabus(
      week: json['week'] ?? '',
      content: json['content'] ?? '',
      method: json['method'] ?? '',
      remark: json['remark'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'week': week,
    'content': content,
    'method': method,
    'remark': remark,
  };
}

class CourseDetail {
  final String courseName;
  final String teacher;
  final String credits;
  final String timeRoom;
  final String requiredType;
  final String goal;
  final String outline;
  final String grade;
  final String? deptCourseNo;
  final String? courseType;
  final String? courseClass;
  final String? teacherEmailAndTel;
  final String? courseRemark;
  final List<CourseSyllabus> syllabus;

  CourseDetail({
    required this.courseName,
    required this.teacher,
    required this.credits,
    required this.timeRoom,
    required this.requiredType,
    required this.goal,
    required this.outline,
    required this.grade,
    this.deptCourseNo,
    this.courseType,
    this.courseClass,
    this.teacherEmailAndTel,
    this.courseRemark,
    this.syllabus = const [],
  });

  /// 從快取/回應的 JSON 還原。
  ///
  /// 也接受**舊版的完整信封** `{status: ..., data: {...}}` —— 早期的課綱快取
  /// 存的是整個回應而非課程本身。直接把信封餵進來會得到一片空白欄位（不會崩，
  /// 但會顯示錯的內容），因此在這裡明確地解開。
  factory CourseDetail.fromJson(Map<String, dynamic> json) {
    final payload = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    return CourseDetail._fromPayload(payload);
  }

  factory CourseDetail._fromPayload(Map<String, dynamic> json) {
    return CourseDetail(
      courseName: json['courseName'] ?? '',
      teacher: json['teacher'] ?? '',
      credits: json['credits'] ?? '',
      timeRoom: json['timeRoom'] ?? '',
      requiredType: json['requiredType'] ?? '',
      goal: json['goal'] ?? '',
      outline: json['outline'] ?? '',
      grade: json['grade'] ?? '',
      deptCourseNo: json['deptCourseNo'],
      courseType: json['courseType'],
      courseClass: json['courseClass'],
      teacherEmailAndTel: json['teacherEmailAndTel'],
      courseRemark: json['courseRemark'],
      syllabus:
          (json['syllabus'] as List<dynamic>?)
              ?.map(
                (e) => CourseSyllabus.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'courseName': courseName,
    'teacher': teacher,
    'credits': credits,
    'timeRoom': timeRoom,
    'requiredType': requiredType,
    'goal': goal,
    'outline': outline,
    'grade': grade,
    'deptCourseNo': deptCourseNo,
    'courseType': courseType,
    'courseClass': courseClass,
    'teacherEmailAndTel': teacherEmailAndTel,
    'courseRemark': courseRemark,
    'syllabus': syllabus.map((s) => s.toJson()).toList(),
  };
}
