/// 課表與課程詳情相關的服務介面。
abstract interface class CourseService {
  /// 取得本學期課表。
  Future<Map<String, dynamic>> getSchedule();

  /// 取得單一課程的詳細資訊。
  Future<Map<String, dynamic>> getCourseDetail({
    required String year,
    required String semester,
    required String courseNo,
  });
}
