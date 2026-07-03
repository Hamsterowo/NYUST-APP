import '../api_client.dart';
import '../scrapers/grades_scraper.dart';
import '../scrapers/graduation_scraper.dart';
import 'grades_service.dart';

/// 以 YunTech eStudent 網頁為後端的 [GradesService] 實作。
class NyustGradesService implements GradesService {
  final ApiClient _client;
  late final GradesScraper _gradesScraper;
  late final GraduationScraper _graduationScraper;

  NyustGradesService(this._client) {
    _gradesScraper = GradesScraper(_client.dio);
    _graduationScraper = GraduationScraper(_client.dio);
  }

  @override
  Future<Map<String, dynamic>> getGrades() async {
    await _client.ensureInit();
    return _gradesScraper.getGrades();
  }

  @override
  Future<Map<String, dynamic>> getGraduation() async {
    await _client.ensureInit();
    return _graduationScraper.getGraduation();
  }
}
