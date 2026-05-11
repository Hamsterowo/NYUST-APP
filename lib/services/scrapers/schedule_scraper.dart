import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:html/dom.dart' as dom;
import 'base_scraper.dart';

/// 處理課表資料爬取的類別
class ScheduleScraper extends BaseScraper {
  ScheduleScraper(super.dio);

  static const String scheduleUrl =
      'https://webapp.yuntech.edu.tw/WebNewCAS/StudentFile/Course/';

  /// 獲取學生課表資料
  Future<Map<String, dynamic>> getSchedule() async {
    try {
      if (kDebugMode) print('ScheduleScraper: Fetching schedule from $scheduleUrl');
      
      final response = await getWithRedirects(
        scheduleUrl,
        options: Options(
          headers: {
            ...commonHeaders,
            'Referer': 'https://webapp.yuntech.edu.tw/YunTechSSO/Account/Login',
          },
        ),
      );

      final document = parseHtml(response.data);
      if (kDebugMode) print('ScheduleScraper: Page Title: ${document.querySelector('title')?.text.trim()}');

      // 檢查是否被導向回登入頁面 (Session Expired)
      if (response.data.toString().contains('Login.aspx') ||
          document.querySelector('form[action="./Login/Login.aspx"]') != null) {
        return {
          'status': 'error',
          'message': 'Session expired, please login again',
          'isExpired': true
        };
      }

      final List<Map<String, dynamic>> courses = [];

      // 參考 schedule.js: $('[id*="_cour_cname"]')
      final courseLinks = document.querySelectorAll('[id*="_cour_cname"]');

      for (var anchor in courseLinks) {
        final name = anchor.text.trim();
        // 找到該欄位所屬的 tr (TableRow)
        dom.Element? row = anchor.parent;
        while (row != null && row.localName != 'tr') {
          row = row.parent;
        }

        if (row != null && name.isNotEmpty) {
          // 提取網址與參數 (參考 schedule.js)
          String syllabusUrl = '';
          String year = '';
          String semester = '';
          String courseNo = '';
          final relativeHref = anchor.attributes['href'];
          
          if (relativeHref != null && relativeHref.isNotEmpty) {
            syllabusUrl = relativeHref.replaceFirst(RegExp(r'^(\.\.\/)+'), 
                'https://webapp.yuntech.edu.tw/WebNewCAS/');
            
            final parts = relativeHref.split('&');
            if (parts.length >= 4) {
              year = parts[1];
              semester = parts[2];
              courseNo = parts[3];
            }
          }

          // 擷取各欄位內容
          final semesterCourseNo = _findTextById(row, '_current_subj');
          final deptCourseNo = _findTextById(row, '_Dept_Cour_No');
          final courseClass = _findTextById(row, '_Cour_Class');
          final classType = _findTextById(row, '_Subj_Team');
          final requiredType = _findTextById(row, '_maj_op');
          final credits = _findTextById(row, '_credits');
          final timeRoomStr = _findTextById(row, '_Cour_Time');
          final teacher = _findTextById(row, '_cour_emp');

          // 備註處理
          String remark = '';
          final remarkElements = row.querySelectorAll(
            'span[id*="_comm"], span[id*="_CourRemark_00"], span[id*="_Remark_00_01"], span[id*="_remark_00_02"]'
          );
          for (var rEl in remarkElements) {
            final rText = rEl.text.trim();
            if (rText.isNotEmpty) {
              remark += '$rText ';
            }
          }

          // 拆解時間與教室 (與 schedule.js 邏輯一致)
          String weekday = '';
          List<String> times = [];
          String room = '';

          if (timeRoomStr.isNotEmpty) {
            final parts = timeRoomStr.split('/');
            if (parts.length == 2) {
              final timePart = parts[0]; // 例如 "1-GH"
              room = parts[1];           // 例如 "DH303"

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
            'courseNo': courseNo
          });
        }
      }

      if (kDebugMode) print('ScheduleScraper: Found ${courses.length} courses');

      return {
        'status': 'success',
        'data': {
          'schedule': courses
        }
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': '抓取課表失敗: $e',
      };
    }
  }

  /// 獲取課程詳細資訊 (大綱)
  Future<Map<String, dynamic>> getCourseDetail({
    required String year,
    required String semester,
    required String courseNo,
  }) async {
    try {
      // 參考 schedule.js: 組合課綱網址
      final detailUrl =
          'https://webapp.yuntech.edu.tw/WebNewCAS/Course/Plan/Query.aspx?&$year&$semester&$courseNo';
      
      if (kDebugMode) print('ScheduleScraper: Fetching course detail from $detailUrl');

      final response = await getWithRedirects(
        detailUrl,
        options: Options(
          headers: {
            ...commonHeaders,
          },
        ),
      );

      final document = parseHtml(response.data);

      // Helper 參考 schedule.js
      String text(String selector) => document.querySelector(selector)?.text.trim() ?? '';

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
        'teacherEmailAndTel': text('#ctl00_MainContent_Teacher_emailAndTel').isNotEmpty 
            ? text('#ctl00_MainContent_Teacher_emailAndTel') 
            : text('span[id*="Teacher_emailAndTel"]'),
        'courseRemark': (text('#ctl00_MainContent_CourRemarkLabel') + ' ' + text('#ctl00_MainContent_Remark')).trim(),
        'syllabus': []
      };

      // 擷取每週教學進度
      final syllabusRows = document.querySelectorAll('#ctl00_MainContent_TabContainer1_TabPanel2_GridView2 tr');
      for (var i = 1; i < syllabusRows.length; i++) {
        final tds = syllabusRows[i].querySelectorAll('td');
        if (tds.length >= 4) {
          courseDetail['syllabus'].add({
            'week': tds[0].text.trim(),
            'content': tds[1].text.trim(),
            'method': tds[2].text.trim(),
            'remark': tds[3].text.trim()
          });
        }
      }

      return {
        'status': 'success',
        'data': courseDetail
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': '獲取課程詳情失敗: $e',
      };
    }
  }

  /// 輔助方法：在行中根據 ID 部分匹配尋找文字
  String _findTextById(dom.Element row, String idPart) {
    return row.querySelector('[id*="$idPart"]')?.text.trim() ?? '';
  }
}
