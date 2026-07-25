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

  /// 序列化為與 scraper 相同的 wire 形狀（`nameEn` 採 camelCase，與 scraper 一致），
  /// 供「其他學期」課表的 JSON 快取持久化使用。裝置上既有的快取列同為此形狀，
  /// 因此升級後仍可讀取（[fromJson] 另相容舊的 `name_en`）。
  Map<String, dynamic> toJson() => {
    'semesterCourseNo': semesterCourseNo,
    'deptCourseNo': deptCourseNo,
    'name': name,
    'nameEn': nameEn,
    'courseClass': courseClass,
    'classType': classType,
    'requiredType': requiredType,
    'credits': credits,
    'timeRoomStr': timeRoomStr,
    'teacher': teacher,
    'remark': remark,
    'weekday': weekday,
    'times': times,
    'room': room,
    'syllabusUrl': syllabusUrl,
    'year': year,
    'semester': semester,
    'courseNo': courseNo,
  };
}

/// 學期切換器的一個選項。
class SemesterOption {
  /// 學期代碼（例：`1142`），送回學校端查詢用。
  final String value;

  /// 顯示文字（例：`114學年第2學期`）。
  final String label;

  const SemesterOption({required this.value, required this.label});

  factory SemesterOption.fromJson(Map<String, dynamic> json) {
    return SemesterOption(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'value': value, 'label': label};
}

/// 一次課表抓取的完整結果：該學期的課程，加上抓取當下得知的學期清單與
/// 學校目前的當前學期代碼。
///
/// 學期中繼資料與課程來自同一次請求，因此放在同一個型別裡回傳，
/// 而不是課程走回傳值、中繼資料走可變欄位的側通道。
class ScheduleSnapshot {
  final List<ScheduleEvent> courses;
  final List<SemesterOption> semesters;
  final String currentSemester;

  const ScheduleSnapshot({
    required this.courses,
    this.semesters = const [],
    this.currentSemester = '',
  });

  /// 解析 scraper 的 `data` 區塊（`schedule` / `semesters` / `currentSemester`）。
  /// 缺少 `semesters` 或 `currentSemester` 時回退為空（快取重建即為此情況）。
  factory ScheduleSnapshot.fromJson(Map<String, dynamic> json) {
    final rawCourses = (json['schedule'] as List?) ?? const [];
    final rawSemesters = (json['semesters'] as List?) ?? const [];
    return ScheduleSnapshot(
      courses: rawCourses
          .map(
            (e) => ScheduleEvent.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      semesters: rawSemesters
          .map(
            (e) => SemesterOption.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      currentSemester: json['currentSemester']?.toString() ?? '',
    );
  }
}
