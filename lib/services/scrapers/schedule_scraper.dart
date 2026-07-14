import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:html/dom.dart' as dom;
import '../../utils/network_error.dart';
import 'base_scraper.dart';

/// 處理課表資料爬取的類別
class ScheduleScraper extends BaseScraper {
  ScheduleScraper(super.dio);

  static const String scheduleUrl =
      'https://webapp.yuntech.edu.tw/WebNewCAS/StudentFile/Course/';

  /// 學期下拉選單的欄位名（ASP.NET DropDownList，AutoPostBack）。
  static const String _acadSemeField = r'ctl00$MainContent$AcadSeme';

  /// 獲取學生課表資料。
  ///
  /// [semester] 為學期代碼（例：`1142` = 114 學年第 2 學期）。傳 null 或當前
  /// 選中的學期時，直接解析當前頁面；否則以 ASP.NET postback 切換到指定學期。
  Future<Map<String, dynamic>> getSchedule({String? semester}) async {
    try {
      if (kDebugMode)
        print('ScheduleScraper: Fetching schedule from $scheduleUrl');

      final response = await getWithRedirects(
        scheduleUrl,
        options: Options(
          headers: {
            ...commonHeaders,
            'Referer': 'https://webapp.yuntech.edu.tw/YunTechSSO/Account/Login',
          },
        ),
      );

      var document = parseHtml(response.data);
      if (kDebugMode)
        print(
          'ScheduleScraper: Page Title: ${document.querySelector('title')?.text.trim()}',
        );

      if (response.data.toString().contains('Login.aspx') ||
          document.querySelector('form[action="./Login/Login.aspx"]') != null) {
        return {
          'status': 'session_expired',
          'message': 'Session expired, please login again',
        };
      }

      final semesters = _parseSemesters(document);
      final currentSemester = _selectedSemester(document);

      // 要看的不是當前學期 → 送一次 postback 切換到指定學期。
      if (semester != null &&
          semester.isNotEmpty &&
          semester != currentSemester) {
        final switched = await _postbackSemester(document, semester);
        if (switched != null) document = switched;
      }

      final courses = _parseCourses(document);

      if (kDebugMode) print('ScheduleScraper: Found ${courses.length} courses');

      return {
        'status': 'success',
        'data': {
          'schedule': courses,
          'semesters': semesters,
          'currentSemester': currentSemester,
        },
      };
    } catch (e) {
      // 先判離線再歸類其他錯誤；message 僅供除錯 log，不進 UI。
      if (isNetworkError(e)) {
        return {
          'status': 'network_error',
          'message': 'Network error fetching schedule: $e',
        };
      }
      return {'status': 'error', 'message': 'Failed to fetch schedule: $e'};
    }
  }

  /// 解析學期下拉選單的所有選項（value + 顯示文字）。
  List<Map<String, String>> _parseSemesters(dom.Document document) {
    final options = document.querySelectorAll(
      '#ctl00_MainContent_AcadSeme option',
    );
    final result = <Map<String, String>>[];
    for (final o in options) {
      final value = o.attributes['value']?.trim() ?? '';
      if (value.isEmpty) continue;
      result.add({'value': value, 'label': o.text.trim()});
    }
    return result;
  }

  /// 取得目前選中的學期代碼。
  String _selectedSemester(dom.Document document) {
    final selected = document.querySelector(
      '#ctl00_MainContent_AcadSeme option[selected]',
    );
    if (selected != null) {
      return selected.attributes['value']?.trim() ?? '';
    }
    final first = document.querySelector('#ctl00_MainContent_AcadSeme option');
    return first?.attributes['value']?.trim() ?? '';
  }

  /// 以 ASP.NET WebForms postback 切換學期，回傳切換後的頁面 document。
  Future<dom.Document?> _postbackSemester(
    dom.Document document,
    String semester,
  ) async {
    try {
      // 帶上頁面所有 hidden 欄位（__VIEWSTATE / __EVENTVALIDATION 等）。
      final form = <String, String>{};
      for (final input in document.querySelectorAll('input[type="hidden"]')) {
        final name = input.attributes['name'];
        if (name != null && name.isNotEmpty) {
          form[name] = input.attributes['value'] ?? '';
        }
      }
      form['__EVENTTARGET'] = _acadSemeField;
      form['__EVENTARGUMENT'] = '';
      form[_acadSemeField] = semester;

      final res = await dio.post(
        scheduleUrl,
        data: form,
        options: Options(
          headers: {...commonHeaders, 'Referer': scheduleUrl},
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );
      return parseHtml(res.data);
    } catch (e) {
      if (kDebugMode) print('ScheduleScraper: postback failed: $e');
      return null;
    }
  }

  /// 從課表頁面 document 解析出課程清單。
  List<Map<String, dynamic>> _parseCourses(dom.Document document) {
    final List<Map<String, dynamic>> courses = [];

    final courseLinks = document.querySelectorAll('[id*="_cour_cname"]');

    for (var anchor in courseLinks) {
      final name = anchor.text.trim();

      dom.Element? row = anchor.parent;
      while (row != null && row.localName != 'tr') {
        row = row.parent;
      }

      if (row != null && name.isNotEmpty) {
        String syllabusUrl = '';
        String year = '';
        String semester = '';
        String courseNo = '';
        final relativeHref = anchor.attributes['href'];

        if (relativeHref != null && relativeHref.isNotEmpty) {
          syllabusUrl = relativeHref.replaceFirst(
            RegExp(r'^(\.\.\/)+'),
            'https://webapp.yuntech.edu.tw/WebNewCAS/',
          );

          final parts = relativeHref.split('&');
          if (parts.length >= 4) {
            year = parts[1];
            semester = parts[2];
            courseNo = parts[3];
          }
        }

        final semesterCourseNo = _findTextById(row, '_current_subj');
        final deptCourseNo = _findTextById(row, '_Dept_Cour_No');
        final nameEn = _findTextById(row, '_cour_ename');
        final courseClass = _findTextById(row, '_Cour_Class');
        final classType = _findTextById(row, '_Subj_Team');
        final requiredType = _findTextById(row, '_maj_op');
        final credits = _findTextById(row, '_credits');
        final timeRoomStr = _findTextById(row, '_Cour_Time');
        final teacher = _findTextById(row, '_cour_emp');

        String remark = '';
        final remarkElements = row.querySelectorAll(
          'span[id*="_comm"], span[id*="_CourRemark_00"], span[id*="_Remark_00_01"], span[id*="_remark_00_02"]',
        );
        for (var rEl in remarkElements) {
          final rText = rEl.text.trim();
          if (rText.isNotEmpty) {
            remark += '$rText ';
          }
        }

        String weekday = '';
        List<String> times = [];
        String room = '';

        if (timeRoomStr.isNotEmpty) {
          final parts = timeRoomStr.split('/');
          if (parts.length == 2) {
            final timePart = parts[0];
            room = parts[1];

            final timeParts = timePart.split('-');
            if (timeParts.length == 2) {
              weekday = timeParts[0];
              times = timeParts[1].split('');
            }
          } else {
            room = timeRoomStr;
          }
        }

        courses.add({
          'semesterCourseNo': semesterCourseNo,
          'deptCourseNo': deptCourseNo,
          'name': name,
          'nameEn': nameEn,
          'courseClass': courseClass,
          'classType': classType,
          'requiredType': requiredType,
          'credits': credits,
          'timeRoomStr': timeRoomStr,
          'teacher': teacher,
          'remark': remark.trim(),
          'weekday': weekday,
          'times': times,
          'room': room,
          'syllabusUrl': syllabusUrl,
          'year': year,
          'semester': semester,
          'courseNo': courseNo,
        });
      }
    }

    return courses;
  }

  /// 獲取課程詳細資訊 (大綱)
  Future<Map<String, dynamic>> getCourseDetail({
    required String year,
    required String semester,
    required String courseNo,
  }) async {
    try {
      final detailUrl =
          'https://webapp.yuntech.edu.tw/WebNewCAS/Course/Plan/Query.aspx?&$year&$semester&$courseNo';

      if (kDebugMode)
        print('ScheduleScraper: Fetching course detail from $detailUrl');

      final response = await getWithRedirects(
        detailUrl,
        options: Options(headers: {...commonHeaders}),
      );

      final document = parseHtml(response.data);

      String text(String selector) =>
          document.querySelector(selector)?.text.trim() ?? '';

      final Map<String, dynamic> courseDetail = {
        'courseName': text('#ctl00_MainContent_Cour_cname_fLabel').isNotEmpty
            ? text('#ctl00_MainContent_Cour_cname_fLabel')
            : text('span[id*="Cour_cname"]'),
        'teacher': text('#ctl00_MainContent_Chn_name_nLabel').isNotEmpty
            ? text('#ctl00_MainContent_Chn_name_nLabel')
            : text('span[id*="Chn_name_nLabel"]'),
        'credits': text('#ctl00_MainContent_CreditsLabel').isNotEmpty
            ? text('#ctl00_MainContent_CreditsLabel')
            : text('span[id*="CreditsLabel"]'),
        'timeRoom': text('#ctl00_MainContent_CourTimeLabel').isNotEmpty
            ? text('#ctl00_MainContent_CourTimeLabel')
            : text('span[id*="CourTimeLabel"]'),
        'requiredType': text('#ctl00_MainContent_Maj_OpLabel').isNotEmpty
            ? text('#ctl00_MainContent_Maj_OpLabel')
            : text('span[id*="Maj_OpLabel"]'),
        'goal': text('#ctl00_MainContent_TeachingObjectivesLabel').isNotEmpty
            ? text('#ctl00_MainContent_TeachingObjectivesLabel')
            : text('span[id*="TeachingObjectivesLabel"]'),
        'outline': text('#ctl00_MainContent_CourseIntroductionLabel').isNotEmpty
            ? text('#ctl00_MainContent_CourseIntroductionLabel')
            : text('span[id*="CourseIntroductionLabel"]'),
        'grade': text('#ctl00_MainContent_EvaluationMethodsLabel').isNotEmpty
            ? text('#ctl00_MainContent_EvaluationMethodsLabel')
            : text('span[id*="EvaluationMethodsLabel"]'),
        'deptCourseNo': text('#ctl00_MainContent_Dept_Cour_No').isNotEmpty
            ? text('#ctl00_MainContent_Dept_Cour_No')
            : text('span[id*="Dept_Cour_No"]'),
        'courseType': text('#ctl00_MainContent_Cour_TypeLabel').isNotEmpty
            ? text('#ctl00_MainContent_Cour_TypeLabel')
            : text('span[id*="Cour_TypeLabel"]'),
        'courseClass': text('#ctl00_MainContent_CourClassLabel').isNotEmpty
            ? text('#ctl00_MainContent_CourClassLabel')
            : text('span[id*="CourClassLabel"]'),
        'teacherEmailAndTel':
            text('#ctl00_MainContent_Teacher_emailAndTel').isNotEmpty
            ? text('#ctl00_MainContent_Teacher_emailAndTel')
            : text('span[id*="Teacher_emailAndTel"]'),
        'courseRemark':
            ('${text('#ctl00_MainContent_CourRemarkLabel')} ${text('#ctl00_MainContent_Remark')}')
                .trim(),
        'syllabus': [],
      };

      final syllabusRows = document.querySelectorAll(
        '#ctl00_MainContent_TabContainer1_TabPanel2_GridView2 tr',
      );
      for (var i = 1; i < syllabusRows.length; i++) {
        final tds = syllabusRows[i].querySelectorAll('td');
        if (tds.length >= 4) {
          courseDetail['syllabus'].add({
            'week': tds[0].text.trim(),
            'content': tds[1].text.trim(),
            'method': tds[2].text.trim(),
            'remark': tds[3].text.trim(),
          });
        }
      }

      return {'status': 'success', 'data': courseDetail};
    } catch (e) {
      // 先判離線再歸類其他錯誤；message 僅供除錯 log，不進 UI。
      if (isNetworkError(e)) {
        return {
          'status': 'network_error',
          'message': 'Network error fetching course detail: $e',
        };
      }
      return {
        'status': 'error',
        'message': 'Failed to fetch course detail: $e',
      };
    }
  }

  /// 輔助方法：在行中根據 ID 部分匹配尋找文字
  String _findTextById(dom.Element row, String idPart) {
    return row.querySelector('[id*="$idPart"]')?.text.trim() ?? '';
  }
}
