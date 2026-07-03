import 'grades_service.dart';

/// Demo / 除錯模式使用的 [GradesService]，回傳固定的 mock 成績與畢業門檻資料。
class MockGradesService implements GradesService {
  @override
  Future<Map<String, dynamic>> getGrades() async {
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

  @override
  Future<Map<String, dynamic>> getGraduation() async {
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
}
