/// Demo 模式靜態資料——所有 mock service 的唯一來源。
///
/// 學生設定：B11212345 王小明，112 學年入學（資工系），
/// 成績橫跨 112 上 ~ 114 上（3 個學年 5 學期），目前修讀 114 下。
/// 所有學分數與畢業審核互相吻合。
library;

class MockData {
  MockData._();

  // ── 帳號 ────────────────────────────────────────────

  /// Demo 學號。同時作為冷啟動辨識 mock session 的依據。
  static const String demoId = 'B11212345';

  /// 登入時觸發 demo 模式的帳號名稱。
  static const String demoUsername = 'demo';

  /// 判斷傳入的帳號是否為 demo 帳號。
  static bool isDemoAccount(String username) =>
      username.toLowerCase() == demoUsername;

  /// Mock 使用者資料。鍵值對齊 `InfoScraper.getUserInfo()` 的實際輸出
  /// （中文欄位名 + `name`／`department` 英文別名），設定頁才能正確顯示；
  /// 另保留 `id` 供 `AuthProvider.init()` 於冷啟動辨識 mock session。
  static const Map<String, dynamic> user = {
    '入學年制': '四技',
    '學號': demoId,
    '姓名': '王小明',
    '系(所)別': '資訊工程學系',
    '班級': '資工三甲',
    '性別': '男',
    'name': '王小明',
    'department': '資訊工程學系',
    'id': demoId,
  };

  // ── 成績（5 學期 × 3 學年）──────────────────────────

  static Map<String, dynamic> get grades => {
    'success': true,
    'grades': [
      _semester112_1,
      _semester112_2,
      _semester113_1,
      _semester113_2,
      _semester114_1,
    ],
    'cumulative': {
      'attempted_credits': '91',
      'earned_credits': '91',
      'average': '84.6',
      'rank': '8',
      'total_students': '52',
      'gpa': '3.52',
    },
  };

  // ── 112 上（大一上）19 學分 ──

  static const Map<String, dynamic> _semester112_1 = {
    'academic_year': '112',
    'semester': '1',
    'semester_title': '112學年第1學期',
    'summary': {
      'average_score': '83.4',
      'rank': '12 / 52',
      'gpa': '3.38',
      'conduct': '86',
      'attempted_credits': '19',
      'earned_credits': '19',
    },
    'courses': [
      {
        'code': 'MAT1001',
        'courseNo': '10101',
        'name': '微積分(一)',
        'name_en': 'Calculus I',
        'type': '必修',
        'credits': '3.0',
        'score': '78',
        'syllabusUrl': '',
      },
      {
        'code': 'PHY1001',
        'courseNo': '10102',
        'name': '普通物理',
        'name_en': 'General Physics',
        'type': '必修',
        'credits': '3.0',
        'score': '82',
        'syllabusUrl': '',
      },
      {
        'code': 'CSE1001',
        'courseNo': '10103',
        'name': '計算機概論',
        'name_en': 'Introduction to Computer Science',
        'type': '必修',
        'credits': '3.0',
        'score': '91',
        'syllabusUrl': '',
      },
      {
        'code': 'CSE1002',
        'courseNo': '10104',
        'name': '程式設計(一)',
        'name_en': 'Programming I',
        'type': '必修',
        'credits': '3.0',
        'score': '88',
        'syllabusUrl': '',
      },
      {
        'code': 'ENG1001',
        'courseNo': '10105',
        'name': '英文(一)',
        'name_en': 'English I',
        'type': '必修',
        'credits': '2.0',
        'score': '75',
        'syllabusUrl': '',
      },
      {
        'code': 'PE1001',
        'courseNo': '10106',
        'name': '體育(一)',
        'name_en': 'Physical Education I',
        'type': '必修',
        'credits': '1.0',
        'score': '85',
        'syllabusUrl': '',
      },
      {
        'code': 'GEN1001',
        'courseNo': '10107',
        'name': '大學入門',
        'name_en': 'Introduction to University',
        'type': '必修',
        'credits': '2.0',
        'score': '90',
        'syllabusUrl': '',
      },
      {
        'code': 'GEC1001',
        'courseNo': '10108',
        'name': '文明與經典閱讀',
        'name_en': 'Civilization and Classic Reading',
        'type': '通識',
        'credits': '2.0',
        'score': '84',
        'syllabusUrl': '',
      },
    ],
  };

  // ── 112 下（大一下）19 學分 ──

  static const Map<String, dynamic> _semester112_2 = {
    'academic_year': '112',
    'semester': '2',
    'semester_title': '112學年第2學期',
    'summary': {
      'average_score': '81.5',
      'rank': '16 / 52',
      'gpa': '3.30',
      'conduct': '85',
      'attempted_credits': '19',
      'earned_credits': '19',
    },
    'courses': [
      {
        'code': 'MAT1002',
        'courseNo': '10201',
        'name': '微積分(二)',
        'name_en': 'Calculus II',
        'type': '必修',
        'credits': '3.0',
        'score': '80',
        'syllabusUrl': '',
      },
      {
        'code': 'CSE1003',
        'courseNo': '10202',
        'name': '計算機組織',
        'name_en': 'Computer Organization',
        'type': '必修',
        'credits': '3.0',
        'score': '76',
        'syllabusUrl': '',
      },
      {
        'code': 'CSE1004',
        'courseNo': '10203',
        'name': '程式設計(二)',
        'name_en': 'Programming II',
        'type': '必修',
        'credits': '3.0',
        'score': '92',
        'syllabusUrl': '',
      },
      {
        'code': 'MAT1003',
        'courseNo': '10204',
        'name': '線性代數',
        'name_en': 'Linear Algebra',
        'type': '必修',
        'credits': '3.0',
        'score': '71',
        'syllabusUrl': '',
      },
      {
        'code': 'ENG1002',
        'courseNo': '10205',
        'name': '英文(二)',
        'name_en': 'English II',
        'type': '必修',
        'credits': '2.0',
        'score': '78',
        'syllabusUrl': '',
      },
      {
        'code': 'PE1002',
        'courseNo': '10206',
        'name': '體育(二)',
        'name_en': 'Physical Education II',
        'type': '必修',
        'credits': '1.0',
        'score': '88',
        'syllabusUrl': '',
      },
      {
        'code': 'GEC1002',
        'courseNo': '10207',
        'name': '社會學與當代議題',
        'name_en': 'Sociology and Contemporary Issues',
        'type': '通識',
        'credits': '2.0',
        'score': '86',
        'syllabusUrl': '',
      },
      {
        'code': 'GEC1003',
        'courseNo': '10208',
        'name': '文學賞析',
        'name_en': 'Literary Appreciation',
        'type': '通識',
        'credits': '2.0',
        'score': '91',
        'syllabusUrl': '',
      },
    ],
  };

  // ── 113 上（大二上）18 學分 ──

  static const Map<String, dynamic> _semester113_1 = {
    'academic_year': '113',
    'semester': '1',
    'semester_title': '113學年第1學期',
    'summary': {
      'average_score': '84.8',
      'rank': '10 / 52',
      'gpa': '3.50',
      'conduct': '88',
      'attempted_credits': '18',
      'earned_credits': '18',
    },
    'courses': [
      {
        'code': 'CSE2001',
        'courseNo': '20101',
        'name': '資料結構',
        'name_en': 'Data Structures',
        'type': '必修',
        'credits': '3.0',
        'score': '85',
        'syllabusUrl': '',
      },
      {
        'code': 'CSE2002',
        'courseNo': '20102',
        'name': '離散數學',
        'name_en': 'Discrete Mathematics',
        'type': '必修',
        'credits': '3.0',
        'score': '79',
        'syllabusUrl': '',
      },
      {
        'code': 'CSE2003',
        'courseNo': '20103',
        'name': '數位邏輯設計',
        'name_en': 'Digital Logic Design',
        'type': '必修',
        'credits': '3.0',
        'score': '83',
        'syllabusUrl': '',
      },
      {
        'code': 'MAT2001',
        'courseNo': '20104',
        'name': '機率與統計',
        'name_en': 'Probability and Statistics',
        'type': '必修',
        'credits': '3.0',
        'score': '77',
        'syllabusUrl': '',
      },
      {
        'code': 'CSE2004',
        'courseNo': '20105',
        'name': '物件導向程式設計',
        'name_en': 'Object-Oriented Programming',
        'type': '選修',
        'credits': '3.0',
        'score': '93',
        'syllabusUrl': '',
      },
      {
        'code': 'GEC2001',
        'courseNo': '20106',
        'name': '藝術與美學',
        'name_en': 'Art and Aesthetics',
        'type': '通識',
        'credits': '2.0',
        'score': '87',
        'syllabusUrl': '',
      },
      {
        'code': 'PE2001',
        'courseNo': '20107',
        'name': '體育(三)',
        'name_en': 'Physical Education III',
        'type': '必修',
        'credits': '1.0',
        'score': '90',
        'syllabusUrl': '',
      },
    ],
  };

  // ── 113 下（大二下）18 學分 ──

  static const Map<String, dynamic> _semester113_2 = {
    'academic_year': '113',
    'semester': '2',
    'semester_title': '113學年第2學期',
    'summary': {
      'average_score': '86.3',
      'rank': '7 / 52',
      'gpa': '3.60',
      'conduct': '90',
      'attempted_credits': '18',
      'earned_credits': '18',
    },
    'courses': [
      {
        'code': 'CSE2005',
        'courseNo': '20201',
        'name': '演算法',
        'name_en': 'Algorithms',
        'type': '必修',
        'credits': '3.0',
        'score': '88',
        'syllabusUrl': '',
      },
      {
        'code': 'CSE2006',
        'courseNo': '20202',
        'name': '作業系統',
        'name_en': 'Operating Systems',
        'type': '必修',
        'credits': '3.0',
        'score': '82',
        'syllabusUrl': '',
      },
      {
        'code': 'CSE2007',
        'courseNo': '20203',
        'name': '組合語言與系統程式',
        'name_en': 'Assembly Language and System Programming',
        'type': '必修',
        'credits': '3.0',
        'score': '75',
        'syllabusUrl': '',
      },
      {
        'code': 'CSE2008',
        'courseNo': '20204',
        'name': '資料庫系統',
        'name_en': 'Database Systems',
        'type': '選修',
        'credits': '3.0',
        'score': '90',
        'syllabusUrl': '',
      },
      {
        'code': 'CSE2009',
        'courseNo': '20205',
        'name': '網頁程式設計',
        'name_en': 'Web Programming',
        'type': '選修',
        'credits': '3.0',
        'score': '95',
        'syllabusUrl': '',
      },
      {
        'code': 'GEC2002',
        'courseNo': '20206',
        'name': '歷史與文化',
        'name_en': 'History and Culture',
        'type': '通識',
        'credits': '2.0',
        'score': '88',
        'syllabusUrl': '',
      },
      {
        'code': 'PE2002',
        'courseNo': '20207',
        'name': '體育(四)',
        'name_en': 'Physical Education IV',
        'type': '必修',
        'credits': '1.0',
        'score': '87',
        'syllabusUrl': '',
      },
    ],
  };

  // ── 114 上（大三上）17 學分 ──

  static const Map<String, dynamic> _semester114_1 = {
    'academic_year': '114',
    'semester': '1',
    'semester_title': '114學年第1學期',
    'summary': {
      'average_score': '88.5',
      'rank': '5 / 52',
      'gpa': '3.75',
      'conduct': '91',
      'attempted_credits': '17',
      'earned_credits': '17',
    },
    'courses': [
      {
        'code': 'CSE3001',
        'courseNo': '30101',
        'name': '電腦網路',
        'name_en': 'Computer Networks',
        'type': '必修',
        'credits': '3.0',
        'score': '86',
        'syllabusUrl': '',
      },
      {
        'code': 'CSE3002',
        'courseNo': '30102',
        'name': '軟體工程',
        'name_en': 'Software Engineering',
        'type': '必修',
        'credits': '3.0',
        'score': '91',
        'syllabusUrl': '',
      },
      {
        'code': 'CSE3003',
        'courseNo': '30103',
        'name': '編譯器設計',
        'name_en': 'Compiler Design',
        'type': '必修',
        'credits': '3.0',
        'score': '78',
        'syllabusUrl': '',
      },
      {
        'code': 'CSE3004',
        'courseNo': '30104',
        'name': '行動裝置程式設計',
        'name_en': 'Mobile Application Development',
        'type': '選修',
        'credits': '3.0',
        'score': '97',
        'syllabusUrl': '',
      },
      {
        'code': 'CSE3005',
        'courseNo': '30105',
        'name': '專題實作(一)',
        'name_en': 'Senior Project I',
        'type': '必修',
        'credits': '2.0',
        'score': '92',
        'syllabusUrl': '',
      },
      {
        'code': 'CSE3006',
        'courseNo': '30106',
        'name': '人工智慧導論',
        'name_en': 'Introduction to Artificial Intelligence',
        'type': '選修',
        'credits': '3.0',
        'score': '89',
        'syllabusUrl': '',
      },
    ],
  };

  // ── 畢業審核 ───────────────────────────────────────

  /// 學分合計：體育 4 + 文明 2 + 文學 2 + 通識 6 + 系必修 62 + 選修 15 = 91
  static Map<String, dynamic> get graduation => {
    'success': true,
    'graduation_info': {
      'total_credits': '91',
      'english_threshold': '未通過',
      'internship_threshold': '未修過',
      'credits_breakdown': {
        'required_goal': {
          'pe': '4',
          'civilization': '2',
          'literature': '2',
          'general': '8',
          'dept_required': '63',
          'elective': '49',
          'total': '128',
        },
        'earned': {
          'pe': '4',
          'civilization': '2',
          'literature': '2',
          'general': '6',
          'dept_required': '62',
          'elective': '15',
          'total': '91',
        },
        'missing': {
          'pe': '0',
          'civilization': '0',
          'literature': '0',
          'general': '2',
          'dept_required': '1',
          'elective': '34',
          'total': '37',
        },
      },
      'missing_courses_text': 'CSE3007工程倫理與產業導論[3]、實習課程[0]',
    },
  };

  // ── 課表（114 下・大三下・目前修讀）────────────────

  // ── 課表（多學期）─────────────────────────────────────
  /// Demo 模式可切換的學期清單（對應各 `_courses*`）。
  static const List<Map<String, String>> _scheduleSemesters = [
    {'value': '1142', 'label': '114學年第2學期'},
    {'value': '1141', 'label': '114學年第1學期'},
    {'value': '1132', 'label': '113學年第2學期'},
  ];

  static const String _currentSemester = '1142';

  static Map<String, dynamic> get schedule => scheduleFor(null);

  /// Demo 模式的課表：依 [semester] 回傳對應學期課程，一律附上學期清單與
  /// 當前學期，讓測試帳號也能看到並操作學期切換器。
  static Map<String, dynamic> scheduleFor(String? semester) {
    final sem = (semester == null || semester.isEmpty)
        ? _currentSemester
        : semester;
    final courses = switch (sem) {
      '1141' => _courses1141,
      '1132' => _courses1132,
      _ => _courses1142,
    };
    return {
      'status': 'success',
      'data': {
        'schedule': courses,
        'semesters': _scheduleSemesters,
        'currentSemester': _currentSemester,
      },
    };
  }

  // ── 請假記錄 ────────────────────────────────────────
  /// 請假記錄的學年期清單（value 形如 `114,2`，對齊真實頁面）。
  static const List<Map<String, String>> _absentSemesters = [
    {'value': '114,2', 'label': '114學年第2學期'},
    {'value': '114,1', 'label': '114學年第1學期'},
  ];

  static const String _absentCurrentSemester = '114,2';

  /// Demo 模式的請假記錄：依 [semester] 回傳對應學年期記錄。
  static Map<String, dynamic> absentFor(String? semester) {
    final sem = (semester == null || semester.isEmpty)
        ? _absentCurrentSemester
        : semester;
    final records = switch (sem) {
      '114,1' => _absent1141,
      _ => _absent1142,
    };
    return {
      'status': 'success',
      'data': {
        'records': records,
        'semesters': _absentSemesters,
        'currentSemester': _absentCurrentSemester,
      },
    };
  }

  static const List<Map<String, dynamic>> _absent1142 = [
    {
      'formNo': '0000000009900001',
      'proofDoc': '紙本',
      'year': '114',
      'semester': '2',
      'formType': '一般請假',
      'leaveType': '病假',
      'subType': '',
      'startDate': '115/03/12',
      'startTime': '08',
      'startSection': 'A',
      'endDate': '115/03/12',
      'endTime': '12',
      'endSection': 'D',
      'hours': '4',
      'status': '已核可',
    },
    {
      'formNo': '0000000009900002',
      'proofDoc': '電子',
      'year': '114',
      'semester': '2',
      'formType': '一般請假',
      'leaveType': '事假',
      'subType': '',
      'startDate': '115/04/08',
      'startTime': '13',
      'startSection': 'E',
      'endDate': '115/04/08',
      'endTime': '15',
      'endSection': 'F',
      'hours': '2',
      'status': '審核中',
    },
    {
      'formNo': '0000000009900003',
      'proofDoc': '紙本',
      'year': '114',
      'semester': '2',
      'formType': '一般請假',
      'leaveType': '公假',
      'subType': '',
      'startDate': '115/05/20',
      'startTime': '08',
      'startSection': 'A',
      'endDate': '115/05/21',
      'endTime': '17',
      'endSection': 'H',
      'hours': '16',
      'status': '已核可',
    },
  ];

  static const List<Map<String, dynamic>> _absent1141 = [
    {
      'formNo': '0000000009800001',
      'proofDoc': '紙本',
      'year': '114',
      'semester': '1',
      'formType': '一般請假',
      'leaveType': '病假',
      'subType': '',
      'startDate': '114/11/03',
      'startTime': '10',
      'startSection': 'C',
      'endDate': '114/11/03',
      'endTime': '12',
      'endSection': 'D',
      'hours': '2',
      'status': '已核可',
    },
  ];

  static const List<Map<String, dynamic>> _courses1142 = [
    {
      'semesterCourseNo': '11420099',
      'deptCourseNo': 'CSE4001',
      'name': '專題實作',
      'nameEn': 'Special Topics Project',
      'courseClass': '資工三甲',
      'classType': '甲組',
      'requiredType': '必修',
      'credits': '2',
      'timeRoomStr': '',
      'teacher': '陳建志',
      'remark': '',
      'times': <String>[],
      'weekday': '',
      'room': '',
      'syllabusUrl': '',
      'year': '114',
      'semester': '2',
      'courseNo': '30299',
    },
    {
      'semesterCourseNo': '11420001',
      'deptCourseNo': 'CSE3007',
      'name': '人機互動技術',
      'nameEn': 'Human-Computer Interaction',
      'courseClass': '資工三甲',
      'classType': '',
      'requiredType': '選修',
      'credits': '3',
      'timeRoomStr': '1-C,D/EL101',
      'teacher': '張育銘',
      'remark': '',
      'times': ['C', 'D'],
      'weekday': '1',
      'room': 'EL101',
      'syllabusUrl': '',
      'year': '114',
      'semester': '2',
      'courseNo': '30201',
    },
    {
      'semesterCourseNo': '11420002',
      'deptCourseNo': 'CSE3008',
      'name': '雲端計算',
      'nameEn': 'Cloud Computing',
      'courseClass': '資工三甲',
      'classType': '',
      'requiredType': '選修',
      'credits': '3',
      'timeRoomStr': '2-E,F/EL205',
      'teacher': '林明宏',
      'remark': '',
      'times': ['E', 'F'],
      'weekday': '2',
      'room': 'EL205',
      'syllabusUrl': '',
      'year': '114',
      'semester': '2',
      'courseNo': '30202',
    },
    {
      'semesterCourseNo': '11420003',
      'deptCourseNo': 'CSE3009',
      'name': '計算機結構',
      'nameEn': 'Computer Architecture',
      'courseClass': '資工三甲',
      'classType': '',
      'requiredType': '必修',
      'credits': '3',
      'timeRoomStr': '3-A,B/EL102',
      'teacher': '陳俊達',
      'remark': '',
      'times': ['A', 'B'],
      'weekday': '3',
      'room': 'EL102',
      'syllabusUrl': '',
      'year': '114',
      'semester': '2',
      'courseNo': '30203',
    },
    {
      'semesterCourseNo': '11420004',
      'deptCourseNo': 'CSE3010',
      'name': '專題實作(二)',
      'nameEn': 'Senior Project II',
      'courseClass': '資工三甲',
      'classType': '',
      'requiredType': '必修',
      'credits': '2',
      'timeRoomStr': '4-G,H/EL108',
      'teacher': '張育銘',
      'remark': '',
      'times': ['G', 'H'],
      'weekday': '4',
      'room': 'EL108',
      'syllabusUrl': '',
      'year': '114',
      'semester': '2',
      'courseNo': '30204',
    },
    {
      'semesterCourseNo': '11420005',
      'deptCourseNo': 'CSE3011',
      'name': '資訊安全',
      'nameEn': 'Information Security',
      'courseClass': '資工三甲',
      'classType': '',
      'requiredType': '選修',
      'credits': '3',
      'timeRoomStr': '5-B,C/EL301',
      'teacher': '李佳穎',
      'remark': '',
      'times': ['B', 'C'],
      'weekday': '5',
      'room': 'EL301',
      'syllabusUrl': '',
      'year': '114',
      'semester': '2',
      'courseNo': '30205',
    },
    {
      'semesterCourseNo': '11420006',
      'deptCourseNo': 'CSE3012',
      'name': '工程倫理與產業導論',
      'nameEn': 'Engineering Ethics and Industry Introduction',
      'courseClass': '資工三甲',
      'classType': '',
      'requiredType': '必修',
      'credits': '2',
      'timeRoomStr': '3-E,F/EL108',
      'teacher': '王志偉',
      'remark': '',
      'times': ['E', 'F'],
      'weekday': '3',
      'room': 'EL108',
      'syllabusUrl': '',
      'year': '114',
      'semester': '2',
      'courseNo': '30206',
    },
    {
      'semesterCourseNo': '11420007',
      'deptCourseNo': 'GEN0001',
      'name': '服務學習(三)',
      'nameEn': 'Service Learning III',
      'courseClass': '資工三甲',
      'classType': '',
      'requiredType': '必修',
      'credits': '0',
      'timeRoomStr': '',
      'teacher': '林導師',
      'remark': '無固定上課時間',
      'times': <String>[],
      'weekday': '',
      'room': '',
      'syllabusUrl': '',
      'year': '114',
      'semester': '2',
      'courseNo': '30207',
    },
    {
      'semesterCourseNo': '11420008',
      'deptCourseNo': 'GEN0002',
      'name': '職涯規劃講座',
      'nameEn': 'Career Planning Seminar',
      'courseClass': '通識中心',
      'classType': '',
      'requiredType': '通識',
      'credits': '1',
      'timeRoomStr': '',
      'teacher': '業界講師',
      'remark': '線上非同步課程',
      'times': <String>[],
      'weekday': '',
      'room': '',
      'syllabusUrl': '',
      'year': '114',
      'semester': '2',
      'courseNo': '30208',
    },
  ];

  static const List<Map<String, dynamic>> _courses1141 = [
    {
      'semesterCourseNo': '11410001',
      'deptCourseNo': 'CSE3001',
      'name': '演算法',
      'nameEn': 'Algorithms',
      'courseClass': '資工三甲',
      'classType': '',
      'requiredType': '必修',
      'credits': '3',
      'timeRoomStr': '1-A,B/EL102',
      'teacher': '陳俊達',
      'remark': '',
      'times': ['A', 'B'],
      'weekday': '1',
      'room': 'EL102',
      'syllabusUrl': '',
      'year': '114',
      'semester': '1',
      'courseNo': '30101',
    },
    {
      'semesterCourseNo': '11410002',
      'deptCourseNo': 'CSE3002',
      'name': '作業系統',
      'nameEn': 'Operating Systems',
      'courseClass': '資工三甲',
      'classType': '',
      'requiredType': '必修',
      'credits': '3',
      'timeRoomStr': '2-C,D/EL201',
      'teacher': '林明宏',
      'remark': '',
      'times': ['C', 'D'],
      'weekday': '2',
      'room': 'EL201',
      'syllabusUrl': '',
      'year': '114',
      'semester': '1',
      'courseNo': '30102',
    },
    {
      'semesterCourseNo': '11410003',
      'deptCourseNo': 'CSE3003',
      'name': '機率與統計',
      'nameEn': 'Probability and Statistics',
      'courseClass': '資工三甲',
      'classType': '',
      'requiredType': '必修',
      'credits': '3',
      'timeRoomStr': '3-A,B/EL103',
      'teacher': '李佳穎',
      'remark': '',
      'times': ['A', 'B'],
      'weekday': '3',
      'room': 'EL103',
      'syllabusUrl': '',
      'year': '114',
      'semester': '1',
      'courseNo': '30103',
    },
    {
      'semesterCourseNo': '11410004',
      'deptCourseNo': 'CSE3004',
      'name': '資料庫系統',
      'nameEn': 'Database Systems',
      'courseClass': '資工三甲',
      'classType': '',
      'requiredType': '選修',
      'credits': '3',
      'timeRoomStr': '4-E,F/EL205',
      'teacher': '張育銘',
      'remark': '',
      'times': ['E', 'F'],
      'weekday': '4',
      'room': 'EL205',
      'syllabusUrl': '',
      'year': '114',
      'semester': '1',
      'courseNo': '30104',
    },
    {
      'semesterCourseNo': '11410005',
      'deptCourseNo': 'CSE3005',
      'name': '專題實作(一)',
      'nameEn': 'Senior Project I',
      'courseClass': '資工三甲',
      'classType': '',
      'requiredType': '必修',
      'credits': '2',
      'timeRoomStr': '5-G,H/EL108',
      'teacher': '張育銘',
      'remark': '',
      'times': ['G', 'H'],
      'weekday': '5',
      'room': 'EL108',
      'syllabusUrl': '',
      'year': '114',
      'semester': '1',
      'courseNo': '30105',
    },
    {
      'semesterCourseNo': '11410006',
      'deptCourseNo': 'CSE3006',
      'name': '計算機網路',
      'nameEn': 'Computer Networks',
      'courseClass': '資工三甲',
      'classType': '',
      'requiredType': '必修',
      'credits': '3',
      'timeRoomStr': '2-E,F/EL301',
      'teacher': '王志偉',
      'remark': '',
      'times': ['E', 'F'],
      'weekday': '2',
      'room': 'EL301',
      'syllabusUrl': '',
      'year': '114',
      'semester': '1',
      'courseNo': '30106',
    },
  ];

  static const List<Map<String, dynamic>> _courses1132 = [
    {
      'semesterCourseNo': '11320001',
      'deptCourseNo': 'CSE2001',
      'name': '資料結構',
      'nameEn': 'Data Structures',
      'courseClass': '資工二甲',
      'classType': '',
      'requiredType': '必修',
      'credits': '3',
      'timeRoomStr': '1-C,D/EL101',
      'teacher': '陳俊達',
      'remark': '',
      'times': ['C', 'D'],
      'weekday': '1',
      'room': 'EL101',
      'syllabusUrl': '',
      'year': '113',
      'semester': '2',
      'courseNo': '20201',
    },
    {
      'semesterCourseNo': '11320002',
      'deptCourseNo': 'CSE2002',
      'name': '計算機組織',
      'nameEn': 'Computer Organization',
      'courseClass': '資工二甲',
      'classType': '',
      'requiredType': '必修',
      'credits': '3',
      'timeRoomStr': '2-A,B/EL102',
      'teacher': '林明宏',
      'remark': '',
      'times': ['A', 'B'],
      'weekday': '2',
      'room': 'EL102',
      'syllabusUrl': '',
      'year': '113',
      'semester': '2',
      'courseNo': '20202',
    },
    {
      'semesterCourseNo': '11320003',
      'deptCourseNo': 'CSE2003',
      'name': '線性代數',
      'nameEn': 'Linear Algebra',
      'courseClass': '資工二甲',
      'classType': '',
      'requiredType': '必修',
      'credits': '3',
      'timeRoomStr': '3-E,F/EL103',
      'teacher': '李佳穎',
      'remark': '',
      'times': ['E', 'F'],
      'weekday': '3',
      'room': 'EL103',
      'syllabusUrl': '',
      'year': '113',
      'semester': '2',
      'courseNo': '20203',
    },
    {
      'semesterCourseNo': '11320004',
      'deptCourseNo': 'CSE2004',
      'name': '物件導向程式設計',
      'nameEn': 'Object-Oriented Programming',
      'courseClass': '資工二甲',
      'classType': '',
      'requiredType': '必修',
      'credits': '3',
      'timeRoomStr': '4-C,D/EL204',
      'teacher': '張育銘',
      'remark': '',
      'times': ['C', 'D'],
      'weekday': '4',
      'room': 'EL204',
      'syllabusUrl': '',
      'year': '113',
      'semester': '2',
      'courseNo': '20204',
    },
    {
      'semesterCourseNo': '11320005',
      'deptCourseNo': 'CSE2005',
      'name': '數位邏輯設計',
      'nameEn': 'Digital Logic Design',
      'courseClass': '資工二甲',
      'classType': '',
      'requiredType': '選修',
      'credits': '3',
      'timeRoomStr': '5-A,B/EL301',
      'teacher': '王志偉',
      'remark': '',
      'times': ['A', 'B'],
      'weekday': '5',
      'room': 'EL301',
      'syllabusUrl': '',
      'year': '113',
      'semester': '2',
      'courseNo': '20205',
    },
  ];

  // ── 行事曆 ─────────────────────────────────────────

  /// 依傳入的西元年產生該年內的學校行事曆事件。
  static Map<String, dynamic> calendarEvents(String year, {String? lang}) {
    final isEn = lang == 'en';
    final y = year;

    final events = <Map<String, dynamic>>[
      // 上半年（第二學期）
      {
        'id': 'cal-01',
        'date': '$y-02-17',
        'name': isEn ? 'Spring Semester Begins' : '第二學期開學',
        'link': '',
        'isImportant': true,
      },
      {
        'id': 'cal-02',
        'date': '$y-02-17',
        'name': isEn ? 'Add/Drop Period Begins' : '加退選開始',
        'link': '',
        'isImportant': false,
      },
      {
        'id': 'cal-03',
        'date': '$y-02-28',
        'name': isEn ? 'Peace Memorial Day (No Classes)' : '和平紀念日放假',
        'link': '',
        'isImportant': false,
      },
      {
        'id': 'cal-04',
        'date': '$y-03-03',
        'name': isEn ? 'Add/Drop Period Ends' : '加退選截止',
        'link': '',
        'isImportant': true,
      },
      {
        'id': 'cal-05',
        'date': '$y-04-04',
        'name': isEn ? "Children's Day / Tomb Sweeping Day" : '兒童節/清明節連假',
        'link': '',
        'isImportant': false,
      },
      {
        'id': 'cal-06',
        'date': '$y-04-14',
        'name': isEn ? 'Midterm Exam Week' : '期中考週',
        'link': '',
        'isImportant': true,
      },
      {
        'id': 'cal-07',
        'date': '$y-05-01',
        'name': isEn ? 'Campus Sports Day' : '校慶運動會',
        'link': '',
        'isImportant': false,
      },
      {
        'id': 'cal-08',
        'date': '$y-06-16',
        'name': isEn ? 'Final Exam Week' : '期末考週',
        'link': '',
        'isImportant': true,
      },
      {
        'id': 'cal-09',
        'date': '$y-06-21',
        'name': isEn ? 'Graduation Ceremony' : '畢業典禮',
        'link': '',
        'isImportant': true,
      },
      {
        'id': 'cal-10',
        'date': '$y-06-28',
        'name': isEn ? 'Summer Break Begins' : '暑假開始',
        'link': '',
        'isImportant': false,
      },
      // 下半年（第一學期）
      {
        'id': 'cal-11',
        'date': '$y-09-09',
        'name': isEn ? 'Fall Semester Begins' : '第一學期開學',
        'link': '',
        'isImportant': true,
      },
      {
        'id': 'cal-12',
        'date': '$y-09-09',
        'name': isEn ? 'Add/Drop Period Begins' : '加退選開始',
        'link': '',
        'isImportant': false,
      },
      {
        'id': 'cal-13',
        'date': '$y-09-22',
        'name': isEn ? 'Add/Drop Period Ends' : '加退選截止',
        'link': '',
        'isImportant': true,
      },
      {
        'id': 'cal-14',
        'date': '$y-10-10',
        'name': isEn ? 'National Day (No Classes)' : '國慶日放假',
        'link': '',
        'isImportant': false,
      },
      {
        'id': 'cal-15',
        'date': '$y-11-03',
        'name': isEn ? 'Midterm Exam Week' : '期中考週',
        'link': '',
        'isImportant': true,
      },
      {
        'id': 'cal-16',
        'date': '$y-11-17',
        'name': isEn ? 'Anniversary Celebration' : '校慶',
        'link': '',
        'isImportant': false,
      },
      {
        'id': 'cal-17',
        'date': '$y-12-22',
        'name': isEn ? 'Final Exam Week' : '期末考週',
        'link': '',
        'isImportant': true,
      },
      {
        'id': 'cal-18',
        'date': '$y-01-01',
        'name': isEn ? "New Year's Day" : '元旦放假',
        'link': '',
        'isImportant': false,
      },
      {
        'id': 'cal-19',
        'date': '$y-01-13',
        'name': isEn ? 'Winter Break Begins' : '寒假開始',
        'link': '',
        'isImportant': false,
      },
    ];

    return {
      'success': true,
      'year': year,
      'count': events.length,
      'events': events,
    };
  }

  /// 依傳入的西元年產生假日清單。
  static Map<String, dynamic> holidays(int year, {String? lang}) {
    final y = year.toString();

    final holidayDates = [
      '$y-01-01',
      '$y-02-28',
      '$y-04-04',
      '$y-04-05',
      '$y-05-01',
      '$y-10-10',
    ];

    final details = <String, String>{
      '$y-01-01': 'national',
      '$y-02-28': 'national',
      '$y-04-04': 'national',
      '$y-04-05': 'national',
      '$y-05-01': 'national',
      '$y-10-10': 'national',
    };

    return {
      'success': true,
      'year': year,
      'count': holidayDates.length,
      'holidays': holidayDates,
      'holidayDetails': details,
    };
  }

  /// 合併行事曆 + 假日。
  static Map<String, dynamic> calendarCombined(String year, {String? lang}) {
    final events = calendarEvents(year, lang: lang);
    final h = holidays(int.parse(year), lang: lang);
    return {
      'success': true,
      'events': events['events'] ?? [],
      'holidays': h['holidays'] ?? [],
      'holidayDetails': h['holidayDetails'] ?? {},
    };
  }

  // ── 課程詳情（依 courseNo 查找）────────────────────

  /// 從成績 + 課表中查找課程資訊，找不到就回預設。
  static Map<String, dynamic> courseDetail({
    required String year,
    required String semester,
    required String courseNo,
  }) {
    // 先從課表找
    final scheduleList = (schedule['data']?['schedule'] as List?) ?? const [];
    for (final c in scheduleList) {
      if ((c as Map)['courseNo'] == courseNo) {
        return {
          'status': 'success',
          'data': {
            'courseNo': courseNo,
            'name': c['name'],
            'nameEn': c['nameEn'] ?? '',
            'credits': c['credits'],
            'teacher': c['teacher'],
            'description': 'Demo 模式 — ${c['name']}課程詳情。',
          },
        };
      }
    }

    // 再從成績找
    for (final sem in grades['grades'] as List) {
      for (final c in (sem as Map)['courses'] as List) {
        if ((c as Map)['courseNo'] == courseNo) {
          return {
            'status': 'success',
            'data': {
              'courseNo': courseNo,
              'name': c['name'],
              'nameEn': c['name_en'] ?? '',
              'credits': c['credits'],
              'teacher': '',
              'description': 'Demo 模式 — ${c['name']}課程詳情。',
            },
          };
        }
      }
    }

    return {
      'status': 'success',
      'data': {
        'courseNo': courseNo,
        'name': '示範課程',
        'nameEn': 'Demo Course',
        'credits': '3',
        'teacher': '示範教授',
        'description': 'Demo 模式的課程詳情範例。',
      },
    };
  }
}
