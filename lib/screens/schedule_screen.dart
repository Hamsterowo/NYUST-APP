import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../models/schedule_event.dart';
import '../providers/data_provider.dart';
import '../providers/providers.dart';
import '../services/server_time_service.dart';
import '../utils/top_snack_bar.dart';
import '../widgets/custom_app_bar.dart';
import 'course_detail_screen.dart';
import 'map_screen.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  final bool embed;
  const ScheduleScreen({super.key, this.embed = false});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  bool _isMapMode = false;
  // 課程方塊淡入的「世代」：每次進到課表分頁或切換學期時 +1，
  // 讓所有方塊重新以隨機錯開的方式淡入一次（見 [_FadeInCard]）。
  int _fadeGen = 0;
  final GlobalKey _repaintKey = GlobalKey();

  Timer? _timeLineTimer;

  static const Map<String, List<int>> _periodMinutes = {
    'X': [430, 480],
    'A': [490, 540],
    'B': [550, 600],
    'C': [610, 660],
    'D': [670, 720],
    'Y': [730, 780],
    'E': [790, 840],
    'F': [850, 900],
    'G': [910, 960],
    'H': [970, 1020],
    'Z': [1030, 1080],
    'I': [1105, 1155],
    'J': [1160, 1210],
    'K': [1215, 1265],
    'L': [1270, 1320],
  };

  @override
  void initState() {
    super.initState();
    _timeLineTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timeLineTimer?.cancel();
    super.dispose();
  }

  double? _calculateTimeLineY(List<String> activePeriods, double cellHeight) {
    final now = ServerTimeService.instance.now();
    final nowMinutes = now.hour * 60 + now.minute;

    for (int i = 0; i < activePeriods.length; i++) {
      final period = activePeriods[i];
      final times = _periodMinutes[period];
      if (times == null) continue;
      final start = times[0];
      final end = times[1];

      if (nowMinutes >= start && nowMinutes <= end) {
        final ratio = (nowMinutes - start) / (end - start);
        return i * cellHeight + ratio * cellHeight;
      }

      if (i < activePeriods.length - 1) {
        final nextPeriod = activePeriods[i + 1];
        final nextTimes = _periodMinutes[nextPeriod];
        if (nextTimes != null) {
          final nextStart = nextTimes[0];
          if (nowMinutes > end && nowMinutes < nextStart) {
            return (i + 1) * cellHeight;
          }
        }
      }
    }
    return null;
  }

  Future<void> _shareScheduleImage() async {
    try {
      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      if (kIsWeb) {
        await Share.shareXFiles([
          XFile.fromData(pngBytes, mimeType: 'image/png', name: 'schedule.png'),
        ]);
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/schedule.png').create();
        await file.writeAsBytes(pngBytes);

        if (!mounted) return;
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(file.path)],
          sharePositionOrigin: box != null
              ? box.localToGlobal(Offset.zero) & box.size
              : null,
        );
      }
    } catch (e) {
      if (kDebugMode) print("Share schedule error: $e");
      if (!mounted) return;
      final isEnglish = Localizations.localeOf(context).languageCode == 'en';
      showTopSnackBar(
        context,
        isEnglish ? 'Failed to share schedule' : '分享課表失敗',
        type: SnackBarType.error,
      );
    }
  }

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
    final auth = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // 從其他分頁切回課表分頁（index 1）時：重播課程方塊淡入，並確保學期清單已載入。
    ref.listen<int>(navIndexProvider, (prev, next) {
      if (next == 1 && prev != 1 && mounted) {
        setState(() => _fadeGen++);
        ref.read(dataProvider).ensureScheduleSemesters();
      }
    });

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
                ref.read(navIndexProvider.notifier).state = 4;
                showTopSnackBar(
                  context,
                  AppLocalizations.of(context).pleaseLoginToViewSchedule,
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
        appBar: CustomAppBar(title: AppLocalizations.of(context).navSchedule),
        body: notLoggedInBody,
      );
    }

    final data = ref.watch(dataProvider);
    final bodyContent = _buildBody(data);

    if (widget.embed) {
      return bodyContent;
    }

    final mainBody = Stack(
      children: [
        bodyContent,
        Positioned(
          left: -9999,
          top: -9999,
          width: 496,
          height: 656,
          child: RepaintBoundary(
            key: _repaintKey,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _ShareScheduleCard(courses: data.scheduleData),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: CustomAppBar(
        title: AppLocalizations.of(context).navSchedule,
        onRefresh: () => data.fetchSchedule(force: true),
        isLoading: data.isLoadingSchedule,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: data.isLoadingSchedule || data.scheduleData.isEmpty
                ? null
                : _shareScheduleImage,
            tooltip: Localizations.localeOf(context).languageCode == 'en'
                ? 'Share Schedule'
                : '分享課表',
          ),
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
      body: mainBody,
    );
  }

  Widget _buildBody(DataProvider data) {
    final bar = _buildSemesterBar(data);
    final content = _buildScheduleContent(data);
    if (bar == null) return content;
    return Column(
      children: [
        bar,
        Expanded(child: content),
      ],
    );
  }

  /// 可水平捲動的學期切換列（分段膠囊，大小隨文字、不填滿）。
  /// 學期少於 2 個時不顯示。
  Widget? _buildSemesterBar(DataProvider data) {
    final sems = data.scheduleSemesters;
    if (sems.length < 2) return null;
    final selected = data.selectedSemester ?? data.currentSemester;
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        itemCount: sems.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final value = sems[i]['value'] ?? '';
          return _SemesterChip(
            label: _shortSemester(value, sems[i]['label']),
            selected: value == selected,
            onTap: () {
              if (value == selected) return;
              setState(() => _fadeGen++);
              data.selectSemester(value);
            },
          );
        },
      ),
    );
  }

  /// 學期代碼縮寫：`1142` → `114-2`（拿不到就用完整 label）。
  String _shortSemester(String value, String? fallback) {
    if (value.length >= 2) {
      return '${value.substring(0, value.length - 1)}-'
          '${value.substring(value.length - 1)}';
    }
    return fallback ?? value;
  }

  Widget _buildScheduleContent(DataProvider data) {
    final switching = data.isLoadingScheduleSemester;
    final events = data.displayedSchedule;
    final hasData = events.isNotEmpty;

    if (data.scheduleFailed && data.scheduleData.isEmpty && !switching) {
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
              onPressed: () => data.fetchSchedule(force: true),
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      );
    }

    if ((data.isLoadingSchedule || switching) && !hasData) {
      return _buildScheduleGrid(const <ScheduleEvent>[], isLoading: true);
    }

    if (!hasData) {
      return Center(child: Text(AppLocalizations.of(context).noScheduleData));
    }

    final grid = _buildScheduleGrid(events);

    // 沒有排定上課時間的課（times 為空）不會出現在格線裡，改用下方列表呈現。
    final noTimeCourses = events.where((c) => c.times.isEmpty).toList();
    final Widget content = noTimeCourses.isEmpty
        ? grid
        : Column(
            children: [
              Expanded(child: grid),
              _buildNoTimeSection(noTimeCourses, events),
            ],
          );

    if (!switching) return content;

    // 切換到另一個學期、抓取中：在現有課表上疊一層 loading。
    return Stack(
      children: [
        content,
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.45),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleGrid(
    List<ScheduleEvent> courses, {
    bool isLoading = false,
  }) {
    final allWeekDays = ['一', '二', '三', '四', '五', '六', '日'];
    const timeColumnWidth = 28.0;
    const headerHeight = 36.0;
    const minCellWidth = 46.0;
    const minCellHeight = 28.0;

    final uniqueCourseNames =
        courses
            .map((c) => c.name)
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

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
          } else if (day == '二')
            translatedDay = AppLocalizations.of(context).weekdayTue;
          else if (day == '三')
            translatedDay = AppLocalizations.of(context).weekdayWed;
          else if (day == '四')
            translatedDay = AppLocalizations.of(context).weekdayThu;
          else if (day == '五')
            translatedDay = AppLocalizations.of(context).weekdayFri;
          else if (day == '六')
            translatedDay = AppLocalizations.of(context).weekdaySat;
          else if (day == '日')
            translatedDay = AppLocalizations.of(context).weekdaySun;

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
                : _buildCourseCard(event, uniqueCourseNames);

            final cellWidget = Container(
              height: cellHeight * span,
              decoration: decoration,
              width: needsScroll ? minCellWidth : double.infinity,
              child: child,
            );

            cells.add(cellWidget);
            i += span - 1;
          }

          Widget columnWidget = Column(children: cells);

          final todayWeekday = ServerTimeService.instance.now().weekday;
          if (dayIndex + 1 == todayWeekday) {
            final lineY = _calculateTimeLineY(activePeriods, cellHeight);
            if (lineY != null) {
              columnWidget = Stack(
                clipBehavior: Clip.none,
                children: [
                  columnWidget,
                  Positioned(
                    top: lineY - 4,
                    left: 0,
                    right: 0,
                    height: 8,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(height: 3.0, color: Colors.red),
                        Positioned(
                          left: 0,
                          child: CustomPaint(
                            size: const Size(6, 8),
                            painter: TrianglePainter(
                              color: Colors.red,
                              isRight: true,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: CustomPaint(
                            size: const Size(6, 8),
                            painter: TrianglePainter(
                              color: Colors.red,
                              isRight: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
          }

          return needsScroll
              ? SizedBox(width: minCellWidth, child: columnWidget)
              : Expanded(child: columnWidget);
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
            margin: EdgeInsets.zero,
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
                                    fontSize: 12,
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
                                          AppLocalizations.of(
                                            context,
                                          ).periodDetails(period, time),
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
                                                    fontSize: 11,
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

  Widget _buildCourseCard(ScheduleEvent event, List<String> uniqueCourseNames) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasRoom = event.room != null && event.room!.isNotEmpty;
    final isLocatable = _isMapMode && hasRoom;

    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final displayName =
        (isEnglish && event.nameEn != null && event.nameEn!.trim().isNotEmpty)
        ? event.nameEn!
        : event.name;

    final courseIndex = uniqueCourseNames.indexOf(event.name);
    final courseColor = getCourseColor(context, courseIndex);

    final cardBgColor = isLocatable
        ? colorScheme.secondaryContainer.withValues(alpha: 0.95)
        : courseColor.backgroundColor;
    final cardBorder = isLocatable
        ? Border.all(color: colorScheme.secondary, width: 1.5)
        : Border.all(color: courseColor.borderColor, width: 0.5);
    final textThemeColor = isLocatable
        ? colorScheme.onSecondaryContainer
        : courseColor.textColor;
    final roomThemeColor = isLocatable
        ? colorScheme.onSecondaryContainer.withValues(alpha: 0.8)
        : courseColor.textColor.withValues(alpha: 0.75);

    final Widget card = GestureDetector(
      onTap: () {
        if (_isMapMode) {
          if (hasRoom) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    MapScreen(embed: false, targetRoomCode: event.room),
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
                    Text(
                      AppLocalizations.of(context).classroomLabel(
                        event.room ?? AppLocalizations.of(context).notDecided,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context).teacherLabel(event.teacher),
                    ),
                    const Divider(),
                    Text(
                      AppLocalizations.of(context).timeLabel(event.timeRoomStr),
                    ),
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
          color: cardBgColor,
          borderRadius: BorderRadius.circular(6),
          border: cardBorder,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                displayName,
                style: TextStyle(
                  fontSize: 13,
                  color: textThemeColor,
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
                      style: TextStyle(fontSize: 12, color: roomThemeColor),
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

    // 每次進到課表分頁或切換學期時（_fadeGen 改變），方塊以隨機錯開的方式淡入。
    return _FadeInCard(generation: _fadeGen, child: card);
  }

  /// 格線下方的「無安排上課時間」區塊：標題 + 一疊左側色條小卡片。
  Widget _buildNoTimeSection(
    List<ScheduleEvent> noTimeCourses,
    List<ScheduleEvent> allEvents,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final uniqueCourseNames =
        allEvents
            .map((c) => c.name)
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
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
                  AppLocalizations.of(context).scheduleNoTimeTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${noTimeCourses.length})',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: noTimeCourses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) =>
                  _buildNoTimeCard(noTimeCourses[i], uniqueCourseNames),
            ),
          ),
        ],
      ),
    );
  }

  /// 無時間課程的橫向小卡片：左側色條 + 課名 / 修別 / 學分 / 組合。
  Widget _buildNoTimeCard(ScheduleEvent event, List<String> uniqueCourseNames) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final displayName =
        (isEnglish && event.nameEn != null && event.nameEn!.trim().isNotEmpty)
        ? event.nameEn!
        : event.name;

    final courseIndex = uniqueCourseNames.indexOf(event.name);
    final courseColor = getCourseColor(context, courseIndex);

    final chips = <String>[
      if (event.classType.isNotEmpty) event.classType,
      if (event.credits.isNotEmpty)
        AppLocalizations.of(context).courseCreditsFormat(event.credits),
      if (event.courseClass.isNotEmpty) event.courseClass,
    ];

    return GestureDetector(
      onTap: () {
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
              content: Text(
                AppLocalizations.of(context).teacherLabel(event.teacher),
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
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.hardEdge,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: courseColor.borderColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (chips.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: chips
                              .map(
                                (label) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 學期切換膠囊：大小隨文字（不填滿），選中填 teal 色。
class _SemesterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SemesterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const Color _accent = Color(0xFF14B8A6);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _accent : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? _accent : cs.outlineVariant),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            height: 1.0,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.white : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// 課程方塊的「進場淡入」包裝：以隨機的小延遲錯開，讓一整批方塊淡入時
/// 有一點自然的隨機感。[generation] 改變時會重新播放一次淡入。
class _FadeInCard extends StatefulWidget {
  final Widget child;
  final int generation;
  const _FadeInCard({required this.child, required this.generation});

  @override
  State<_FadeInCard> createState() => _FadeInCardState();
}

class _FadeInCardState extends State<_FadeInCard> {
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(_FadeInCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.generation != widget.generation) {
      setState(() => _visible = false);
      _schedule();
    }
  }

  void _schedule() {
    _timer?.cancel();
    // 0–200ms 的隨機延遲：一點點就好，但足以有錯落感。
    final delayMs = Random().nextInt(200);
    _timer = Timer(Duration(milliseconds: delayMs), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 隱藏（重播前的重置）要瞬間完成，只有「淡入」才用動畫時間，
    // 否則重播時會先從 1.0 縮到 0.94 再長回來（看起來像先縮小再變大）。
    final duration = _visible
        ? const Duration(milliseconds: 200)
        : Duration.zero;
    return AnimatedScale(
      scale: _visible ? 1.0 : 0.94,
      duration: duration,
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _ShareScheduleCard extends StatelessWidget {
  final List<ScheduleEvent> courses;

  const _ShareScheduleCard({required this.courses});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    final uniqueCourseNames =
        courses
            .map((c) => c.name)
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    // 1. 提取學年與學期
    String year = '';
    String semester = '';
    for (var c in courses) {
      if (c.year != null && c.year!.isNotEmpty) {
        year = c.year!;
      }
      if (c.semester != null && c.semester!.isNotEmpty) {
        semester = c.semester!;
      }
      if (year.isNotEmpty && semester.isNotEmpty) break;
    }

    String titleText = '';
    if (year.isNotEmpty && semester.isNotEmpty) {
      titleText = isEnglish
          ? 'Academic Year $year, Sem $semester'
          : '$year學年度 第$semester學期 課表';
    } else {
      titleText = isEnglish ? 'Class Schedule' : '課表';
    }

    final schoolName = isEnglish
        ? 'National Yunlin University of Science and Technology'
        : '國立雲林科技大學';

    // 2. 計算活躍的星期與節次
    final periods = [
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

    int minDayIndex = 0;
    int maxDayIndex = 4;
    int minPeriodIndex = 1; // 預設 A
    int maxPeriodIndex = 9; // 預設 H

    if (courses.isNotEmpty) {
      int minDay = 6;
      int maxDay = 0;
      int minP = periods.length;
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
            int pIndex = periods.indexOf(t);
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
        minPeriodIndex = min(minP, 1).clamp(0, periods.length - 1);
        maxPeriodIndex = max(maxP, 9).clamp(minPeriodIndex, periods.length - 1);
      }
    }

    final activeDayIndices = List.generate(
      maxDayIndex - minDayIndex + 1,
      (i) => minDayIndex + i,
    );
    final activePeriods = periods.sublist(minPeriodIndex, maxPeriodIndex + 1);
    final allWeekDays = ['一', '二', '三', '四', '五', '六', '日'];

    // 3. 取得某天某節的課
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

    return Container(
      width: 480,
      height: 640,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant, width: 2),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header 區
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                schoolName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                titleText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Grid 區
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  // 左側節次欄
                  SizedBox(
                    width: 32,
                    child: Column(
                      children: [
                        // 左上角空白格
                        Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            border: Border(
                              bottom: BorderSide(
                                color: colorScheme.outlineVariant,
                              ),
                              right: BorderSide(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              isEnglish ? 'Pd.' : '節',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        // 節次列表
                        Expanded(
                          child: Column(
                            children: activePeriods.map((period) {
                              return Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: period == activePeriods.last
                                          ? BorderSide.none
                                          : BorderSide(
                                              color: colorScheme.outlineVariant,
                                            ),
                                      right: BorderSide(
                                        color: colorScheme.outlineVariant,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      period,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 右側星期與課程
                  Expanded(
                    child: Column(
                      children: [
                        // 頂部星期欄
                        Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            border: Border(
                              bottom: BorderSide(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                          child: Row(
                            children: activeDayIndices.map((i) {
                              String day = allWeekDays[i];
                              String displayDay = day;
                              if (isEnglish) {
                                if (day == '一')
                                  displayDay = 'Mon';
                                else if (day == '二')
                                  displayDay = 'Tue';
                                else if (day == '三')
                                  displayDay = 'Wed';
                                else if (day == '四')
                                  displayDay = 'Thu';
                                else if (day == '五')
                                  displayDay = 'Fri';
                                else if (day == '六')
                                  displayDay = 'Sat';
                                else if (day == '日')
                                  displayDay = 'Sun';
                              } else {
                                displayDay = '週$day';
                              }
                              return Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: i == activeDayIndices.last
                                          ? BorderSide.none
                                          : BorderSide(
                                              color: colorScheme.outlineVariant,
                                            ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      displayDay,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        // 課程內容網格
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: activeDayIndices.map((dayIndex) {
                              List<Widget> dayColumnCells = [];
                              for (int i = 0; i < activePeriods.length; i++) {
                                final period = activePeriods[i];
                                final event = getEventFor(dayIndex, period);

                                int span = 1;
                                if (event.name.isNotEmpty) {
                                  while (i + span < activePeriods.length) {
                                    final nextPeriod = activePeriods[i + span];
                                    final nextEvent = getEventFor(
                                      dayIndex,
                                      nextPeriod,
                                    );
                                    if (nextEvent.name == event.name &&
                                        nextEvent.semesterCourseNo ==
                                            event.semesterCourseNo) {
                                      span++;
                                    } else {
                                      break;
                                    }
                                  }
                                }

                                final hasCourse = event.name.isNotEmpty;
                                Widget cellChild;
                                if (hasCourse) {
                                  final displayName =
                                      (isEnglish &&
                                          event.nameEn != null &&
                                          event.nameEn!.trim().isNotEmpty)
                                      ? event.nameEn!
                                      : event.name;

                                  final courseIndex = uniqueCourseNames.indexOf(
                                    event.name,
                                  );
                                  final courseColor = getCourseColor(
                                    context,
                                    courseIndex,
                                  );

                                  cellChild = Container(
                                    margin: const EdgeInsets.all(2.0),
                                    padding: const EdgeInsets.all(4.0),
                                    decoration: BoxDecoration(
                                      color: courseColor.backgroundColor,
                                      borderRadius: BorderRadius.circular(6.0),
                                      border: Border.all(
                                        color: courseColor.borderColor,
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          displayName,
                                          maxLines: span > 1 ? 4 : 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: span > 1 ? 13.5 : 12.5,
                                            fontWeight: FontWeight.bold,
                                            color: courseColor.textColor,
                                            height: 1.1,
                                          ),
                                        ),
                                        if (event.room != null &&
                                            event.room!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            event.room!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              color: courseColor.textColor
                                                  .withValues(alpha: 0.75),
                                              height: 1.0,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                } else {
                                  cellChild = const SizedBox.shrink();
                                }

                                dayColumnCells.add(
                                  Expanded(
                                    flex: span,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom:
                                              i + span >= activePeriods.length
                                              ? BorderSide.none
                                              : BorderSide(
                                                  color: colorScheme
                                                      .outlineVariant
                                                      .withValues(alpha: 0.5),
                                                ),
                                          right:
                                              dayIndex == activeDayIndices.last
                                              ? BorderSide.none
                                              : BorderSide(
                                                  color: colorScheme
                                                      .outlineVariant
                                                      .withValues(alpha: 0.5),
                                                ),
                                        ),
                                      ),
                                      child: cellChild,
                                    ),
                                  ),
                                );
                                i += span - 1;
                              }

                              return Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: dayColumnCells,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CourseColor {
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  const CourseColor({
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });
}

CourseColor getCourseColor(BuildContext context, int index) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  // 淺色模式調色盤 (16種和諧柔和的粉彩莫蘭迪配色)
  final lightPalette = [
    // 1. 藍色
    const CourseColor(
      backgroundColor: Color(0xFFE0F2FE),
      textColor: Color(0xFF0369A1),
      borderColor: Color(0xFFBAE6FD),
    ),
    // 2. 綠色
    const CourseColor(
      backgroundColor: Color(0xFFDCFCE7),
      textColor: Color(0xFF15803D),
      borderColor: Color(0xFFBBF7D0),
    ),
    // 3. 粉紅
    const CourseColor(
      backgroundColor: Color(0xFFFCE7F3),
      textColor: Color(0xFFBE185D),
      borderColor: Color(0xFFFBCFE8),
    ),
    // 4. 黃橘
    const CourseColor(
      backgroundColor: Color(0xFFFEF3C7),
      textColor: Color(0xFFB45309),
      borderColor: Color(0xFFFDE68A),
    ),
    // 5. 紫色
    const CourseColor(
      backgroundColor: Color(0xFFF3E8FF),
      textColor: Color(0xFF6B21A8),
      borderColor: Color(0xFFE9D5FF),
    ),
    // 6. 青色
    const CourseColor(
      backgroundColor: Color(0xFFE0F7FA),
      textColor: Color(0xFF006064),
      borderColor: Color(0xFFB2EBF2),
    ),
    // 7. 靛藍
    const CourseColor(
      backgroundColor: Color(0xFFE0E7FF),
      textColor: Color(0xFF4338CA),
      borderColor: Color(0xFFC7D2FE),
    ),
    // 8. 橙色
    const CourseColor(
      backgroundColor: Color(0xFFFFEED9),
      textColor: Color(0xFFC2410C),
      borderColor: Color(0xFFFFD8A8),
    ),
    // 9. 薄荷綠
    const CourseColor(
      backgroundColor: Color(0xFFECFDF5),
      textColor: Color(0xFF047857),
      borderColor: Color(0xFFD1FAE5),
    ),
    // 10. 玫瑰紅
    const CourseColor(
      backgroundColor: Color(0xFFFFF1F2),
      textColor: Color(0xFFBE123C),
      borderColor: Color(0xFFFFE4E6),
    ),
    // 11. 琥珀黃
    const CourseColor(
      backgroundColor: Color(0xFFFEF9C3),
      textColor: Color(0xFF854D0E),
      borderColor: Color(0xFFFEF08A),
    ),
    // 12. 翠青綠
    const CourseColor(
      backgroundColor: Color(0xFFCCFBF1),
      textColor: Color(0xFF0F766E),
      borderColor: Color(0xFF99F6E4),
    ),
    // 13. 珊瑚紅
    const CourseColor(
      backgroundColor: Color(0xFFFFE4E6),
      textColor: Color(0xFF9F1239),
      borderColor: Color(0xFFFECDD3),
    ),
    // 14. 丁香紫
    const CourseColor(
      backgroundColor: Color(0xFFFAE8FF),
      textColor: Color(0xFF86198F),
      borderColor: Color(0xFFF5D0FE),
    ),
    // 15. 石頭褐
    const CourseColor(
      backgroundColor: Color(0xFFF5F5F4),
      textColor: Color(0xFF44403C),
      borderColor: Color(0xFFE7E5E4),
    ),
    // 16. 藍板岩
    const CourseColor(
      backgroundColor: Color(0xFFF1F5F9),
      textColor: Color(0xFF334155),
      borderColor: Color(0xFFE2E8F0),
    ),
  ];

  // 深色模式調色盤 (16種和諧明亮的深暗莫蘭迪配色)
  final darkPalette = [
    // 1. 藍色
    const CourseColor(
      backgroundColor: Color(0xFF082F49),
      textColor: Color(0xFF38BDF8),
      borderColor: Color(0xFF0C4A6E),
    ),
    // 2. 綠色
    const CourseColor(
      backgroundColor: Color(0xFF064E3B),
      textColor: Color(0xFF4ADE80),
      borderColor: Color(0xFF065F46),
    ),
    // 3. 粉紅
    const CourseColor(
      backgroundColor: Color(0xFF500724),
      textColor: Color(0xFFF472B6),
      borderColor: Color(0xFF701A40),
    ),
    // 4. 黃橘
    const CourseColor(
      backgroundColor: Color(0xFF451A03),
      textColor: Color(0xFFFBBF24),
      borderColor: Color(0xFF78350F),
    ),
    // 5. 紫色
    const CourseColor(
      backgroundColor: Color(0xFF3B0764),
      textColor: Color(0xFFC084FC),
      borderColor: Color(0xFF581C87),
    ),
    // 6. 青色
    const CourseColor(
      backgroundColor: Color(0xFF083344),
      textColor: Color(0xFF22D3EE),
      borderColor: Color(0xFF155E75),
    ),
    // 7. 靛藍
    const CourseColor(
      backgroundColor: Color(0xFF1E1B4B),
      textColor: Color(0xFF818CF8),
      borderColor: Color(0xFF312E81),
    ),
    // 8. 橙色
    const CourseColor(
      backgroundColor: Color(0xFF431407),
      textColor: Color(0xFFFB923C),
      borderColor: Color(0xFF7C2D12),
    ),
    // 9. 薄荷綠
    const CourseColor(
      backgroundColor: Color(0xFF022C22),
      textColor: Color(0xFF34D399),
      borderColor: Color(0xFF064E3B),
    ),
    // 10. 玫瑰紅
    const CourseColor(
      backgroundColor: Color(0xFF4C0519),
      textColor: Color(0xFFFDA4AF),
      borderColor: Color(0xFF881337),
    ),
    // 11. 琥珀黃
    const CourseColor(
      backgroundColor: Color(0xFF3F2F00),
      textColor: Color(0xFFFDE047),
      borderColor: Color(0xFF713F12),
    ),
    // 12. 翠青綠
    const CourseColor(
      backgroundColor: Color(0xFF042F2E),
      textColor: Color(0xFF2DD4BF),
      borderColor: Color(0xFF115E59),
    ),
    // 13. 珊瑚紅
    const CourseColor(
      backgroundColor: Color(0xFF3B100E),
      textColor: Color(0xFFFB7185),
      borderColor: Color(0xFF6F1D1B),
    ),
    // 14. 丁香紫
    const CourseColor(
      backgroundColor: Color(0xFF300B3B),
      textColor: Color(0xFFE879F9),
      borderColor: Color(0xFF4A1054),
    ),
    // 15. 石頭褐
    const CourseColor(
      backgroundColor: Color(0xFF292524),
      textColor: Color(0xFFD6D3D1),
      borderColor: Color(0xFF44403C),
    ),
    // 16. 藍板岩
    const CourseColor(
      backgroundColor: Color(0xFF1E293B),
      textColor: Color(0xFF94A3B8),
      borderColor: Color(0xFF334155),
    ),
  ];

  final palette = isDark ? darkPalette : lightPalette;
  if (index < 0) {
    return palette[0];
  }
  return palette[index % palette.length];
}

class TrianglePainter extends CustomPainter {
  final Color color;
  final bool isRight;

  TrianglePainter({required this.color, required this.isRight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isRight) {
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(0, size.height / 2);
      path.lineTo(size.width, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
