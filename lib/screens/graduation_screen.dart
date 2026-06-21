import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../models/schedule_event.dart';
import '../providers/navigation_provider.dart';
import '../utils/top_snack_bar.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/shimmer_box.dart';
import 'course_detail_screen.dart';
import 'map_screen.dart';

class GraduationContent extends StatelessWidget {
  const GraduationContent({super.key});

  String _formatCreditsText(BuildContext context, String? rawText) {
    if (rawText == null || rawText.isEmpty) return '-';
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    if (isEnglish) {
      return rawText.replaceAll('學分', ' Credits').trim();
    }
    return rawText;
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    if (data.graduationFailed && data.graduationData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).gradLoadFailed,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context).checkNetworkRetry, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () => data.fetchGraduation(),
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      );
    }

    if (data.isLoadingGraduation && data.graduationData == null) {
      return _buildGraduationSkeleton(context, colorScheme);
    }

    final info = data.graduationData?['graduation_info'];
    if (info == null) {
      return Center(child: Text(AppLocalizations.of(context).gradNoData));
    }

    final breakdown =
        info['credits_breakdown'] ??
        {
          "pe": "0",
          "civilization": "0",
          "literature": "0",
          "general": "0",
          "dept_required": "0",
          "elective": "0",
          "total": "0",
        };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(context, info),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context).gradDetailTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildCreditTable(context, breakdown),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).gradTotalNotice,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (info['missing_courses_text'] != null &&
              info['missing_courses_text'].isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).gradMissingRequiredCourses,
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildMissingCoursesList(
                  context,
                  info['missing_courses_text'],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGraduationSkeleton(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shadowColor: Colors.transparent,
            color: colorScheme.surfaceContainer,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const ShimmerBox(width: 100, height: 20),
                  const SizedBox(height: 8),
                  const ShimmerBox(width: 80, height: 48),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      ShimmerBox(width: 80, height: 50),
                      ShimmerBox(width: 80, height: 50),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const ShimmerBox(width: 120, height: 28),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: List.generate(
                8,
                (index) => const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: ShimmerBox(width: double.infinity, height: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, Map info) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shadowColor: Colors.transparent,
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(AppLocalizations.of(context).gradTotalEarnedCredits, style: Theme.of(context).textTheme.labelLarge),
            Text(
              _formatCreditsText(context, info["total_credits"]?.toString()),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBadge(context, AppLocalizations.of(context).gradEnglishThreshold, info['english_threshold']),
                _buildBadge(
                  context,
                  AppLocalizations.of(context).gradInternshipThreshold,
                  info['internship_threshold'] ?? "N/A",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String label, String value) {
    final isPassed = value.contains("通過") || value == "已修過";
    final colorScheme = Theme.of(context).colorScheme;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    String displayValue = value;
    if (isEnglish) {
      final trimmed = value.trim();
      if (trimmed.contains('已通過') || trimmed.contains('通過')) {
        displayValue = 'Passed';
      } else if (trimmed.contains('未通過') || trimmed.contains('不通過')) {
        displayValue = 'Not Passed';
      } else if (trimmed.contains('已修過') || trimmed.contains('修過')) {
        displayValue = 'Completed';
      } else if (trimmed.contains('免修')) {
        displayValue = 'Waived';
      }
    }

    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isPassed
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPassed ? colorScheme.primary : colorScheme.outline,
            ),
          ),
          child: Text(
            displayValue,
            style: TextStyle(
              color: isPassed
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreditTable(BuildContext context, Map breakdown) {
    final rows = [
      'pe',
      'civilization',
      'literature',
      'general',
      'dept_required',
      'elective',
      'total',
    ];
    final labels = {
      'pe': AppLocalizations.of(context).gradLabelPE,
      'civilization': AppLocalizations.of(context).gradLabelCivilization,
      'literature': AppLocalizations.of(context).gradLabelLiterature,
      'general': AppLocalizations.of(context).gradLabelGeneral,
      'dept_required': AppLocalizations.of(context).gradLabelDeptRequired,
      'elective': AppLocalizations.of(context).gradLabelElective,
      'total': AppLocalizations.of(context).gradLabelTotal,
    };
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.hardEdge,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FixedColumnWidth(60),
          1: FlexColumnWidth(),
          2: FlexColumnWidth(),
          3: FlexColumnWidth(),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
            ),
            children: [
              AppLocalizations.of(context).gradCategory,
              AppLocalizations.of(context).gradRequired,
              AppLocalizations.of(context).gradEarned,
              AppLocalizations.of(context).gradMissing,
            ]
                .map(
                  (h) => Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      h,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )
                .toList(),
          ),
          ...rows.map((key) {
            final isTotal = key == 'total';
            return TableRow(
              decoration: isTotal
                  ? BoxDecoration(
                      color: colorScheme.secondaryContainer.withValues(
                        alpha: 0.3,
                      ),
                    )
                  : null,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    labels[key] ?? key,
                    style: TextStyle(
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _formatCreditsText(context, breakdown['required_goal'][key]),
                    style: TextStyle(
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _formatCreditsText(context, breakdown['earned'][key]),
                    style: TextStyle(
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _formatCreditsText(context, breakdown['missing'][key]),
                    style: TextStyle(
                      color:
                          (() {
                            final val = breakdown['missing'][key]?.toString() ?? '';
                            return val == "0" || val.startsWith('0') || val == "Pass" || val.isEmpty;
                          })()
                          ? colorScheme.onSurface
                          : colorScheme.error,
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMissingCoursesList(BuildContext context, String raw) {
    final colorScheme = Theme.of(context).colorScheme;

    final regex = RegExp(r'^([A-Z]+\d+)(.+?)\[(\d+)\]$');

    final items = raw.split('、').map((entry) {
      final match = regex.firstMatch(entry.trim());
      if (match != null) {
        return {
          'code': match.group(1)!,
          'name': match.group(2)!,
          'year': int.tryParse(match.group(3)!) ?? 0,
        };
      }
      return {'code': '', 'name': entry.trim(), 'year': 0};
    }).toList()..sort((a, b) => (a['year'] as int).compareTo(b['year'] as int));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        final year = item['year'] as int;
        final label =
            '${year > 0 ? AppLocalizations.of(context).gradYearFormat(year.toString()) : '??'} - ${item['code']} ${item['name']}';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ',
                style: TextStyle(
                  color: colorScheme.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class ScheduleScreen extends StatefulWidget {
  final bool embed;
  const ScheduleScreen({super.key, this.embed = false});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  bool _isMapMode = false;
  final List<String> _periods = [
    'X',
    'A',
    'B',
    'C',
    'D',
    'Y',
    'E',
    'F',
    'G',
    'H',
    'Z',
    'I',
    'J',
    'K',
    'L',
  ];

  final Map<String, String> _periodTimes = {
    'X': '07:10 - 08:00',
    'A': '08:10 - 09:00',
    'B': '09:10 - 10:00',
    'C': '10:10 - 11:00',
    'D': '11:10 - 12:00',
    'Y': '12:10 - 13:00',
    'E': '13:10 - 14:00',
    'F': '14:10 - 15:00',
    'G': '15:10 - 16:00',
    'H': '16:10 - 17:00',
    'Z': '17:10 - 18:00',
    'I': '18:25 - 19:15',
    'J': '19:20 - 20:10',
    'K': '20:15 - 21:05',
    'L': '21:10 - 22:00',
  };

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!auth.isInitialized) {
      if (widget.embed) {
        return const Center(child: CircularProgressIndicator());
      }
      return Scaffold(
        appBar: CustomAppBar(title: AppLocalizations.of(context).navSchedule),
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
                context.read<NavigationProvider>().setIndex(4);
                showTopSnackBar(context, AppLocalizations.of(context).pleaseLoginToViewSchedule);
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
        appBar: CustomAppBar(title: AppLocalizations.of(context).navSchedule),
        body: notLoggedInBody,
      );
    }

    final data = context.watch<DataProvider>();
    final bodyContent = _buildBody(data);

    if (widget.embed) {
      return bodyContent;
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: AppLocalizations.of(context).navSchedule,
        onRefresh: () => data.fetchSchedule(),
        isLoading: data.isLoadingSchedule,
        actions: [
          IconButton(
            icon: Icon(
              _isMapMode ? Icons.map : Icons.map_outlined,
              color: _isMapMode ? colorScheme.primary : null,
            ),
            onPressed: () {
              setState(() {
                _isMapMode = !_isMapMode;
              });
              showTopSnackBar(
                context,
                _isMapMode
                    ? AppLocalizations.of(context).mapModeEnabled
                    : AppLocalizations.of(context).mapModeDisabled,
              );
            },
            tooltip: AppLocalizations.of(context).mapModeTooltip,
          ),
        ],
      ),
      body: bodyContent,
    );
  }

  Widget _buildBody(DataProvider data) {
    if (data.scheduleFailed && data.scheduleData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).loadScheduleFailed,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).checkNetworkRetry,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () => data.fetchSchedule(),
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      );
    }

    final hasData = data.scheduleData.isNotEmpty;
    final displayData = hasData
        ? data.scheduleData
        : [
            ScheduleEvent(
              semesterCourseNo: '11210001',
              deptCourseNo: 'ABC0001',
              name: '這是一堂假的課這是一堂假的課',
              courseClass: 'A班',
              classType: '必修',
              requiredType: '必',
              credits: '3',
              timeRoomStr: '1-C,D/教室',
              teacher: '教授',
              remark: '',
              times: ['C', 'D'],
              weekday: '1',
            ),
            ScheduleEvent(
              semesterCourseNo: '11210002',
              deptCourseNo: 'ABC0002',
              name: '這是一堂假的課這是一堂假的課',
              courseClass: 'B班',
              classType: '選修',
              requiredType: '選',
              credits: '3',
              timeRoomStr: '2-E,F/教室',
              teacher: '教授',
              remark: '',
              times: ['E', 'F'],
              weekday: '2',
            ),
            ScheduleEvent(
              semesterCourseNo: '11210003',
              deptCourseNo: 'ABC0003',
              name: '假的課',
              courseClass: 'C班',
              classType: '必修',
              requiredType: '必',
              credits: '3',
              timeRoomStr: '3-A,B/教室',
              teacher: '教授',
              remark: '',
              times: ['A', 'B'],
              weekday: '3',
            ),
          ];

    if (!hasData && !data.isLoadingSchedule) {
      return Center(child: Text(AppLocalizations.of(context).noScheduleData));
    }

    if (data.isLoadingSchedule && !hasData) {
      return _buildScheduleGrid(<ScheduleEvent>[], isLoading: true);
    }

    return _buildScheduleGrid(displayData);
  }

  Widget _buildScheduleGrid(
    List<ScheduleEvent> courses, {
    bool isLoading = false,
  }) {
    final allWeekDays = ['一', '二', '三', '四', '五', '六', '日'];
    const timeColumnWidth = 36.0;
    const headerHeight = 36.0;
    const minCellWidth = 46.0;
    const minCellHeight = 28.0;

    int minDayIndex = 0;
    int maxDayIndex = 4;
    int minPeriodIndex = 1;
    int maxPeriodIndex = 9;

    if (courses.isNotEmpty) {
      int minDay = 6;
      int maxDay = 0;
      int minP = _periods.length;
      int maxP = 0;
      bool hasClass = false;

      for (var course in courses) {
        if (course.name.isNotEmpty) {
          hasClass = true;
          int d = int.tryParse(course.weekday ?? '') ?? 1;
          int dIndex = d - 1;
          if (dIndex < minDay) minDay = dIndex;
          if (dIndex > maxDay) maxDay = dIndex;

          for (var t in course.times) {
            int pIndex = _periods.indexOf(t);
            if (pIndex != -1) {
              if (pIndex < minP) minP = pIndex;
              if (pIndex > maxP) maxP = pIndex;
            }
          }
        }
      }

      if (hasClass) {
        minDayIndex = min(minDay, 0).clamp(0, 6);
        maxDayIndex = max(maxDay, 4).clamp(minDayIndex, 6);
        minPeriodIndex = min(minP, 1).clamp(0, _periods.length - 1);
        maxPeriodIndex = max(
          maxP,
          8,
        ).clamp(minPeriodIndex, _periods.length - 1);
      }
    }

    final activeDayIndices = List.generate(
      maxDayIndex - minDayIndex + 1,
      (i) => minDayIndex + i,
    );
    final activePeriods = _periods.sublist(minPeriodIndex, maxPeriodIndex + 1);

    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {

        final availableHeight = constraints.maxHeight - headerHeight - 24.0;
        final rawCellHeight = availableHeight / activePeriods.length;
        final needsVerticalScroll = rawCellHeight < minCellHeight;
        final cellHeight = needsVerticalScroll ? minCellHeight : rawCellHeight;

        final availableForDays = constraints.maxWidth - 24.0 - timeColumnWidth;
        final needsScroll =
            availableForDays / activeDayIndices.length < minCellWidth;

        Widget dayCell(String day) {
          String translatedDay = day;
          if (day == '一') {
            translatedDay = AppLocalizations.of(context).weekdayMon;
          } else if (day == '二') translatedDay = AppLocalizations.of(context).weekdayTue;
          else if (day == '三') translatedDay = AppLocalizations.of(context).weekdayWed;
          else if (day == '四') translatedDay = AppLocalizations.of(context).weekdayThu;
          else if (day == '五') translatedDay = AppLocalizations.of(context).weekdayFri;
          else if (day == '六') translatedDay = AppLocalizations.of(context).weekdaySat;
          else if (day == '日') translatedDay = AppLocalizations.of(context).weekdaySun;

          final label = isLoading
              ? const SizedBox.shrink()
              : Center(
                  child: Text(
                    AppLocalizations.of(context).weekdayHeader(translatedDay),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
          return needsScroll
              ? SizedBox(width: minCellWidth, child: label)
              : Expanded(child: label);
        }

        ScheduleEvent getEventFor(int dayIndex, String period) {
          final weekdayStr = (dayIndex + 1).toString();
          return courses.firstWhere(
            (c) => c.weekday == weekdayStr && c.times.contains(period),
            orElse: () => ScheduleEvent(
              semesterCourseNo: '',
              deptCourseNo: '',
              name: '',
              courseClass: '',
              classType: '',
              requiredType: '',
              credits: '',
              timeRoomStr: '',
              teacher: '',
              remark: '',
              times: [],
            ),
          );
        }

        Widget buildColumnForDay(int dayIndex) {
          List<Widget> cells = [];

          for (int i = 0; i < activePeriods.length; i++) {
            final period = activePeriods[i];
            final event = getEventFor(dayIndex, period);

            int span = 1;
            if (event.name.isNotEmpty) {

              while (i + span < activePeriods.length) {
                final nextPeriod = activePeriods[i + span];
                final nextEvent = getEventFor(dayIndex, nextPeriod);

                if (nextEvent.name == event.name &&
                    nextEvent.semesterCourseNo == event.semesterCourseNo) {
                  span++;
                } else {
                  break;
                }
              }
            }

            final decoration = BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                ),
                right: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                ),
              ),
            );

            final child = isLoading || !event.name.isNotEmpty
                ? null
                : _buildCourseCard(event);

            final cellWidget = Container(
              height: cellHeight * span,
              decoration: decoration,
              width: needsScroll ? minCellWidth : double.infinity,
              child: child,
            );

            cells.add(cellWidget);
            i += span - 1;
          }

          final column = Column(children: cells);
          return needsScroll
              ? SizedBox(width: minCellWidth, child: column)
              : Expanded(child: column);
        }

        Widget headerDays() => Row(
          children: activeDayIndices
              .map((i) => dayCell(allWeekDays[i]))
              .toList(),
        );

        Widget gridRows() => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: activeDayIndices.map((i) => buildColumnForDay(i)).toList(),
        );

        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Card(
            clipBehavior: Clip.hardEdge,
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [

                Container(
                  height: headerHeight,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: timeColumnWidth,
                        child: isLoading
                            ? const SizedBox.shrink()
                            : Center(
                                child: Text(
                                  AppLocalizations.of(context).periodHeader,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                      Expanded(
                        child: needsScroll
                            ? ScrollConfiguration(
                                behavior: ScrollConfiguration.of(
                                  context,
                                ).copyWith(overscroll: false),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const ClampingScrollPhysics(),
                                  child: headerDays(),
                                ),
                              )
                            : headerDays(),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(overscroll: false),
                    child: SingleChildScrollView(
                      physics: needsVerticalScroll
                          ? const ClampingScrollPhysics()
                          : const NeverScrollableScrollPhysics(),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          SizedBox(
                            width: timeColumnWidth,
                            child: Column(
                              children: activePeriods
                                  .map(
                                    (period) => InkWell(
                                      onTap: () {
                                        final time = _periodTimes[period] ?? '';
                                        showTopSnackBar(
                                          context,
                                          AppLocalizations.of(context).periodDetails(period, time),
                                        );
                                      },
                                      child: Container(
                                        height: cellHeight,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Theme.of(context)
                                                  .dividerColor
                                                  .withValues(alpha: 0.5),
                                            ),
                                            right: BorderSide(
                                              color: Theme.of(
                                                context,
                                              ).dividerColor,
                                            ),
                                          ),
                                        ),
                                        child: isLoading
                                            ? const SizedBox.shrink()
                                            : Center(
                                                child: Text(
                                                  period,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),

                          Expanded(
                            child: needsScroll
                                ? ScrollConfiguration(
                                    behavior: ScrollConfiguration.of(
                                      context,
                                    ).copyWith(overscroll: false),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      physics: const ClampingScrollPhysics(),
                                      child: gridRows(),
                                    ),
                                  )
                                : gridRows(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCourseCard(ScheduleEvent event) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasRoom = event.room != null && event.room!.isNotEmpty;
    final isLocatable = _isMapMode && hasRoom;

    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final displayName = (isEnglish && event.nameEn != null && event.nameEn!.trim().isNotEmpty)
        ? event.nameEn!
        : event.name;

    return GestureDetector(
      onTap: () {
        if (_isMapMode) {
          if (hasRoom) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MapScreen(
                  embed: false,
                  targetRoomCode: event.room,
                ),
              ),
            );
          } else {
            showTopSnackBar(
              context,
              AppLocalizations.of(context).noClassroomForLocation,
              type: SnackBarType.warning,
            );
          }
          return;
        }

        if (event.year != null &&
            event.semester != null &&
            event.courseNo != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailScreen(
                year: event.year!,
                semester: event.semester!,
                courseNo: event.courseNo!,
                courseName: displayName,
              ),
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(displayName),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AppLocalizations.of(context).classroomLabel(event.room ?? AppLocalizations.of(context).notDecided)),
                    Text(AppLocalizations.of(context).teacherLabel(event.teacher)),
                    const Divider(),
                    Text(AppLocalizations.of(context).timeLabel(event.timeRoomStr)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context).close),
                ),
              ],
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isLocatable
              ? colorScheme.secondaryContainer.withValues(alpha: 0.95)
              : colorScheme.primaryContainer.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(6),
          border: isLocatable
              ? Border.all(color: colorScheme.secondary, width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                displayName,
                style: TextStyle(
                  fontSize: 15,
                  color: isLocatable
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onPrimaryContainer,
                  height: 1.15,
                  fontWeight: isLocatable ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasRoom)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      event.room!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isLocatable
                            ? colorScheme.onSecondaryContainer.withValues(
                                alpha: 0.8,
                              )
                            : colorScheme.onPrimaryContainer.withValues(
                                alpha: 0.7,
                              ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isLocatable)
                    Icon(
                      Icons.near_me_rounded,
                      size: 12,
                      color: colorScheme.secondary,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class GraduationScreen extends StatelessWidget {
  const GraduationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    return Scaffold(
      appBar: CustomAppBar(
        title: AppLocalizations.of(context).infoGradTitle,
        onRefresh: () => data.fetchGraduation(),
        isLoading: data.isLoadingGraduation,
      ),
      body: const GraduationContent(),
    );
  }
}

