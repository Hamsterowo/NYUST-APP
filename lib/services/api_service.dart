import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'api_client.dart';
import 'auth/nyust_auth_service.dart';
import 'grades/nyust_grades_service.dart';
import 'course/nyust_course_service.dart';
import 'calendar/nyust_calendar_service.dart';
import 'report/cf_report_service.dart';
import 'scrapers/sso_scraper.dart';
import 'scrapers/info_scraper.dart';

/// 對外的統一入口 facade。
///
/// 本身不再包辦 HTTP 細節，而是持有一個 [ApiClient] 與各個 feature Service，
/// 並將呼叫委派下去，藉此保持既有的對外 API 不變（[AuthProvider] / [DataProvider]
/// 等呼叫端不需同步修改）。
///
/// 註：mock/debug 模式的分支仍暫留在此 facade，將於後續階段（Demo Mode 重構）
/// 改由 Interface + DI 自動切換 Mock 實作取代。
class ApiService {
  final ApiClient _client = ApiClient();

  late final NyustAuthService _auth;
  late final NyustGradesService _grades;
  late final NyustCourseService _course;
  late final NyustCalendarService _calendar;
  late final CfReportService _report;

  bool isMockMode = false;

  ApiService() {
    _auth = NyustAuthService(_client);
    _grades = NyustGradesService(_client);
    _course = NyustCourseService(_client);
    _calendar = NyustCalendarService(_client);
    _report = CfReportService(_client);
  }

  Dio get dio => _client.dio;
  String get baseUrl => _client.baseUrl;

  VoidCallback? get onSessionExpired => _client.onSessionExpired;
  set onSessionExpired(VoidCallback? cb) => _client.onSessionExpired = cb;

  Future<void> init() => _client.init();

  /// 檢查是否有儲存的學校 Cookies
  Future<bool> hasSavedCookies() => _client.hasSavedCookies();

  /// 取得特定網域的 Cookies
  Future<List<Cookie>> getCookiesForUri(Uri uri) =>
      _client.getCookiesForUri(uri);

  // ---- Auth ----

  Future<Map<String, dynamic>> loginInit() => _auth.loginInit();

  Future<Map<String, dynamic>> login(
    String username,
    String password,
    String captcha,
    String requestVerificationToken,
  ) =>
      _auth.login(username, password, captcha, requestVerificationToken);

  Future<Map<String, dynamic>> getUserInfo() async {
    if (isMockMode) {
      return {
        'success': true,
        'user': {
          'name': '開發除錯員',
          'id': 'D11012345',
          'dept': '資訊工程學系',
          'class': '資工三甲',
        }
      };
    }
    return _auth.getUserInfo();
  }

  Future<void> logout() => _auth.logout();

  // ---- Calendar ----

  Future<Map<String, dynamic>> getCalendarEvents(String year, {String? lang}) =>
      _calendar.getCalendarEvents(year, lang: lang);

  Future<Map<String, dynamic>> getHolidays(int year, {String? lang}) =>
      _calendar.getHolidays(year, lang: lang);

  /// 同時呼叫行事曆事件 + 假日兩個端點，合併回傳
  Future<Map<String, dynamic>> getCalendarCombined(String year,
          {String? lang}) =>
      _calendar.getCalendarCombined(year, lang: lang);

  /// 同時呼叫行事曆事件 + 假日兩個端點，合併回傳
  Future<Map<String, dynamic>> getCalendar(int year, {String? lang}) =>
      _calendar.getCalendarCombined(year.toString(), lang: lang);

  // ---- Grades ----

  Future<Map<String, dynamic>> getGrades() async {
    if (isMockMode) {
      return {
        'success': true,
        'grades': [
          {
            'academic_year': '112',
            'semester': '1',
            'summary': {
              'average_score': '89.50',
              'rank': '3 / 48',
              'gpa': '3.90',
              'conduct': '88',
              'attempted_credits': '18',
              'earned_credits': '18',
            },
            'courses': [
              {
                'name': '行動裝置程式設計',
                'credits': '3.0',
                'score': '95',
                'type': '選修',
                'courseNo': '1001',
              },
              {
                'name': '軟體工程',
                'credits': '3.0',
                'score': '88',
                'type': '必修',
                'courseNo': '1002',
              },
              {
                'name': '電腦網路',
                'credits': '3.0',
                'score': '85',
                'type': '必修',
                'courseNo': '1003',
              }
            ]
          },
          {
            'academic_year': '112',
            'semester': '2',
            'summary': {
              'average_score': '92.30',
              'rank': '1 / 48',
              'gpa': '4.15',
              'conduct': '90',
              'attempted_credits': '17',
              'earned_credits': '17',
            },
            'courses': [
              {
                'name': '人機互動技術',
                'credits': '3.0',
                'score': '96',
                'type': '選修',
                'courseNo': '2001',
              },
              {
                'name': '編譯器設計',
                'credits': '3.0',
                'score': '87',
                'type': '必修',
                'courseNo': '2002',
              },
              {
                'name': '專題實作(二)',
                'credits': '2.0',
                'score': '94',
                'type': '必修',
                'courseNo': '2003',
              }
            ]
          }
        ],
        'cumulative': {
          'average': '90.90',
          'rank': '2',
          'total_students': '48',
          'gpa': '4.02',
          'attempted_credits': '35',
          'earned_credits': '35',
        }
      };
    }
    return _grades.getGrades();
  }

  Future<Map<String, dynamic>> getGraduation() async {
    if (isMockMode) {
      return {
        'success': true,
        'graduation_info': {
          'total_credits': '84',
          'english_threshold': '已通過',
          'internship_threshold': '已修過',
          'credits_breakdown': {
            'required_goal': {
              'pe': '4',
              'civilization': '2',
              'literature': '2',
              'general': '8',
              'dept_required': '60',
              'elective': '52',
              'total': '128',
            },
            'earned': {
              'pe': '4',
              'civilization': '2',
              'literature': '2',
              'general': '8',
              'dept_required': '50',
              'elective': '18',
              'total': '84',
            },
            'missing': {
              'pe': '0',
              'civilization': '0',
              'literature': '0',
              'general': '0',
              'dept_required': '10',
              'elective': '34',
              'total': '44',
            }
          },
          'missing_courses_text': 'COE3007工程倫理與產業導論[3]、COE3008系統分析與設計[3]'
        }
      };
    }
    return _grades.getGraduation();
  }

  // ---- Course ----

  Future<Map<String, dynamic>> getSchedule() async {
    if (isMockMode) {
      return {
        'status': 'success',
        'data': {
          'schedule': [
            {
              'semesterCourseNo': '11210001',
              'deptCourseNo': 'COE3001',
              'name': '行動裝置程式設計',
              'courseClass': '資工三甲',
              'classType': '選修',
              'requiredType': '選',
              'credits': '3',
              'timeRoomStr': '1-C,D/EL101',
              'teacher': '張教授',
              'remark': '',
              'times': ['C', 'D'],
              'weekday': '1'
            },
            {
              'semesterCourseNo': '11210002',
              'deptCourseNo': 'COE3002',
              'name': '人機互動技術',
              'courseClass': '資工三甲',
              'classType': '選修',
              'requiredType': '選',
              'credits': '3',
              'timeRoomStr': '2-E,F/EL102',
              'teacher': '李教授',
              'remark': '',
              'times': ['E', 'F'],
              'weekday': '2'
            },
            {
              'semesterCourseNo': '11210003',
              'deptCourseNo': 'COE3003',
              'name': '軟體工程',
              'courseClass': '資工三甲',
              'classType': '必修',
              'requiredType': '必',
              'credits': '3',
              'timeRoomStr': '3-A,B/EL105',
              'teacher': '王教授',
              'remark': '',
              'times': ['A', 'B'],
              'weekday': '3'
            },
            {
              'semesterCourseNo': '11210004',
              'deptCourseNo': 'COE3004',
              'name': '系統分析與設計',
              'courseClass': '資工三甲',
              'classType': '必修',
              'requiredType': '必',
              'credits': '3',
              'timeRoomStr': '4-G,H/EL108',
              'teacher': '陳教授',
              'remark': '',
              'times': ['G', 'H'],
              'weekday': '4'
            }
          ]
        }
      };
    }
    return _course.getSchedule();
  }

  Future<Map<String, dynamic>> getCourseDetail({
    required String year,
    required String semester,
    required String courseNo,
  }) =>
      _course.getCourseDetail(
        year: year,
        semester: semester,
        courseNo: courseNo,
      );

  // ---- Report / Policy ----

  Future<Map<String, dynamic>> getTermsOfService({String? lang}) =>
      _report.getTermsOfService(lang: lang);

  Future<Map<String, dynamic>> submitBugReport({
    required String description,
    String? contact,
    required String deviceInfo,
    XFile? imageFile,
  }) =>
      _report.submitBugReport(
        description: description,
        contact: contact,
        deviceInfo: deviceInfo,
        imageFile: imageFile,
      );

  // ---- Scraper 存取（維持既有對外 getter；目前無外部使用者）----

  SsoScraper get ssoScraper => _auth.ssoScraper;
  InfoScraper get infoScraper => _auth.infoScraper;
}
