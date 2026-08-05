import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/grade_report.dart';
import '../providers/data_provider.dart';
import '../providers/providers.dart';
import '../services/scrape_result.dart';
import '../utils/refresh_body_state.dart';
import '../utils/status_colors.dart';
import '../utils/top_snack_bar.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/grade_notification_sheet.dart';
import '../widgets/grade_stat_card.dart';
import '../widgets/skeleton_loading.dart';
import 'course_detail_screen.dart';
import 'semester_grades_detail_screen.dart';
import 'web_view_screen.dart';

class GradesScreen extends ConsumerStatefulWidget {
  final bool embed;
  const GradesScreen({super.key, this.embed = false});

  @override
  ConsumerState<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends ConsumerState<GradesScreen> {
  int _selectedSegment = 0;

  /// 使用者主動觸發的更新（重新整理、重試）進行中。
  /// 與資料層的 `isLoadingGrades` 並存而不混用：背景預抓也會設那個旗標，
  /// 只有這個為真時才蓋上骨架。
  bool _manualRefreshing = false;

  final Map<String, bool> _expandedStates = {};

  /// 主動更新：蓋上骨架，失敗時跳提示——那是使用者按的，需要明確的回答。
  /// 失敗不動資料，骨架一收畫面自己回到原先的形態。
  Future<void> _refresh(DataProvider data) async {
    setState(() => _manualRefreshing = true);
    try {
      final outcome = await data.fetchGrades(force: true);
      if (!mounted) return;
      if (outcome != null && !outcome.isSuccess) {
        showTopSnackBar(
          context,
          _failureMessage(outcome),
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _manualRefreshing = false);
    }
  }

  /// 連線類錯誤 → 具名「無法連線至成績系統」；其他 → 通用提示。
  /// 錯誤頁與提示共用同一句，兩種呈現方式才不會像是兩種不同的問題。
  String _failureMessage(RefreshOutcome? reason) {
    final l10n = AppLocalizations.of(context);
    return reason == RefreshOutcome.networkError
        ? l10n.serviceUnavailable(l10n.serviceGrades)
        : l10n.checkNetworkRetry;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final data = ref.watch(dataProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (!auth.isInitialized) {
      if (widget.embed) {
        return const Center(child: CircularProgressIndicator());
      }
      return Scaffold(
        appBar: CustomAppBar(title: AppLocalizations.of(context).gradesTitle),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.isLoggedIn) {
      final notLoggedInBody = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).loginToUseAllFeatures,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () {
                ref.read(navIndexProvider.notifier).state = 4;
                showTopSnackBar(
                  context,
                  AppLocalizations.of(context).pleaseLoginToViewGrades,
                );
              },
              child: Text(AppLocalizations.of(context).goToLogin),
            ),
          ],
        ),
      );

      if (widget.embed) {
        return notLoggedInBody;
      }

      return Scaffold(
        appBar: CustomAppBar(title: AppLocalizations.of(context).gradesTitle),
        body: notLoggedInBody,
      );
    }

    final bodyContent = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              segments: <ButtonSegment<int>>[
                ButtonSegment<int>(
                  value: 0,
                  label: Text(
                    AppLocalizations.of(context).gradesSegmentSemester,
                  ),
                  icon: const Icon(Icons.calendar_view_day),
                ),
                ButtonSegment<int>(
                  value: 1,
                  label: Text(
                    AppLocalizations.of(context).gradesSegmentHistory,
                  ),
                  icon: const Icon(Icons.history),
                ),
              ],
              selected: <int>{_selectedSegment},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() => _selectedSegment = newSelection.first);
              },
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.comfortable,
              ),
            ),
          ),
        ),
        Expanded(child: _buildGradesContent(data, colorScheme)),
      ],
    );

    if (widget.embed) {
      return bodyContent;
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: AppLocalizations.of(context).gradesTitle,
        onRefresh: () => _refresh(data),
        isLoading: data.isLoadingGrades,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: AppLocalizations.of(context).settingsGradeNotification,
            // 就地開啟成績通知開關面板，不離開成績頁（修正返回鍵回不到成績頁）。
            onPressed: () => showGradeNotificationSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: AppLocalizations.of(context).courseOpenInBrowser,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppWebViewScreen(
                    url:
                        'https://webapp.yuntech.edu.tw/WebNewCAS/StudentFile/Score/StudScores.aspx',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      // 預留底部系統導覽列（三鍵/手勢）高度，避免內容被系統列遮擋。
      body: SafeArea(top: false, child: bodyContent),
    );
  }

  Widget _buildGradesContent(DataProvider data, ColorScheme colorScheme) {
    final state = resolveRefreshBody(
      isEmpty: data.gradesData?.semesters.isEmpty,
      failed: data.gradesFailed,
      manualRefreshing: _manualRefreshing,
    );
    switch (state) {
      case RefreshBodyState.skeleton:
        return _buildGradesSkeleton(colorScheme);
      case RefreshBodyState.error:
        return _buildGradesError(data, colorScheme);
      // 零筆與有內容都交給列表建構：它依當前分頁選用不同的空狀態文案。
      case RefreshBodyState.empty:
      case RefreshBodyState.list:
        return _buildGradesList(data.gradesData!, colorScheme);
    }
  }

  Widget _buildGradesError(DataProvider data, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).loadGradesFailed,
            style: TextStyle(fontSize: 18, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            _failureMessage(data.gradesFailReason),
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: () => _refresh(data),
            child: Text(AppLocalizations.of(context).retry),
          ),
        ],
      ),
    );
  }

  Widget _buildGradesList(GradeReport gradesData, ColorScheme colorScheme) {
    final List<SemesterGrades> originalGrades = gradesData.semesters;

    if (originalGrades.isEmpty) {
      return Center(
        child: Text(
          _selectedSegment == 0
              ? AppLocalizations.of(context).gradesNoData
              : AppLocalizations.of(context).gradesNoHistoryData,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    // 計算當前真實世界的台灣學年與學期
    final now = DateTime.now();
    int currentYear = now.year - 1911;
    int currentSem = 1;
    if (now.month >= 2 && now.month <= 7) {
      currentYear -= 1;
      currentSem = 2;
    } else if (now.month == 1) {
      currentYear -= 1;
      currentSem = 1;
    }
    final currentSemesterIndex = currentYear * 2 + currentSem;

    // 解析資料庫中最新一學期的學年與學期
    final latestSemester = originalGrades.last;
    final int latestYear = int.tryParse(latestSemester.academicYear) ?? 0;
    final int latestSem = int.tryParse(latestSemester.semester) ?? 0;
    final latestSemesterIndex = latestYear * 2 + latestSem;

    // 計算學期差距，如果差距大於 1，代表最新成績學期已經是過去的歷史（使用者可能已畢業或長期休學）
    final diff = currentSemesterIndex - latestSemesterIndex;
    final isGraduatedOrInactive = diff > 1;

    List<SemesterGrades> grades = [];

    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    if (_selectedSegment == 0) {
      if (isGraduatedOrInactive) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 48, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).gradesNoCurrentData,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).gradesNotEnrolled,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      } else {
        // 在學學生：學期成績分頁直接呈現「直觀成績儀表板」
        final semester = originalGrades.last;
        final courses = semester.courses;

        // 計算統計數據
        double totalWeightedScore = 0;
        double totalGradedCredits = 0;
        double totalCredits = 0;
        double earnedCredits = 0;

        for (var course in courses) {
          final credit = double.tryParse(course.credits) ?? 0;
          final scoreStr = course.score;
          final score = double.tryParse(scoreStr);
          totalCredits += credit;
          bool isPass = false;
          if (score != null) {
            if (score >= 60) isPass = true;
          } else {
            if (scoreStr.contains('通過') ||
                scoreStr.toLowerCase().contains('pass')) {
              isPass = true;
            }
          }
          if (isPass) earnedCredits += credit;
          if (score != null) {
            totalWeightedScore += score * credit;
            totalGradedCredits += credit;
          }
        }

        final calculatedAverage = totalGradedCredits > 0
            ? (totalWeightedScore / totalGradedCredits).toStringAsFixed(2)
            : 'N/A';

        String formatCredit(double c) =>
            c.truncateToDouble() == c ? c.toInt().toString() : c.toString();
        final passRate =
            '${formatCredit(earnedCredits)}/${formatCredit(totalCredits)}';

        final displayAverage = calculatedAverage;
        final displayRank = semester.rank.isEmpty ? "-" : semester.rank;

        return ListView(
          key: const ValueKey('semester_grades_dashboard'),
          padding: const EdgeInsets.all(16),
          children: [
            // 學期標題
            Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 4),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).gradesSemesterTitle(
                      semester.academicYear,
                      semester.semester,
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // 數據儀表板橫列 (一排四個)
            Row(
              children: [
                GradeStatCard(
                  label: AppLocalizations.of(context).gradesAverage,
                  value: displayAverage,
                  icon: Icons.analytics_outlined,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 8),
                GradeStatCard(
                  label: AppLocalizations.of(context).gradesGPA,
                  value: semester.gpa.isEmpty ? "-" : semester.gpa,
                  icon: Icons.grade_outlined,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 8),
                GradeStatCard(
                  label: AppLocalizations.of(context).gradesRank,
                  value: displayRank,
                  icon: Icons.format_list_numbered_outlined,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 8),
                GradeStatCard(
                  label: AppLocalizations.of(context).gradesEarnedCredits,
                  value: passRate,
                  icon: Icons.menu_book_outlined,
                  colorScheme: colorScheme,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 課程卡片列表
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerHighest,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: courses.map<Widget>((course) {
                  final scoreRaw = course.score;
                  final isEmpty = scoreRaw.isEmpty;
                  final score = isEmpty ? null : double.tryParse(scoreRaw);
                  final isPass =
                      !isEmpty &&
                      (score != null
                          ? score >= 60
                          : scoreRaw.contains('通過') ||
                                scoreRaw.toLowerCase().contains('pass'));
                  final effectivePass = isPass;

                  String displayScore = scoreRaw;
                  if (isEmpty) {
                    displayScore = AppLocalizations.of(context).notSpecified;
                  } else if (isEnglish) {
                    if (scoreRaw == '通過') displayScore = 'Pass';
                    if (scoreRaw == '不通過') displayScore = 'Fail';
                  }

                  final cName = (isEnglish && course.nameEn.trim().isNotEmpty)
                      ? course.nameEn
                      : (course.name.isNotEmpty
                            ? course.name
                            : 'Unknown Course');

                  final typeZh = course.type;
                  String type = typeZh;
                  if (isEnglish) {
                    if (typeZh == '必修') {
                      type = 'Required';
                    } else if (typeZh == '選修') {
                      type = 'Elective';
                    } else if (typeZh == '通識') {
                      type = 'General Education';
                    }
                  }

                  return InkWell(
                    onTap: () {
                      final courseNo = course.courseNo;
                      if (courseNo.isNotEmpty &&
                          semester.academicYear.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourseDetailScreen(
                              year: semester.academicYear,
                              semester: semester.semester,
                              courseNo: courseNo,
                              courseName: cName,
                            ),
                          ),
                        );
                      } else {
                        showTopSnackBar(
                          context,
                          AppLocalizations.of(context).noCourseDetail,
                          type: SnackBarType.warning,
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if (type.isNotEmpty) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                colorScheme.secondaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            type,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: colorScheme
                                                  .onSecondaryContainer,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        ).courseCreditsFormat(course.credits),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isEmpty
                                    ? colorScheme.surfaceContainerHighest
                                    : effectivePass
                                    ? StatusColors.success.withValues(
                                        alpha: 0.15,
                                      )
                                    : colorScheme.error.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                displayScore,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isEmpty
                                      ? colorScheme.onSurfaceVariant
                                      : effectivePass
                                      ? StatusColors.success
                                      : colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      }
    }

    // 歷年成績分頁：使用 ListView.builder 搭配原有的 Card + ExpansionTile
    grades = [];
    if (isGraduatedOrInactive) {
      grades = originalGrades.reversed.toList();
    } else {
      if (originalGrades.length > 1) {
        grades = originalGrades
            .sublist(0, originalGrades.length - 1)
            .reversed
            .toList();
      } else {
        grades = [];
      }
    }

    final cumulative = gradesData.cumulative;
    Widget? cumulativeDashboard;
    if (cumulative != null) {
      final cumAverage = cumulative.average.isNotEmpty
          ? cumulative.average
          : '-';
      final cumGPA = cumulative.gpa.isNotEmpty ? cumulative.gpa : '-';
      final cumRank = cumulative.rank;
      final cumTotal = cumulative.totalStudents;
      final cumRankText = cumRank.isNotEmpty && cumTotal.isNotEmpty
          ? '$cumRank / $cumTotal'
          : cumRank.isNotEmpty
          ? cumRank
          : '-';
      final cumCredits = cumulative.earnedCredits;
      final cumAttempted = cumulative.attemptedCredits;
      final cumCreditsText = cumCredits.isNotEmpty && cumAttempted.isNotEmpty
          ? '$cumCredits/$cumAttempted'
          : cumCredits.isNotEmpty
          ? cumCredits
          : '-';

      cumulativeDashboard = Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GradeStatCard(
                  label: AppLocalizations.of(context).gradesAverage,
                  value: cumAverage,
                  icon: Icons.analytics_outlined,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 8),
                GradeStatCard(
                  label: AppLocalizations.of(context).gradesGPA,
                  value: cumGPA,
                  icon: Icons.grade_outlined,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 8),
                GradeStatCard(
                  label: AppLocalizations.of(context).gradesRank,
                  value: cumRankText,
                  icon: Icons.format_list_numbered_outlined,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 8),
                GradeStatCard(
                  label: AppLocalizations.of(context).gradesEarnedCredits,
                  value: cumCreditsText,
                  icon: Icons.menu_book_outlined,
                  colorScheme: colorScheme,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 24),
          ],
        ),
      );
    }

    if (grades.isEmpty && cumulativeDashboard == null) {
      return Center(
        child: Text(
          AppLocalizations.of(context).gradesNoHistoryData,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.builder(
      key: ValueKey(_selectedSegment),
      padding: const EdgeInsets.all(16),
      itemCount: grades.length + (cumulativeDashboard != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (cumulativeDashboard != null && index == 0) {
          return cumulativeDashboard;
        }

        final semesterIndex = cumulativeDashboard != null ? index - 1 : index;
        final semester = grades[semesterIndex];
        final courses = semester.courses;
        final semesterKey = '${semester.academicYear}-${semester.semester}';

        if (!_expandedStates.containsKey(semesterKey)) {
          final isLastSemester = _selectedSegment == 0;
          _expandedStates[semesterKey] = isLastSemester;
        }

        double totalWeightedScore = 0;
        double totalGradedCredits = 0;
        double totalCredits = 0;
        double earnedCredits = 0;

        for (var course in courses) {
          final credit = double.tryParse(course.credits) ?? 0;
          final scoreStr = course.score;
          final score = double.tryParse(scoreStr);
          totalCredits += credit;
          bool isPass = false;
          if (score != null) {
            if (score >= 60) isPass = true;
          } else {
            if (scoreStr.contains('通過') ||
                scoreStr.toLowerCase().contains('pass')) {
              isPass = true;
            }
          }
          if (isPass) earnedCredits += credit;
          if (score != null) {
            totalWeightedScore += score * credit;
            totalGradedCredits += credit;
          }
        }

        final calculatedAverage = totalGradedCredits > 0
            ? (totalWeightedScore / totalGradedCredits).toStringAsFixed(2)
            : 'N/A';

        String formatCredit(double c) =>
            c.truncateToDouble() == c ? c.toInt().toString() : c.toString();
        final passRate =
            '${formatCredit(earnedCredits)}/${formatCredit(totalCredits)}';

        final apiAverage = semester.averageScore;
        final displayAverage = (apiAverage.isNotEmpty && apiAverage != 'N/A')
            ? apiAverage
            : calculatedAverage;

        final displayGPA = semester.gpa.isNotEmpty ? semester.gpa : '-';

        final avgText = AppLocalizations.of(
          context,
        ).gradesAverageShort(displayAverage);
        final gpaText = AppLocalizations.of(context).gradesGPAShort(displayGPA);
        final rankText = AppLocalizations.of(
          context,
        ).gradesRankShort(semester.rank.isEmpty ? "-" : semester.rank);
        final creditsText = AppLocalizations.of(
          context,
        ).gradesCreditsShort(passRate);

        return Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest,
          margin: const EdgeInsets.only(bottom: 12),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SemesterGradesDetailScreen(semester: semester),
                ),
              );
            },
            title: Text(
              AppLocalizations.of(
                context,
              ).gradesSemesterTitle(semester.academicYear, semester.semester),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '$avgText  |  $gpaText  |  $rankText  |  $creditsText',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            trailing: Icon(Icons.chevron_right, color: colorScheme.primary),
          ),
        );
      },
    );
  }

  /// 骨架照著同一個分頁真正會顯示的版面挖空——分頁列在載入期間仍然看得見、
  /// 也點得動，骨架跟著它換才對得上。
  Widget _buildGradesSkeleton(ColorScheme colorScheme) {
    return _selectedSegment == 0
        ? _buildSemesterSkeleton(colorScheme)
        : _buildHistorySkeleton(colorScheme);
  }

  /// 學期成績分頁：學期標題列 ＋ 四張統計小卡 ＋ 課程卡片列表。
  Widget _buildSemesterSkeleton(ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 學期標題：左側直立色條的位置也挖成骨架，整份骨架維持單一灰階。
        const Padding(
          padding: EdgeInsets.only(bottom: 16, left: 4),
          child: Row(
            children: [
              SkeletonBox(width: 4, height: 18, borderRadius: 2),
              SizedBox(width: 8),
              SkeletonBox(width: 120, height: 16),
            ],
          ),
        ),
        _buildStatCardRowSkeleton(colorScheme),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: List.generate(
              5,
              (_) => _buildCourseRowSkeleton(colorScheme),
            ),
          ),
        ),
      ],
    );
  }

  /// 歷年成績分頁：累計儀表板 ＋ 分隔線 ＋ 每學期一張的列表卡。
  Widget _buildHistorySkeleton(ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatCardRowSkeleton(colorScheme),
              const SizedBox(height: 8),
              const Divider(height: 24),
            ],
          ),
        ),
        ...List.generate(4, (_) => _buildSemesterTileSkeleton(colorScheme)),
      ],
    );
  }

  /// 四張並排的統計小卡：保留 [GradeStatCard] 的外框與尺寸，只挖掉圖示與數字。
  /// 底色與邊框改用中性灰階——骨架不帶主色，免得看起來像已經載好的內容。
  Widget _buildStatCardRowSkeleton(ColorScheme colorScheme) {
    Widget card() => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant, width: 1),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SkeletonBox(width: 16, height: 16, borderRadius: 8),
            SizedBox(height: 4),
            SkeletonBox(width: 34, height: 14),
            SizedBox(height: 4),
            SkeletonBox(width: 26, height: 9),
          ],
        ),
      ),
    );

    return Row(
      children: [
        card(),
        const SizedBox(width: 8),
        card(),
        const SizedBox(width: 8),
        card(),
        const SizedBox(width: 8),
        card(),
      ],
    );
  }

  /// 一列課程：課名 ＋（類別膠囊、學分）＋ 右側分數色塊。
  Widget _buildCourseRowSkeleton(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 160, height: 16),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      SkeletonBox(width: 40, height: 18, borderRadius: 4),
                      SizedBox(width: 8),
                      SkeletonBox(width: 52, height: 14),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            SkeletonBox(width: 48, height: 30),
          ],
        ),
      ),
    );
  }

  /// 一張學期卡：標題 ＋ 單行摘要 ＋ 右側箭頭（ListTile 的形狀）。
  Widget _buildSemesterTileSkeleton(ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 110, height: 16),
                  SizedBox(height: 8),
                  SkeletonBox(height: 13),
                ],
              ),
            ),
            SizedBox(width: 16),
            SkeletonBox(width: 20, height: 20, borderRadius: 10),
          ],
        ),
      ),
    );
  }
}
