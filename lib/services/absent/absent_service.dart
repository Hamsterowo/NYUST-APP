/// 請假記錄相關的服務介面。
abstract interface class AbsentService {
  /// 取得請假記錄。[semester] 為學年期代碼（如 `114,2`；null = 當前學期）。
  Future<Map<String, dynamic>> getAbsentRecords({String? semester});
}
