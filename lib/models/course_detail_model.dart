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

  factory CourseDetail.fromJson(Map<String, dynamic> json) {
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
              ?.map((e) => CourseSyllabus.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
