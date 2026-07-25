import '../../models/course_detail_model.dart';
import '../../models/schedule_event.dart';
import '../scrape_result.dart';

/// 課表與課程詳情相關的服務介面。
abstract interface class CourseService {
  /// 取得課表（含該次抓取得知的學期清單與當前學期）。
  /// [semester] 為學期代碼（null = 當前學期）。
  Future<ScrapeResult<ScheduleSnapshot>> getSchedule({String? semester});

  /// 取得單一課程的詳細資訊（課綱）。
  Future<ScrapeResult<CourseDetail>> getCourseDetail({
    required String year,
    required String semester,
    required String courseNo,
  });
}
