import '../../models/grade_report.dart';
import '../../models/graduation_report.dart';
import '../scrape_result.dart';
import 'grades_service.dart';
import '../mock/mock_data.dart';

/// Demo 模式使用的 [GradesService]，回傳 [MockData] 中的成績與畢業門檻資料。
class MockGradesService implements GradesService {
  @override
  Future<ScrapeResult<GradeReport>> getGrades() async =>
      ScrapeResult.success(GradeReport.fromJson(MockData.grades));

  @override
  Future<ScrapeResult<GraduationReport>> getGraduation() async =>
      ScrapeResult.success(GraduationReport.fromJson(MockData.graduation));
}
