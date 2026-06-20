class ScheduleEvent {
  final String semesterCourseNo;
  final String deptCourseNo;
  final String name;
  final String? nameEn;
  final String courseClass;
  final String classType;
  final String requiredType;
  final String credits;
  final String timeRoomStr;
  final String teacher;
  final String remark;

  final String? weekday;
  final List<String> times;
  final String? room;

  final String? syllabusUrl;
  final String? year;
  final String? semester;
  final String? courseNo;

  ScheduleEvent({
    required this.semesterCourseNo,
    required this.deptCourseNo,
    required this.name,
    this.nameEn,
    required this.courseClass,
    required this.classType,
    required this.requiredType,
    required this.credits,
    required this.timeRoomStr,
    required this.teacher,
    required this.remark,
    this.weekday,
    required this.times,
    this.room,
    this.syllabusUrl,
    this.year,
    this.semester,
    this.courseNo,
  });

  factory ScheduleEvent.fromJson(Map<String, dynamic> json) {
    return ScheduleEvent(
      semesterCourseNo: json['semesterCourseNo'] ?? '',
      deptCourseNo: json['deptCourseNo'] ?? '',
      name: json['name'] ?? '',
      nameEn: json['nameEn'] ?? json['name_en'],
      courseClass: json['courseClass'] ?? '',
      classType: json['classType'] ?? '',
      requiredType: json['requiredType'] ?? '',
      credits: json['credits'] ?? '',
      timeRoomStr: json['timeRoomStr'] ?? '',
      teacher: json['teacher'] ?? '',
      remark: json['remark'] ?? '',
      weekday: json['weekday'],
      times: List<String>.from(json['times'] ?? []),
      room: json['room'],
      syllabusUrl: json['syllabusUrl'],
      year: json['year'],
      semester: json['semester'],
      courseNo: json['courseNo'],
    );
  }
}
