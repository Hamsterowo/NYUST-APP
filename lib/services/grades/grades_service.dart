import '../../models/grade_report.dart';
import '../../models/graduation_report.dart';
import '../scrape_result.dart';

/// 成績與畢業門檻相關的服務介面。
abstract interface class GradesService {
  /// 取得各學期成績與累計成績。
  Future<ScrapeResult<GradeReport>> getGrades();

  /// 取得畢業門檻與學分資訊。
  Future<ScrapeResult<GraduationReport>> getGraduation();
}
