import '../../models/graduation_report.dart';
import '../scrape_result.dart';
import 'graduation_service.dart';
import '../mock/mock_data.dart';

/// Demo 模式使用的 [GraduationService]，回傳 [MockData] 中的畢業門檻資料。
class MockGraduationService implements GraduationService {
  @override
  Future<ScrapeResult<GraduationReport>> getGraduation() async =>
      ScrapeResult.success(GraduationReport.fromJson(MockData.graduation));
}
