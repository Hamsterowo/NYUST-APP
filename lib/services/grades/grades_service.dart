import '../../models/grade_report.dart';
import '../scrape_result.dart';

/// 成績相關的服務介面。
///
/// 真實實作為 [GradesScraper] 本身（它已是這道縫的真實 adapter，
/// 中間不再有純轉呼叫的一層）；demo 模式為 [MockGradesService]。
abstract interface class GradesService {
  /// 取得各學期成績與累計成績。
  Future<ScrapeResult<GradeReport>> getGrades();
}
