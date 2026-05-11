import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'base_scraper.dart';

/// 處理成績資料爬取的類別
class GradesScraper extends BaseScraper {
  GradesScraper(super.dio);

  static const String gradesUrl =
      'https://webapp.yuntech.edu.tw/WebNewCAS/StudentFile/Score/StudScores.aspx';

  /// 獲取歷年成績資料
  Future<Map<String, dynamic>> getGrades() async {
    try {
      if (kDebugMode) print('GradesScraper: Fetching grades from $gradesUrl');

      // 修正 Access Deny: 先「路過」一下選課頁面以建立 WebNewCAS Session
      await getWithRedirects(
        'https://webapp.yuntech.edu.tw/WebNewCAS/StudentFile/Course/',
        options: Options(headers: commonHeaders),
      );

      final response = await getWithRedirects(
        gradesUrl,
        options: Options(
          headers: {
            ...commonHeaders,
            'Referer': 'https://webapp.yuntech.edu.tw/WebNewCAS/StudentFile/Course/',
          },
        ),
      );

      final document = parseHtml(response.data);
      if (kDebugMode) print('GradesScraper: Page Title: ${document.querySelector('title')?.text.trim()}');
      
      // 檢查是否被導向回登入頁面
      if (response.data.toString().contains('Login.aspx')) {
        return {
          'success': false,
          'message': 'Session expired',
          'isExpired': true
        };
      }

      final List<Map<String, dynamic>> gradesData = [];

      // 參考 academic.js: $('.col-lg-6.col-md-12')
      final semesterBlocks = document.querySelectorAll('.col-lg-6.col-md-12');

      for (var block in semesterBlocks) {
        final titleElement = block.querySelector('.GridView_Header span');
        if (titleElement == null) continue;

        final semesterTitle = titleElement.text.trim(); // e.g., "第 114 學年第1 學期"

        // 解析學年與學期 (參考 academic.js Regex)
        final regExp = RegExp(r'第\s*(\d+)\s*學年第\s*(\d+)\s*學期');
        final match = regExp.firstMatch(semesterTitle);
        int academicYear = 0;
        int semester = 0;
        if (match != null) {
          academicYear = int.parse(match.group(1)!);
          semester = int.parse(match.group(2)!);
        }

        final List<Map<String, dynamic>> courses = [];
        // 參考 academic.js: $(block).find('tr.DataGrid_Item, tr.DataGrid_AlternatingItem')
        final rows = block.querySelectorAll('tr.DataGrid_Item, tr.DataGrid_AlternatingItem');

        for (var row in rows) {
          final code = row.querySelector('span[id*="_Dept_Cour_No"]')?.text.trim() ?? '';
          final courseAnchor = row.querySelector('a[id*="_cour_cname"]');
          
          if (code.isNotEmpty && courseAnchor != null) {
            final nameZh = courseAnchor.text.trim();
            final nameEn = row.querySelector('span[id*="_cour_ename"]')?.text.trim() ?? '';
            final type = row.querySelector('span[id*="_maj_op"]')?.text.trim() ?? '';
            final credits = row.querySelector('span[id*="_credits"]')?.text.trim() ?? '';
            final score = row.querySelector('span[id*="_Score"]')?.text.trim() ?? '';

            String syllabusUrl = '';
            String courseNo = '';
            final relativeHref = courseAnchor.attributes['href'];
            if (relativeHref != null && relativeHref.isNotEmpty) {
              syllabusUrl = relativeHref.replaceFirst(RegExp(r'^(\.\.\/)+'), 
                  'https://webapp.yuntech.edu.tw/WebNewCAS/');
              final parts = relativeHref.split('&');
              if (parts.length >= 4) {
                courseNo = parts.last;
              }
            }

            courses.add({
              'code': code,
              'courseNo': courseNo,
              'name': nameZh,
              'name_en': nameEn,
              'type': type,
              'credits': credits,
              'score': score,
              'syllabusUrl': syllabusUrl
            });
          }
        }

        if (courses.isNotEmpty) {
          gradesData.add({
            'academic_year': academicYear,
            'semester': semester,
            'semester_title': semesterTitle,
            'courses': courses
          });
        }
      }

      if (kDebugMode) print('GradesScraper: Found ${gradesData.length} semesters');

      return {
        'success': true,
        'grades': gradesData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': '抓取成績失敗: $e',
      };
    }
  }
}
