import '../api_client.dart';
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
  Future<Map<String, dynamic>> getSchedule() async {
    await _client.ensureInit();
    return _scheduleScraper.getSchedule();
  }

  @override
  Future<Map<String, dynamic>> getCourseDetail({
    required String year,
    required String semester,
    required String courseNo,
  }) async {
    await _client.ensureInit();
    return _scheduleScraper.getCourseDetail(
      year: year,
      semester: semester,
      courseNo: courseNo,
    );
  }
}
