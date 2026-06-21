import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:intl/intl.dart';
import 'cookie_manager/cookie_manager_api.dart';
import 'scrapers/sso_scraper.dart';
import 'scrapers/info_scraper.dart';
import 'scrapers/schedule_scraper.dart';
import 'scrapers/grades_scraper.dart';
import 'scrapers/graduation_scraper.dart';
import 'scrapers/calendar_scraper.dart';

class ApiService {
  late Dio _dio;
  late SsoScraper _ssoScraper;
  late InfoScraper _infoScraper;
  late ScheduleScraper _scheduleScraper;
  late GradesScraper _gradesScraper;
  late GraduationScraper _graduationScraper;
  late CalendarScraper _calendarScraper;
  final String baseUrl = 'https://cf-api.nyust-plus.com';
  bool _initStarted = false;
  bool _isInit = false;

  Dio get dio => _dio;

  static const String _apiSecretKey = String.fromEnvironment(
    'API_SECRET',
    defaultValue: '',
  );

  VoidCallback? onSessionExpired;
  bool isMockMode = false;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        validateStatus: (status) {
          return status! < 500;
        },
        headers: {
          'Content-Type': 'application/json',
          'X-Nyust-App-Secret': _apiSecretKey,
        },
      ),
    );
    _dio.interceptors.add(LanguageInterceptor());
    _ssoScraper = SsoScraper(_dio);
    _infoScraper = InfoScraper(_dio);
    _scheduleScraper = ScheduleScraper(_dio);
    _gradesScraper = GradesScraper(_dio);
    _graduationScraper = GraduationScraper(_dio);
    _calendarScraper = CalendarScraper(_dio);
  }

  Future<void> init() async {
    if (_isInit) return;
    if (_initStarted) {
      while (!_isInit) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      return;
    }
    _initStarted = true;

    try {
      await setupCookieManager(_dio);
      _isInit = true;
    } catch (e) {
      if (kDebugMode) print('ApiService: Init failed: $e');
      _initStarted = false;
      rethrow;
    }
  }

  Future<void> _ensureInit() async {
    if (!_isInit) {
      await init();
    }
  }

  /// 檢查是否有儲存的學校 Cookies
  Future<bool> hasSavedCookies() async {
    final cookieJar = _dio.interceptors
        .whereType<CookieManager>()
        .firstOrNull
        ?.cookieJar;
    if (cookieJar == null) return false;
    final cookies = await cookieJar.loadForRequest(Uri.parse('https://webapp.yuntech.edu.tw'));
    return cookies.isNotEmpty;
  }

  Future<Map<String, dynamic>> loginInit() async {
    await _ensureInit();
    try {
      return await _ssoScraper.loginInit();
    } catch (e) {
      throw Exception('Failed to init login: $e');
    }
  }

  Future<Map<String, dynamic>> login(
    String username,
    String password,
    String captcha,
    String requestVerificationToken,
  ) async {
    await _ensureInit();
    try {
      final result = await _ssoScraper.login(
        username: username,
        password: password,
        captcha: captcha,
        verificationToken: requestVerificationToken,
        rememberMe: true,
      );
      return result;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

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
    await _ensureInit();
    return _infoScraper.getUserInfo();
  }

  Future<Map<String, dynamic>> getCalendarEvents(String year, {String? lang}) async {
    await _ensureInit();
    return _calendarScraper.getCalendarEvents(year, languageCode: lang);
  }

  Future<Map<String, dynamic>> getHolidays(int year, {String? lang}) async {
    await _ensureInit();
    return _calendarScraper.getHolidays(year, languageCode: lang);
  }

  /// 同時呼叫行事曆事件 + 假日兩個端點，合併回傳
  Future<Map<String, dynamic>> getCalendarCombined(String year, {String? lang}) async {
    final events = await getCalendarEvents(year, lang: lang);
    final holidays = await getHolidays(int.parse(year), lang: lang);

    return {
      'success': events['success'] == true && holidays['success'] == true,
      'events': events['events'] ?? [],
      'holidays': holidays['holidays'] ?? [],
      'holidayDetails': holidays['holidayDetails'] ?? {},
    };
  }

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
        ]
      };
    }
    await _ensureInit();
    return _gradesScraper.getGrades();
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
    await _ensureInit();
    return _graduationScraper.getGraduation();
  }

  /// 同時呼叫行事曆事件 + 假日兩個端點，合併回傳
  Future<Map<String, dynamic>> getCalendar(int year, {String? lang}) async {
    return getCalendarCombined(year.toString(), lang: lang);
  }



  Future<Map<String, dynamic>> getTermsOfService() async {
    await _ensureInit();
    try {
      final response = await _dio.get('/api/policy/terms');
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return {'status': 'error', 'message': '連線逾時，請稍後再試'};
      }
      if (e.type == DioExceptionType.connectionError) {
        return {'status': 'error', 'message': '無法連線至伺服器，請檢查網路連線'};
      }
      return {'status': 'error', 'message': 'API 呼叫失敗: ${e.message}'};
    } catch (e) {
      return {'status': 'error', 'message': 'API call failed: $e'};
    }
  }

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
    await _ensureInit();
    return _scheduleScraper.getSchedule();
  }

  Future<Map<String, dynamic>> getCourseDetail({
    required String year,
    required String semester,
    required String courseNo,
  }) async {
    await _ensureInit();
    return _scheduleScraper.getCourseDetail(
      year: year,
      semester: semester,
      courseNo: courseNo,
    );
  }

  Future<void> logout() async {
    await clearCookies();
  }

  SsoScraper get ssoScraper => _ssoScraper;
  InfoScraper get infoScraper => _infoScraper;
}

class LanguageInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final uri = options.uri;
    final path = uri.path.toLowerCase();

    // Only intercept student portal pages (WebNewCAS and eStudent) on webapp.yuntech.edu.tw
    if (uri.host == 'webapp.yuntech.edu.tw' &&
        (path.contains('/webnewcas/') || path.contains('/estudent/'))) {
      String languageCode = 'zh';
      try {
        if (Intl.defaultLocale != null && Intl.defaultLocale!.isNotEmpty) {
          languageCode = Intl.defaultLocale!.split('_').first.split('-').first.toLowerCase();
        } else {
          languageCode = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
        }
      } catch (_) {
        try {
          languageCode = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
        } catch (_) {}
      }

      final langValue = languageCode == 'en' ? 'en' : 'zh-TW';

      String currentPath = options.path;
      if (!currentPath.contains('lang=')) {
        if (currentPath.contains('?')) {
          final lastChar = currentPath.substring(currentPath.length - 1);
          if (lastChar == '?' || lastChar == '&') {
            currentPath = '${currentPath}lang=$langValue';
          } else {
            currentPath = '$currentPath&lang=$langValue';
          }
        } else {
          currentPath = '$currentPath?lang=$langValue';
        }
        options.path = currentPath;
      }
    }
    super.onRequest(options, handler);
  }
}
