import 'grades_service.dart';
import '../mock/mock_data.dart';

/// Demo 模式使用的 [GradesService]，回傳 [MockData] 中的成績與畢業門檻資料。
class MockGradesService implements GradesService {
  @override
  Future<Map<String, dynamic>> getGrades() async => MockData.grades;

  @override
  Future<Map<String, dynamic>> getGraduation() async => MockData.graduation;
}
