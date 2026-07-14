import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../utils/network_error.dart';
import 'base_scraper.dart';

/// 處理畢業審核資料爬取的類別
class GraduationScraper extends BaseScraper {
  GraduationScraper(super.dio);

  static const String graduationUrl =
      'https://webapp.yuntech.edu.tw/WebNewCAS/Graduation/Score/StudGradCour.aspx';

  /// 獲取畢業審核資料
  Future<Map<String, dynamic>> getGraduation() async {
    try {
      if (kDebugMode)
        print(
          'GraduationScraper: Fetching graduation info from $graduationUrl',
        );

      final response = await getWithRedirects(
        graduationUrl,
        options: Options(
          headers: {
            ...commonHeaders,
            'Referer':
                'https://webapp.yuntech.edu.tw/WebNewCAS/StudentFile/Score/StudScores.aspx',
          },
        ),
      );

      final document = parseHtml(response.data);
      if (kDebugMode)
        print(
          'GraduationScraper: Page Title: ${document.querySelector('title')?.text.trim()}',
        );

      if (response.data.toString().contains('Login.aspx')) {
        return {
          'success': false,
          'status': 'session_expired',
          'message': 'Session expired',
        };
      }

      String getTextSafely(String id) {
        return document
                .querySelector('#ctl00_MainContent_oStudGradInfo_$id')
                ?.text
                .trim() ??
            '';
      }

      final data = {
        'total_credits': getTextSafely('totalCredits'),
        'english_threshold': getTextSafely('EngPass'),
        'internship_threshold': getTextSafely('InternshipPass'),
        'credits_breakdown': {
          'required_goal': {
            'pe': getTextSafely('Grd_MP'),
            'civilization': getTextSafely('Grd_I'),
            'literature': getTextSafely('Grd_J'),
            'general': getTextSafely('Grd_Com'),
            'dept_required': getTextSafely('Grd_MOpt'),
            'elective': getTextSafely('Grd_OSpe'),
            'total': getTextSafely('Grd_Total'),
          },
          'earned': {
            'pe': getTextSafely('Get_MP'),
            'civilization': getTextSafely('Get_I'),
            'literature': getTextSafely('Get_J'),
            'general': getTextSafely('Get_Com'),
            'dept_required': getTextSafely('Get_M1'),
            'dept_required_offset': getTextSafely('Get_M2'),
            'elective': getTextSafely('Get_O1'),
            'elective_offset': getTextSafely('Get_O2'),
            'elective_outer': getTextSafely('Get_EOSpe'),
            'total': getTextSafely('Get_Total'),
          },
          'not_received': {
            'pe': getTextSafely('NS_MP'),
            'civilization': getTextSafely('NS_I'),
            'literature': getTextSafely('NS_J'),
            'general': getTextSafely('NS_Com'),
            'dept_required': getTextSafely('NS_MOpt'),
            'elective': getTextSafely('NS_OSpe'),
            'elective_outer': getTextSafely('NS_EOSpe'),
            'total': getTextSafely('NS_Total'),
          },
          'missing': {
            'pe': getTextSafely('WithOut_MP'),
            'civilization': getTextSafely('WithOut_I'),
            'literature': getTextSafely('WithOut_J'),
            'general': getTextSafely('WithOut_Com'),
            'dept_required': getTextSafely('WithOut_MOpt'),
            'elective': getTextSafely('WithOut_OSpe'),
            'total': getTextSafely('WithOut_Total'),
          },
        },
        'missing_courses_text': getTextSafely('NotExistsFlowChart'),
      };

      if (kDebugMode)
        print('GraduationScraper: Successfully extracted graduation info');

      return {'success': true, 'graduation_info': data};
    } catch (e) {
      // 先判離線再歸類其他錯誤；message 僅供除錯 log，不進 UI。
      if (isNetworkError(e)) {
        return {
          'success': false,
          'status': 'network_error',
          'message': 'Network error fetching graduation info: $e',
        };
      }
      return {
        'success': false,
        'status': 'error',
        'message': 'Failed to fetch graduation info: $e',
      };
    }
  }
}
