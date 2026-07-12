import 'api_client.dart';
import 'auth/auth_service.dart';
import 'auth/nyust_auth_service.dart';
import 'auth/mock_auth_service.dart';
import 'grades/grades_service.dart';
import 'grades/nyust_grades_service.dart';
import 'grades/mock_grades_service.dart';
import 'course/course_service.dart';
import 'course/nyust_course_service.dart';
import 'course/mock_course_service.dart';
import 'calendar/calendar_service.dart';
import 'calendar/nyust_calendar_service.dart';
import 'absent/absent_service.dart';
import 'absent/nyust_absent_service.dart';
import 'absent/mock_absent_service.dart';

/// 根據 demo 模式狀態，回傳正確的 Service 實作。
///
/// 這是消除散落各處 `if (isMockMode)` 判斷的核心：呼叫端一律透過此 factory
/// 取得 Service，由 [isDemoMode] 這個唯一開關決定回傳 Mock 還是真實實作。
///
/// - `demo` 帳號登入 → [isDemoMode] = true → 回傳 Mock 實作
/// - 一般帳號 → 回傳 Nyust*（真實爬蟲）實作
class ServiceFactory {
  final ApiClient client;

  /// 是否為 demo / 除錯模式。可在執行期切換（例如 debug 帳號登入時設為 true）。
  bool isDemoMode;

  ServiceFactory(this.client, {this.isDemoMode = false});

  late final NyustAuthService _nyustAuth = NyustAuthService(client);
  late final MockAuthService _mockAuth = MockAuthService();
  late final NyustGradesService _nyustGrades = NyustGradesService(client);
  late final MockGradesService _mockGrades = MockGradesService();
  late final NyustCourseService _nyustCourse = NyustCourseService(client);
  late final MockCourseService _mockCourse = MockCourseService();
  late final NyustCalendarService _nyustCalendar = NyustCalendarService(client);
  late final NyustAbsentService _nyustAbsent = NyustAbsentService(client);
  late final MockAbsentService _mockAbsent = MockAbsentService();

  AuthService get authService => isDemoMode ? _mockAuth : _nyustAuth;
  GradesService get gradesService => isDemoMode ? _mockGrades : _nyustGrades;
  CourseService get courseService => isDemoMode ? _mockCourse : _nyustCourse;
  AbsentService get absentService => isDemoMode ? _mockAbsent : _nyustAbsent;

  /// 行事曆為全校共用的學術行事曆／假日，從公開網頁爬取，與帳號無關，
  /// 因此即使在 demo 模式也一律使用真實實作，讓測試帳號也能正常抓取行事曆。
  CalendarService get calendarService => _nyustCalendar;

  /// 真實 SSO 認證 Service（供 facade 暴露 scraper getter 使用，永遠為真實實作）。
  NyustAuthService get nyustAuth => _nyustAuth;
}
