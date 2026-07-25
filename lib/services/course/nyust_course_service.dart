import '../../models/schedule_event.dart';
import '../api_client.dart';
import '../scrape_result.dart';
import '../scrapers/schedule_scraper.dart';
import 'course_service.dart';

/// 以 YunTech eStudent 網頁為後端的 [CourseService] 實作。
class NyustCourseService implements CourseService {
  final ApiClient _client;
  late final ScheduleScraper _scheduleScraper;

  NyustCourseService(this._client) {
    _scheduleScraper = ScheduleScraper(_client.dio);
  }

  @override
  Future<ScrapeResult<ScheduleSnapshot>> getSchedule({String? semester}) async {
    return _scheduleScraper.getSchedule(semester: semester);
  }

  @override
  Future<Map<String, dynamic>> getCourseDetail({
    required String year,
    required String semester,
    required String courseNo,
  }) async {
    return _scheduleScraper.getCourseDetail(
      year: year,
      semester: semester,
      courseNo: courseNo,
    );
  }
}
