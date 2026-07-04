import 'course_service.dart';

/// Demo / 除錯模式使用的 [CourseService]，回傳固定的 mock 課表。
class MockCourseService implements CourseService {
  @override
  Future<Map<String, dynamic>> getSchedule() async {
    return {
      'status': 'success',
      'data': {
        'schedule': [
          {
            'semesterCourseNo': '11210001',
            'deptCourseNo': 'COE3001',
            'name': '行動裝置程式設計',
            'courseClass': '資工三甲',
            'classType': '選修',
            'requiredType': '選',
            'credits': '3',
            'timeRoomStr': '1-C,D/EL101',
            'teacher': '張教授',
            'remark': '',
            'times': ['C', 'D'],
            'weekday': '1',
          },
          {
            'semesterCourseNo': '11210002',
            'deptCourseNo': 'COE3002',
            'name': '人機互動技術',
            'courseClass': '資工三甲',
            'classType': '選修',
            'requiredType': '選',
            'credits': '3',
            'timeRoomStr': '2-E,F/EL102',
            'teacher': '李教授',
            'remark': '',
            'times': ['E', 'F'],
            'weekday': '2',
          },
          {
            'semesterCourseNo': '11210003',
            'deptCourseNo': 'COE3003',
            'name': '軟體工程',
            'courseClass': '資工三甲',
            'classType': '必修',
            'requiredType': '必',
            'credits': '3',
            'timeRoomStr': '3-A,B/EL105',
            'teacher': '王教授',
            'remark': '',
            'times': ['A', 'B'],
            'weekday': '3',
          },
          {
            'semesterCourseNo': '11210004',
            'deptCourseNo': 'COE3004',
            'name': '系統分析與設計',
            'courseClass': '資工三甲',
            'classType': '必修',
            'requiredType': '必',
            'credits': '3',
            'timeRoomStr': '4-G,H/EL108',
            'teacher': '陳教授',
            'remark': '',
            'times': ['G', 'H'],
            'weekday': '4',
          },
        ],
      },
    };
  }

  @override
  Future<Map<String, dynamic>> getCourseDetail({
    required String year,
    required String semester,
    required String courseNo,
  }) async {
    return {
      'status': 'success',
      'data': {
        'courseNo': courseNo,
        'name': '示範課程',
        'credits': '3',
        'teacher': '示範教授',
        'description': '這是 Demo 模式的課程詳情範例。',
      },
    };
  }
}
