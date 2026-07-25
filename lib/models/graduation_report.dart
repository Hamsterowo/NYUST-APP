/// 畢業審核的型別化領域模型。取代過去在 scraper、repository、UI、mock 之間
/// 流動的 `Map<String, dynamic>`，成為唯一契約。
///
/// 欄位一律為 String（沿用 [GradeReport] / [ScheduleEvent] 典範），唯一例外是
/// [MissingCourse.year]：它是從缺修字串以 regex 拆出、供排序使用的數字。
///
/// - [GraduationReport.fromJson] 吃完整回應信封（讀 `graduation_info`），
///   是 scraper、mock 與 Drift 重建共用的唯一進料口；缺少的分組會回退成空的
///   [CreditGroup]（mock 只有 3 組，真實資料有 4 組）。
/// - [CreditGroup.toJson] / [CreditGroup.fromJson] 讓 repository 能沿用通用的
///   EAV（group/category/value）迴圈存取 Drift，不需要手寫欄位對映表。
library;

/// 單一分組（應修目標 / 已得 / 未取得 / 尚缺）的各類別學分。
///
/// 各分組實際擁有的類別不同（例如僅 `earned` 有抵免與外系欄位），
/// 不存在的類別為空字串。
class CreditGroup {
  final String pe;
  final String civilization;
  final String literature;
  final String general;
  final String deptRequired;
  final String deptRequiredOffset;
  final String elective;
  final String electiveOffset;
  final String electiveOuter;
  final String total;

  const CreditGroup({
    this.pe = '',
    this.civilization = '',
    this.literature = '',
    this.general = '',
    this.deptRequired = '',
    this.deptRequiredOffset = '',
    this.elective = '',
    this.electiveOffset = '',
    this.electiveOuter = '',
    this.total = '',
  });

  /// 全空的分組。資料缺少該組時使用（例如 demo 資料沒有「未取得」組）。
  static const CreditGroup empty = CreditGroup();

  factory CreditGroup.fromJson(Map<String, dynamic> json) {
    String s(String key) => json[key]?.toString() ?? '';
    return CreditGroup(
      pe: s('pe'),
      civilization: s('civilization'),
      literature: s('literature'),
      general: s('general'),
      deptRequired: s('dept_required'),
      deptRequiredOffset: s('dept_required_offset'),
      elective: s('elective'),
      electiveOffset: s('elective_offset'),
      electiveOuter: s('elective_outer'),
      total: s('total'),
    );
  }

  /// 只輸出非空的類別，讓 EAV 儲存不會塞入一堆空列
  /// （各分組本來就不具備全部類別）。
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    void put(String key, String value) {
      if (value.isNotEmpty) map[key] = value;
    }

    put('pe', pe);
    put('civilization', civilization);
    put('literature', literature);
    put('general', general);
    put('dept_required', deptRequired);
    put('dept_required_offset', deptRequiredOffset);
    put('elective', elective);
    put('elective_offset', electiveOffset);
    put('elective_outer', electiveOuter);
    put('total', total);
    return map;
  }
}

/// 缺修的必修課程。由 `missing_courses_text` 解析而來。
class MissingCourse {
  final String code;
  final String name;

  /// 建議修習學年（`[3]` → 3）。無法解析時為 0。供排序與顯示使用。
  final int year;

  const MissingCourse({
    required this.code,
    required this.name,
    required this.year,
  });

  static final RegExp _pattern = RegExp(r'^([A-Z]+\d+)(.+?)\[(\d+)\]$');

  /// 解析學校提供的缺修字串（以「、」分隔），並依建議學年排序。
  /// 無法匹配的項目整段當作名稱保留（`code` 為空、`year` 為 0）。
  static List<MissingCourse> parseAll(String raw) {
    if (raw.trim().isEmpty) return const [];

    final items = raw.split('、').map((entry) {
      final trimmed = entry.trim();
      final match = _pattern.firstMatch(trimmed);
      if (match != null) {
        return MissingCourse(
          code: match.group(1)!,
          name: match.group(2)!,
          year: int.tryParse(match.group(3)!) ?? 0,
        );
      }
      return MissingCourse(code: '', name: trimmed, year: 0);
    }).toList();

    items.sort((a, b) => a.year.compareTo(b.year));
    return items;
  }
}

class GraduationReport {
  final String totalCredits;
  final String englishThreshold;
  final String internshipThreshold;

  /// 學校原始的缺修課程字串（保留原文，解析結果見 [missingCourses]）。
  final String missingCoursesText;

  final CreditGroup requiredGoal;
  final CreditGroup earned;

  /// 已修但未取得學分。目前畫面未使用，但忠實保留爬取到的資料。
  final CreditGroup notReceived;
  final CreditGroup missing;

  /// [missingCoursesText] 的解析結果，已依建議學年排序。
  final List<MissingCourse> missingCourses;

  GraduationReport({
    required this.totalCredits,
    required this.englishThreshold,
    required this.internshipThreshold,
    required this.missingCoursesText,
    required this.requiredGoal,
    required this.earned,
    required this.notReceived,
    required this.missing,
    required this.missingCourses,
  });

  factory GraduationReport.fromJson(Map<String, dynamic> json) {
    final info = (json['graduation_info'] as Map?) ?? const {};
    final breakdown = (info['credits_breakdown'] as Map?) ?? const {};

    CreditGroup group(String name) {
      final raw = breakdown[name];
      if (raw is Map) {
        return CreditGroup.fromJson(Map<String, dynamic>.from(raw));
      }
      return CreditGroup.empty;
    }

    final missingText = info['missing_courses_text']?.toString() ?? '';

    return GraduationReport(
      totalCredits: info['total_credits']?.toString() ?? '',
      englishThreshold: info['english_threshold']?.toString() ?? '',
      internshipThreshold: info['internship_threshold']?.toString() ?? '',
      missingCoursesText: missingText,
      requiredGoal: group('required_goal'),
      earned: group('earned'),
      notReceived: group('not_received'),
      missing: group('missing'),
      missingCourses: MissingCourse.parseAll(missingText),
    );
  }

  /// 輸出與 scraper 相同的 wire 形狀。供 repository 以通用 EAV 迴圈持久化，
  /// 以及測試 round-trip 使用。
  Map<String, dynamic> toJson() => {
    'success': true,
    'graduation_info': {
      'total_credits': totalCredits,
      'english_threshold': englishThreshold,
      'internship_threshold': internshipThreshold,
      'credits_breakdown': {
        'required_goal': requiredGoal.toJson(),
        'earned': earned.toJson(),
        'not_received': notReceived.toJson(),
        'missing': missing.toJson(),
      },
      'missing_courses_text': missingCoursesText,
    },
  };
}
