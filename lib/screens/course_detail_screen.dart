import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/calendar_event.dart';
import '../models/course_detail_model.dart';
import '../models/map_building_model.dart';
import '../providers/providers.dart';
import '../services/api_service.dart';
import '../services/calendar_cache_service.dart';
import '../services/calendar_export_service.dart';
import '../services/course_detail_cache.dart';
import '../services/scrape_result.dart';
import '../utils/course_time_slot.dart';
import '../utils/network_error.dart';
import '../utils/semester_anchor.dart';
import '../utils/semester_code.dart';
import '../utils/syllabus_week.dart';
import '../utils/top_snack_bar.dart';
import '../widgets/syllabus_week_calendar_sheet.dart';
import 'map_screen.dart';
import 'web_view_screen.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final String year;
  final String semester;
  final String courseNo;
  final String courseName;

  const CourseDetailScreen({
    super.key,
    required this.year,
    required this.semester,
    required this.courseNo,
    required this.courseName,
  });

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  final _api = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  CourseDetail? _courseDetail;

  /// 本學期第 1 週的週一。`null` = 還沒算出來或行事曆上找不到「上課開始」，
  /// 此時每週進度的加入行事曆按鈕停用（而不是隱藏，也不是靜靜算錯）。
  DateTime? _firstWeekMonday;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
    _resolveSemesterAnchor();
  }

  /// 從學校行事曆推出本學期第 1 週的週一。
  ///
  /// **一律取中文行事曆**（`lang: 'zh'`）：判斷依據是「上課開始」這個中文名稱，
  /// 與 UI 語言無關。英文版是翻譯產物，拿它當判斷依據等於把可靠度往下押一層 ——
  /// 而且英文介面下就會整個推導失效。
  ///
  /// 失敗（離線、學校網站掛了、那一年沒有這筆）一律讓 [_firstWeekMonday] 維持
  /// null，按鈕停用並說明原因。這裡不顯示錯誤，課程詳細頁本身仍然可看。
  Future<void> _resolveSemesterAnchor() async {
    final gregorianYear = gregorianYearOf(
      year: widget.year,
      semester: widget.semester,
    );
    if (gregorianYear == null) return;

    try {
      final data = await CalendarCacheService.getOrFetch(
        gregorianYear,
        'zh',
        (year, {lang}) => _api.getCalendar(year, lang: lang),
      );
      if (data == null || !mounted) return;

      final events = ((data['events'] as List?) ?? const [])
          .map((e) => CalendarEvent.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final classStart = findClassStart(
        events,
        year: widget.year,
        semester: widget.semester,
      );
      if (classStart == null || !mounted) return;

      setState(() => _firstWeekMonday = firstWeekMonday(classStart));
    } catch (e) {
      if (kDebugMode) print('CourseDetailScreen: anchor lookup failed: $e');
    }
  }

  Future<void> _fetchDetail() async {
    try {
      final response = await CourseDetailCache.getOrFetch(
        widget.year,
        widget.semester,
        widget.courseNo,
        () => _api.getCourseDetail(
          year: widget.year,
          semester: widget.semester,
          courseNo: widget.courseNo,
        ),
      );

      if (!mounted) return;

      if (response.isSuccess) {
        setState(() {
          _courseDetail = response.data;
          _isLoading = false;
        });
      } else {
        // 依失敗分類顯示具名「無法連線至課程大綱系統」或通用載入失敗。
        if (kDebugMode) {
          print('CourseDetailScreen: fetch failed: ${response.status}');
        }
        setState(() {
          _errorMessage = response.status == RefreshOutcome.networkError
              ? AppLocalizations.of(context).serviceUnavailable(
                  AppLocalizations.of(context).serviceCourseDetail,
                )
              : AppLocalizations.of(context).loadCalendarFailed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('CourseDetailScreen: fetch threw: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = isNetworkError(e)
            ? AppLocalizations.of(context).serviceUnavailable(
                AppLocalizations.of(context).serviceCourseDetail,
              )
            : AppLocalizations.of(context).loadCalendarFailed;
        _isLoading = false;
      });
    }
  }

  /// 每週進度表的週次欄。學校的課綱頁只有中文版，所以這一欄由 App 這側翻譯；
  /// 同一列的進度內容／教學方法／備註是老師寫的中文原文，一律原樣顯示。
  ///
  /// 抽不到數字時原樣顯示原字串 —— 顯示看不懂的原文，好過顯示空白。
  String _formatWeek(String raw) {
    final week = parseSyllabusWeek(raw);
    if (week == null) return raw;
    return AppLocalizations.of(context).courseSyllabusWeek(week);
  }

  /// 這一列為什麼不能加入行事曆；`null` = 可以加。
  ///
  /// 三個理由都回傳可讀的說明而不是靜靜停用：使用者看到一顆灰掉的按鈕卻沒有
  /// 任何解釋，只會以為 App 壞了。
  String? _syllabusAddBlockedReason(CourseSyllabus item, CourseDetail detail) {
    final l10n = AppLocalizations.of(context);
    if (_firstWeekMonday == null) return l10n.syllabusAddNoClassStart;
    if (parseSyllabusWeek(item.week) == null) return l10n.syllabusAddNoWeek;
    if (parseCourseTimeRooms(detail.timeRoom).isEmpty) {
      return l10n.syllabusAddNoTime;
    }
    return null;
  }

  /// 算出這一列（這一週）會產生哪些事件。
  ///
  /// 國定假日**照放**，不跳過也不順延 —— 完全不讀假日資料。這與學校課綱本身
  /// 一致：課綱也沒有扣掉放假那一週。
  List<SyllabusSession> _sessionsFor(CourseSyllabus item, CourseDetail detail) {
    final monday = _firstWeekMonday;
    final week = parseSyllabusWeek(item.week);
    if (monday == null || week == null) return const [];

    return [
      for (final slot in parseCourseTimeRooms(detail.timeRoom))
        SyllabusSession(
          date: dateOfWeek(monday, week: week, weekday: slot.weekday),
          slot: slot,
        ),
    ];
  }

  /// 確認後把這一週的每一個時段都交給系統日曆。
  Future<void> _addSyllabusWeek(
    CourseSyllabus item,
    CourseDetail detail,
  ) async {
    final l10n = AppLocalizations.of(context);
    final week = parseSyllabusWeek(item.week)!;
    final weekLabel = l10n.courseSyllabusWeek(week);
    final sessions = _sessionsFor(item, detail);
    if (sessions.isEmpty) return;

    final confirmed = await showSyllabusWeekCalendarSheet(
      context,
      courseName: detail.courseName.isEmpty
          ? widget.courseName
          : detail.courseName,
      weekLabel: weekLabel,
      sessions: sessions,
    );
    if (confirmed != true || !mounted) return;

    showTopSnackBar(context, l10n.addToCalendarOpening);

    try {
      await CalendarExportService.export([
        for (final session in sessions)
          CalendarExportService.fromSyllabusSession(
            uid: CalendarExportService.uidForSyllabusSession(
              year: widget.year,
              semester: widget.semester,
              courseNo: widget.courseNo,
              week: week,
              weekday: session.slot.weekday,
              startPeriod: session.slot.periods.first,
            ),
            courseName: detail.courseName.isEmpty
                ? widget.courseName
                : detail.courseName,
            weekLabel: weekLabel,
            content: item.content,
            method: item.method,
            remark: item.remark,
            teacher: detail.teacher,
            syllabusUrl: _syllabusUrl,
            methodLabel: l10n.courseSyllabusMethod,
            remarkLabel: l10n.courseRemark,
            teacherLabel: l10n.courseInstructor,
            start: session.start,
            end: session.end,
            room: session.slot.room,
          ),
      ], filename: 'yuntech-syllabus-week.ics');
    } catch (e) {
      if (kDebugMode) print('CourseDetailScreen: add to calendar failed: $e');
      if (!mounted) return;
      showTopSnackBar(
        context,
        l10n.addToCalendarFailed,
        type: SnackBarType.error,
      );
    }
  }

  /// 這門課的課綱頁網址。已知它需要登入才打得開，仍然附進事件描述裡。
  String get _syllabusUrl =>
      'https://webapp.yuntech.edu.tw/WebNewCAS/Course/Plan/Query.aspx'
      '?&${widget.year}&${widget.semester}&${widget.courseNo}';

  String _formatContent(String text) {
    if (text.isEmpty) return AppLocalizations.of(context).courseNoData;
    return text.split('\n').map((line) => line.trimLeft()).join('\n').trim();
  }

  String _annotateRequiredType(String rawType) {
    final type = rawType.trim();
    if (type == '必修' || type.toLowerCase() == 'required') {
      return '必修 (Required)';
    } else if (type == '選修' || type.toLowerCase() == 'elective') {
      return '選修 (Elective)';
    } else if (type == '通識' ||
        type.toLowerCase() == 'general education' ||
        type.toLowerCase().contains('general')) {
      return '通識 (General Education)';
    }
    return type;
  }

  List<String> _extractRoomCodes(String timeRoomStr) {
    if (timeRoomStr.isEmpty) return [];
    final parts = timeRoomStr.split(RegExp(r'[\s,，、；;]+'));
    final List<String> rooms = [];
    for (var part in parts) {
      final subParts = part.split('/');
      if (subParts.length >= 2) {
        final room = subParts.last.trim();
        if (room.isNotEmpty && !rooms.contains(room)) {
          rooms.add(room);
        }
      } else {
        final trimmed = part.trim();
        if (trimmed.isNotEmpty &&
            RegExp(r'^[A-Za-z]+').hasMatch(trimmed) &&
            !trimmed.contains('-')) {
          if (!rooms.contains(trimmed)) {
            rooms.add(trimmed);
          }
        }
      }
    }
    return rooms;
  }

  Future<void> _handleNavigateToMap(String roomCode) async {
    try {
      final jsonString = await rootBundle.loadString('assets/map_data.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      final buildings = jsonList
          .map((item) => MapBuilding.fromJson(item))
          .toList();

      if (!mounted) return;

      final regExp = RegExp(r'^([A-Za-z]+)(\d*)');
      final match = regExp.firstMatch(roomCode.trim());
      if (match == null) {
        showTopSnackBar(
          context,
          AppLocalizations.of(context).courseInvalidRoomCode,
          type: SnackBarType.warning,
        );
        return;
      }

      final String codePrefix = match.group(1)!.toUpperCase();
      bool hasBuilding = false;
      for (var b in buildings) {
        final bIdUpper = b.id.toUpperCase();
        if (bIdUpper.endsWith('-$codePrefix') ||
            b.aliases.any((alias) => alias.toUpperCase() == codePrefix)) {
          hasBuilding = true;
          break;
        }
      }

      if (hasBuilding) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MapScreen(embed: false, targetRoomCode: roomCode),
          ),
        );
      } else {
        showTopSnackBar(
          context,
          AppLocalizations.of(context).courseBuildingNotFound(codePrefix),
          type: SnackBarType.warning,
        );
      }
    } catch (e) {
      // 地圖資料是內建 asset,失敗屬本機解析問題;不顯示原始例外字串。
      if (kDebugMode) print('CourseDetailScreen: map data load failed: $e');
      if (mounted) {
        showTopSnackBar(
          context,
          AppLocalizations.of(context).courseLoadMapDataFailed,
          isError: true,
        );
      }
    }
  }

  void _showRoomSelectionSheet(List<String> roomCodes) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  AppLocalizations.of(context).courseSelectRoomLocation,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              ...roomCodes.map((room) {
                return ListTile(
                  leading: Icon(Icons.map_outlined, color: colorScheme.primary),
                  title: Text(
                    AppLocalizations.of(context).courseGoToRoomLocation(room),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    _handleNavigateToMap(room);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseName),
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: AppLocalizations.of(context).courseOpenInBrowser,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppWebViewScreen(url: _syllabusUrl),
                ),
              );
            },
          ),
        ],
      ),
      // 預留底部系統導覽列（三鍵/手勢）高度，避免內容被系統列遮擋。
      body: SafeArea(top: false, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      final colorScheme = Theme.of(context).colorScheme;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: TextStyle(color: colorScheme.error)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _fetchDetail();
              },
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      );
    }

    if (_courseDetail == null) return const SizedBox.shrink();

    final detail = _courseDetail!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(detail),
        const SizedBox(height: 24),
        _buildSectionTitle(AppLocalizations.of(context).courseGoal),
        _buildContentCard(_formatContent(detail.goal)),
        const SizedBox(height: 24),
        _buildSectionTitle(AppLocalizations.of(context).courseOutline),
        _buildContentCard(_formatContent(detail.outline)),
        const SizedBox(height: 24),
        _buildSectionTitle(AppLocalizations.of(context).courseGrading),
        _buildContentCard(_formatContent(detail.grade)),
        const SizedBox(height: 24),
        _buildSyllabusPanel(detail),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSyllabusPanel(CourseDetail detail) {
    final syllabus = detail.syllabus;
    if (syllabus.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    // 已經過去的學期整張表都不長加入按鈕：那一週的課早就上完了，把它排進行事曆
    // 沒有意義，而從歷年成績點進舊課程時那顆按鈕只會是誤觸來源。**隱藏而不是
    // 停用** —— 18 列各一顆灰按鈕比沒有按鈕更吵，而且「這是舊學期」不需要解釋。
    //
    // 注意這只擋「早於」當前學期，未來學期照常顯示（校曆還沒公布的話，錨點推導
    // 自然會讓它停用並說明原因）。當前學期**已經過去的週次**也照常顯示：那是
    // 使用者在自己的課綱表上刻意按的，不是誤觸。
    final isPastSemester = isSemesterBefore(
      year: widget.year,
      semester: widget.semester,
      currentSemester: ref.watch(dataProvider).currentSemester,
    );
    final showAddButton = CalendarExportService.isSupported && !isPastSemester;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          AppLocalizations.of(context).courseSyllabus,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        collapsedBackgroundColor: colorScheme.surfaceContainerHighest,
        backgroundColor: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              border: Border.all(color: colorScheme.surfaceContainerHighest),
            ),
            child: Column(
              children: syllabus.map((item) {
                final blockedReason = showAddButton
                    ? _syllabusAddBlockedReason(item, detail)
                    : null;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(
                          _formatWeek(item.week),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.secondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.content
                                  .split('\n')
                                  .map((line) => line.trimLeft())
                                  .join('\n')
                                  .trim(),
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                height: 1.5,
                              ),
                            ),
                            if (item.method.isNotEmpty ||
                                item.remark.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (item.method.isNotEmpty)
                                    Text(
                                      '📝 ${item.method}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  if (item.remark.isNotEmpty)
                                    Text(
                                      '📌 ${item.remark}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (showAddButton)
                        IconButton(
                          icon: const Icon(Icons.edit_calendar, size: 20),
                          visualDensity: VisualDensity.compact,
                          // 算不出來時畫成停用的樣子，但**仍然可以按** —— 按下去
                          // 用 snackbar 說明原因。純粹 `onPressed: null` 的話理由
                          // 只剩 tooltip，而在手機上那要長按才看得到，等於沒說。
                          color: blockedReason == null
                              ? colorScheme.primary
                              : colorScheme.outline,
                          tooltip:
                              blockedReason ??
                              AppLocalizations.of(context).addToCalendar,
                          onPressed: blockedReason == null
                              ? () => _addSyllabusWeek(item, detail)
                              : () => showTopSnackBar(
                                  context,
                                  blockedReason,
                                  type: SnackBarType.warning,
                                ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(CourseDetail detail) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            _buildInfoRow(
              AppLocalizations.of(context).courseInstructor,
              detail.teacher,
            ),
            if (detail.teacherEmailAndTel != null &&
                detail.teacherEmailAndTel!.isNotEmpty) ...[
              const Divider(height: 8),
              _buildInfoRow(
                AppLocalizations.of(context).courseContactInfo,
                detail.teacherEmailAndTel!,
              ),
            ],
            if (detail.deptCourseNo != null &&
                detail.deptCourseNo!.isNotEmpty) ...[
              const Divider(height: 8),
              _buildInfoRow(
                AppLocalizations.of(context).courseCurriculumNo,
                detail.deptCourseNo!,
              ),
            ],
            const Divider(height: 8),
            _buildInfoRow(
              AppLocalizations.of(context).courseCredits,
              detail.credits,
            ),
            const Divider(height: 8),
            _buildInfoRow(
              AppLocalizations.of(context).courseScheduleClassroom,
              detail.timeRoom,
              crossAxisAlignment: CrossAxisAlignment.center,
              trailing: () {
                final rooms = _extractRoomCodes(detail.timeRoom);
                if (rooms.isEmpty) return null;
                return IconButton(
                  icon: const Icon(Icons.map_outlined),
                  tooltip: AppLocalizations.of(context).mapModeTooltip,
                  onPressed: () {
                    if (rooms.length == 1) {
                      _handleNavigateToMap(rooms.first);
                    } else {
                      _showRoomSelectionSheet(rooms);
                    }
                  },
                );
              }(),
            ),
            if (detail.courseClass != null &&
                detail.courseClass!.isNotEmpty) ...[
              const Divider(height: 8),
              _buildInfoRow(
                AppLocalizations.of(context).courseClass,
                detail.courseClass!,
              ),
            ],
            const Divider(height: 8),
            _buildInfoRow(
              AppLocalizations.of(context).courseRequiredElective,
              _annotateRequiredType(detail.requiredType),
            ),
            if (detail.courseType != null && detail.courseType!.isNotEmpty) ...[
              const Divider(height: 8),
              _buildInfoRow(
                AppLocalizations.of(context).courseType,
                detail.courseType!,
              ),
            ],
            if (detail.courseRemark != null &&
                detail.courseRemark!.isNotEmpty) ...[
              const Divider(height: 8),
              _buildInfoRow(
                AppLocalizations.of(context).courseRemark,
                detail.courseRemark!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Widget? trailing,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? AppLocalizations.of(context).courseNone : value,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildContentCard(String content) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(content, style: const TextStyle(height: 1.6)),
      ),
    );
  }
}
