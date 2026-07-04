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

      await getWithRedirects(
        'https://webapp.yuntech.edu.tw/WebNewCAS/StudentFile/Course/',
        options: Options(headers: commonHeaders),
      );

      final response = await getWithRedirects(
        gradesUrl,
        options: Options(
          headers: {
            ...commonHeaders,
            'Referer':
                'https://webapp.yuntech.edu.tw/WebNewCAS/StudentFile/Course/',
          },
        ),
      );

      final document = parseHtml(response.data);
      if (kDebugMode)
        print(
          'GradesScraper: Page Title: ${document.querySelector('title')?.text.trim()}',
        );

      if (response.data.toString().contains('Login.aspx')) {
        return {
          'success': false,
          'message': 'Session expired',
          'isExpired': true,
        };
      }

      final List<Map<String, dynamic>> gradesData = [];
      final Map<String, Map<String, dynamic>> semesterRankData = {};
      final Map<String, dynamic> cumulativeData = {};

      // 1. Fetch StudScoreRank.aspx for GPA and rankings
      try {
        if (kDebugMode) print('GradesScraper: Fetching StudScoreRank.aspx...');
        final rankResponse = await getWithRedirects(
          'https://webapp.yuntech.edu.tw/WebNewCAS/StudentFile/Score/StudScoreRank.aspx',
          options: Options(headers: {...commonHeaders, 'Referer': gradesUrl}),
        );

        if (rankResponse.data.toString().contains('Login.aspx')) {
          if (kDebugMode)
            print(
              'GradesScraper: StudScoreRank.aspx returned login page (session expired)!',
            );
        } else {
          final rankDoc = parseHtml(rankResponse.data);
          if (kDebugMode)
            print(
              'GradesScraper: StudScoreRank.aspx fetched successfully. Parsing...',
            );
          final rankGridView = rankDoc.querySelector(
            '#ctl00_MainContent_StudScore_GridView',
          );
          if (rankGridView != null) {
            final rows = rankGridView.querySelectorAll(
              'tr.GridView_Row, tr.GridView_AlternatingRow',
            );
            for (var row in rows) {
              final cells = row.querySelectorAll('td');
              if (cells.length >= 11) {
                final yearText = cells[0].text.trim();
                final semText = cells[1].text.trim();
                final conduct = cells[4].text
                    .trim()
                    .replaceAll('&nbsp;', '')
                    .trim();
                final attempted = cells[5].text
                    .trim()
                    .replaceAll('&nbsp;', '')
                    .trim();
                final earned = cells[6].text
                    .trim()
                    .replaceAll('&nbsp;', '')
                    .trim();
                final avgText = cells[7].text
                    .trim()
                    .replaceAll('&nbsp;', '')
                    .trim();
                final rankText = cells[8].text
                    .trim()
                    .replaceAll('&nbsp;', '')
                    .trim();
                final totalText = cells[9].text
                    .trim()
                    .replaceAll('&nbsp;', '')
                    .trim();
                final gpaText = cells[10].text
                    .trim()
                    .replaceAll('&nbsp;', '')
                    .trim();

                final key = '$yearText-$semText';
                semesterRankData[key] = {
                  'conduct': conduct,
                  'attempted_credits': attempted,
                  'earned_credits': earned,
                  'average': avgText,
                  'rank': rankText,
                  'total_students': totalText,
                  'gpa': gpaText,
                };
              }
            }
          }

          // Parse Cumulative Table
          final totalTable = rankDoc.querySelector(
            '#ctl00_MainContent_TotalScore_Table',
          );
          if (totalTable != null) {
            if (kDebugMode)
              print(
                'GradesScraper: Total table found. Parsing cumulative stats...',
              );
            final sCredits =
                totalTable
                    .querySelector('#ctl00_MainContent_Total_SCredits')
                    ?.text
                    .trim() ??
                '';
            final rCredits =
                totalTable
                    .querySelector('#ctl00_MainContent_Total_RCredits')
                    ?.text
                    .trim() ??
                '';
            final avg =
                totalTable
                    .querySelector('#ctl00_MainContent_Total_Avg')
                    ?.text
                    .trim() ??
                '';
            final rank =
                totalTable
                    .querySelector('#ctl00_MainContent_Total_Rank')
                    ?.text
                    .trim() ??
                '';
            final totalStudents =
                totalTable
                    .querySelector('#ctl00_MainContent_Total_StudNum')
                    ?.text
                    .trim() ??
                '';
            final gpa =
                totalTable
                    .querySelector('#ctl00_MainContent_Total_GPA')
                    ?.text
                    .trim() ??
                '';

            cumulativeData['attempted_credits'] = sCredits;
            cumulativeData['earned_credits'] = rCredits;
            cumulativeData['average'] = avg;
            cumulativeData['rank'] = rank;
            cumulativeData['total_students'] = totalStudents;
            cumulativeData['gpa'] = gpa;
            if (kDebugMode)
              print(
                'GradesScraper: Cumulative GPA: $gpa, average: $avg, rank: $rank/$totalStudents',
              );
          } else {
            if (kDebugMode) print('GradesScraper: Total table not found!');
          }
        }
      } catch (e) {
        if (kDebugMode)
          print('GradesScraper: Error fetching or parsing rank data: $e');
      }

      final semesterBlocks = document.querySelectorAll('.col-lg-6.col-md-12');

      for (var block in semesterBlocks) {
        final titleElement = block.querySelector('.GridView_Header span');
        if (titleElement == null) continue;

        final semesterTitle = titleElement.text.trim();

        final regExp = RegExp(r'第\s*(\d+)\s*學年第\s*(\d+)\s*學期');
        final match = regExp.firstMatch(semesterTitle);
        int academicYear = 0;
        int semester = 0;
        if (match != null) {
          academicYear = int.parse(match.group(1)!);
          semester = int.parse(match.group(2)!);
        }

        final List<Map<String, dynamic>> courses = [];

        final rows = block.querySelectorAll(
          'tr.DataGrid_Item, tr.DataGrid_AlternatingItem',
        );

        for (var row in rows) {
          final code =
              row.querySelector('span[id*="_Dept_Cour_No"]')?.text.trim() ?? '';
          final courseAnchor = row.querySelector('a[id*="_cour_cname"]');

          if (code.isNotEmpty && courseAnchor != null) {
            final nameZh = courseAnchor.text.trim();
            final nameEn =
                row.querySelector('span[id*="_cour_ename"]')?.text.trim() ?? '';
            final type =
                row.querySelector('span[id*="_maj_op"]')?.text.trim() ?? '';
            final credits =
                row.querySelector('span[id*="_credits"]')?.text.trim() ?? '';
            final score =
                row.querySelector('span[id*="_Score"]')?.text.trim() ?? '';

            String syllabusUrl = '';
            String courseNo = '';
            final relativeHref = courseAnchor.attributes['href'];
            if (relativeHref != null && relativeHref.isNotEmpty) {
              syllabusUrl = relativeHref.replaceFirst(
                RegExp(r'^(\.\.\/)+'),
                'https://webapp.yuntech.edu.tw/WebNewCAS/',
              );
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
              'syllabusUrl': syllabusUrl,
            });
          }
        }

        if (courses.isNotEmpty) {
          final key = '$academicYear-$semester';
          final rankInfo = semesterRankData[key];

          gradesData.add({
            'academic_year': academicYear,
            'semester': semester,
            'semester_title': semesterTitle,
            'courses': courses,
            'summary': {
              'average_score': rankInfo?['average'] ?? '',
              'rank':
                  rankInfo != null &&
                      rankInfo['rank'] != null &&
                      rankInfo['rank'].toString().isNotEmpty
                  ? '${rankInfo['rank']} / ${rankInfo['total_students']}'
                  : '',
              'gpa': rankInfo?['gpa'] ?? '',
              'conduct': rankInfo?['conduct'] ?? '',
              'attempted_credits': rankInfo?['attempted_credits'] ?? '',
              'earned_credits': rankInfo?['earned_credits'] ?? '',
            },
          });
        }
      }

      if (kDebugMode)
        print('GradesScraper: Found ${gradesData.length} semesters');

      return {
        'success': true,
        'grades': gradesData,
        'cumulative': cumulativeData.isNotEmpty ? cumulativeData : null,
      };
    } catch (e) {
      return {'success': false, 'message': '抓取成績失敗: $e'};
    }
  }
}
