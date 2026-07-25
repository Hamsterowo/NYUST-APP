import '../../models/schedule_event.dart';
import '../scrape_result.dart';
import 'course_service.dart';
import '../mock/mock_data.dart';

/// Demo 模式使用的 [CourseService]，回傳 [MockData] 中的課表與課程詳情。
class MockCourseService implements CourseService {
  @override
  Future<ScrapeResult<ScheduleSnapshot>> getSchedule({String? semester}) async {
    final data = MockData.scheduleFor(semester)['data'] as Map;
    return ScrapeResult.success(
      ScheduleSnapshot.fromJson(Map<String, dynamic>.from(data)),
    );
  }

  @override
  Future<Map<String, dynamic>> getCourseDetail({
    required String year,
    required String semester,
    required String courseNo,
  }) async =>
      MockData.courseDetail(year: year, semester: semester, courseNo: courseNo);
}
