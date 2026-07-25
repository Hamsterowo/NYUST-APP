import '../../models/graduation_report.dart';
import '../scrape_result.dart';

/// 畢業門檻相關的服務介面。
///
/// 真實實作為 [GraduationScraper] 本身；demo 模式為 [MockGraduationService]。
abstract interface class GraduationService {
  /// 取得畢業門檻與學分資訊。
  Future<ScrapeResult<GraduationReport>> getGraduation();
}
