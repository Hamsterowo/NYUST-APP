import 'absent_service.dart';
import '../mock/mock_data.dart';

/// Demo 模式使用的 [AbsentService]，回傳 [MockData] 的請假記錄。
class MockAbsentService implements AbsentService {
  @override
  Future<Map<String, dynamic>> getAbsentRecords({String? semester}) async =>
      MockData.absentFor(semester);
}
