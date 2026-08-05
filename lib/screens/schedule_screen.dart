import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/class_periods.dart';
import '../l10n/app_localizations.dart';
import '../models/schedule_event.dart';
import '../providers/data_provider.dart';
import '../providers/providers.dart';
import '../services/scrape_result.dart';
import '../services/server_time_service.dart';
import '../theme/course_palette.dart';
import '../utils/refresh_body_state.dart';
import '../utils/share_image/share_image.dart';
import '../utils/timetable_layout.dart';
import '../utils/top_snack_bar.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/fade_in_card.dart';
import '../widgets/triangle_painter.dart';
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

  /// 使用者主動觸發的更新（重新整理、重試）進行中。
  /// 與資料層的 `isLoadingSchedule` 並存而不混用：背景預抓也會設那個旗標
  /// （課表常駐於首頁分頁堆疊，離線恢復連線時資料層會自己重跑預抓），
  /// 只有這個為真時才蓋上骨架。
  bool _manualRefreshing = false;
  // 課程方塊淡入的「世代」：每次進到課表分頁或切換學期時 +1，
  // 讓所有方塊重新以隨機錯開的方式淡入一次（見 [FadeInCard]）。
  int _fadeGen = 0;
  final GlobalKey _repaintKey = GlobalKey();

  Timer? _timeLineTimer;

  /// 課表在首頁 `_screens` 中的分頁索引。
  static const int _scheduleTabIndex = 1;

  /// 五個分頁常駐於首頁 Stack，非當前分頁也會收到計時器回呼；
  /// 只有課表分頁被選中時才需要重繪時間線。
  bool get _isVisibleTab =>
      widget.embed || ref.read(navIndexProvider) == _scheduleTabIndex;

  @override
  void initState() {
    super.initState();
    _timeLineTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted && _isVisibleTab) {
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
      final times = ClassPeriods.byCode(activePeriods[i]);
      if (times == null) continue;
      final start = times.startMinutes;
      final end = times.endMinutes;

      if (nowMinutes >= start && nowMinutes <= end) {
        final ratio = (nowMinutes - start) / (end - start);
        return i * cellHeight + ratio * cellHeight;
      }

      if (i < activePeriods.length - 1) {
        final nextTimes = ClassPeriods.byCode(activePeriods[i + 1]);
        if (nextTimes != null) {
          final nextStart = nextTimes.startMinutes;
          if (nowMinutes > end && nowMinutes < nextStart) {
            return (i + 1) * cellHeight;
          }
        }
      }
    }
    return null;
  }

  /// 主動更新：蓋上骨架，失敗時跳提示——那是使用者按的，需要明確的回答。
  /// 提示長在這個回呼裡而不是監聽資料層的失敗狀態：課表常駐於分頁堆疊，
  /// 監聽會讓使用者人在行事曆分頁時跳出課表的提示。
  Future<void> _refresh(DataProvider data) async {
    setState(() => _manualRefreshing = true);
    try {
      final outcome = await data.fetchSchedule(force: true);
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

  /// 連線類錯誤 → 具名「無法連線至課表系統」；其他 → 通用提示。
  /// 錯誤頁與提示共用同一句，兩種呈現方式才不會像是兩種不同的問題。
  String _failureMessage(RefreshOutcome? reason) {
    final l10n = AppLocalizations.of(context);
    return reason == RefreshOutcome.networkError
        ? l10n.serviceUnavailable(l10n.serviceSchedule)
        : l10n.checkNetworkRetry;
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

      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await sharePngBytes(
        pngBytes,
        filename: 'schedule.png',
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null,
      );
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

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // 從其他分頁切回課表分頁時：重播課程方塊淡入、確保學期清單已載入；
    // 這次 setState 也會立即重算時間線（背景時計時器不重繪，見 initState）。
    ref.listen<int>(navIndexProvider, (prev, next) {
      if (next == _scheduleTabIndex && prev != _scheduleTabIndex && mounted) {
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
              // 分享目前「顯示中」的學期，而非固定的當前學期——否則切到其他
              // 學期後分享出來的圖仍是當前學期。
              child: _ShareScheduleCard(courses: data.displayedSchedule),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: CustomAppBar(
        title: AppLocalizations.of(context).navSchedule,
        onRefresh: () => _refresh(data),
        isLoading: data.isLoadingSchedule,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed:
                data.isLoadingSchedule ||
                    data.isLoadingScheduleSemester ||
                    data.displayedSchedule.isEmpty
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
          final value = sems[i].value;
          return _SemesterChip(
            label: _shortSemester(value, sems[i].label),
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

    // 切換到其他學期抓取失敗且無快取:顯示失敗提示與重試,
    // 而非默默 fallback 顯示當前學期的資料造成誤導。
    final sel = data.selectedSemester;
    if (data.semesterLoadFailed &&
        !switching &&
        sel != null &&
        sel != data.currentSemester &&
        !data.hasSemesterCache(sel)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).loadScheduleFailed,
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data.semesterLoadFailReason == RefreshOutcome.networkError
                  ? AppLocalizations.of(context).serviceUnavailable(
                      AppLocalizations.of(context).serviceSchedule,
                    )
                  : AppLocalizations.of(context).checkNetworkRetry,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () => data.selectSemester(sel),
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      );
    }

    // 紅色時間線的意思是「現在上到這裡」，只有在看**當前學期**時才成立。切到
    // 其他學期時那條線指的是另一個學期的某一天，是錯的資訊。
    //
    // 還不知道當前學期是哪一個時照常顯示：那時使用者看的必然是預設的當前學期。
    final showNowLine =
        data.currentSemester == null ||
        (data.selectedSemester ?? data.currentSemester) == data.currentSemester;

    // 課表的資料層沒有可為 null 的集合，「從未載入」與「真的零筆」只能從旗標
    // 推回來：沒有課且（正在抓或已失敗）＝ 還沒拿到這學期的課表；
    // 沒有課且兩者皆非 ＝ 真的零筆（例如休學、暑假）。
    final bool? isEmpty = hasData
        ? false
        : (data.isLoadingSchedule || switching || data.scheduleFailed
              ? null
              : true);

    switch (resolveRefreshBody(
      isEmpty: isEmpty,
      // 切換學期中不算失敗：那條路徑有自己的處理（見上方 semesterLoadFailed
      // 與下方的半透明遮罩），這裡不能讓當前學期的舊失敗蓋掉它。
      failed: data.scheduleFailed && !switching,
      manualRefreshing: _manualRefreshing,
    )) {
      case RefreshBodyState.skeleton:
        return _buildScheduleGrid(
          const <ScheduleEvent>[],
          isLoading: true,
          showNowLine: showNowLine,
        );
      case RefreshBodyState.error:
        return _buildScheduleError(data);
      case RefreshBodyState.empty:
        return Center(child: Text(AppLocalizations.of(context).noScheduleData));
      case RefreshBodyState.list:
        break;
    }

    final grid = _buildScheduleGrid(events, showNowLine: showNowLine);

    // 沒有排定上課時間的課（times 為空）不會出現在格線裡，改用下方列表呈現。
    // 課表維持整頁高度、不被下方列表壓縮，整頁改為可捲動以顯示列表。
    final noTimeCourses = events.where((c) => c.times.isEmpty).toList();
    final Widget content = noTimeCourses.isEmpty
        ? grid
        : LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: Column(
                children: [
                  // 課表略縮 32px，讓下方列表露一角，提示使用者可往下捲。
                  SizedBox(height: constraints.maxHeight - 32, child: grid),
                  _buildNoTimeSection(noTimeCourses, events),
                ],
              ),
            ),
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

  Widget _buildScheduleError(DataProvider data) {
    final colorScheme = Theme.of(context).colorScheme;
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
            AppLocalizations.of(context).loadScheduleFailed,
            style: TextStyle(fontSize: 18, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            _failureMessage(data.scheduleFailReason),
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

  Widget _buildScheduleGrid(
    List<ScheduleEvent> courses, {
    bool isLoading = false,
    bool showNowLine = true,
  }) {
    final allWeekDays = ['一', '二', '三', '四', '五', '六', '日'];
    const timeColumnWidth = 20.0;
    const headerHeight = 36.0;
    const minCellWidth = 46.0;
    const minCellHeight = 28.0;

    // 擺位規則（顯示哪幾天/哪幾節、每格放什麼課、跨節合併幾格）全部由
    // TimetableLayout 這個純模組決定；這裡只負責畫。
    final layout = TimetableLayout.from(
      courses,
      allPeriods: ClassPeriods.codes,
    );
    final uniqueCourseNames = layout.courseNames;
    final activeDayIndices = layout.dayIndices;
    final activePeriods = layout.periods;

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

        Widget buildColumnForDay(int dayIndex) {
          List<Widget> cells = [];

          for (final cell in layout.column(dayIndex)) {
            final event = cell.event;
            final span = cell.span;

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

            final child = isLoading || event == null
                ? null
                : _buildCourseCard(event, uniqueCourseNames);

            final cellWidget = Container(
              height: cellHeight * span,
              decoration: decoration,
              width: needsScroll ? minCellWidth : double.infinity,
              child: child,
            );

            cells.add(cellWidget);
          }

          Widget columnWidget = Column(children: cells);

          final todayWeekday = ServerTimeService.instance.now().weekday;
          if (showNowLine && dayIndex + 1 == todayWeekday) {
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
                                        final time = ClassPeriods.rangeText(
                                          period,
                                        );
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

    // 地圖模式下不改變課程的顏色/背景，僅以「高亮邊框 + 粗體標題 + 導航 icon」
    // 標示可定位的課程（見下方 cardBorder / fontWeight / near_me icon）。
    final cardBgColor = courseColor.backgroundColor;
    final cardBorder = isLocatable
        ? Border.all(color: colorScheme.secondary, width: 1.5)
        : Border.all(color: courseColor.borderColor, width: 0.5);
    final textThemeColor = courseColor.textColor;
    final roomThemeColor = courseColor.textColor.withValues(alpha: 0.75);

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
                  fontSize: 11,
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
                      style: TextStyle(fontSize: 10, color: roomThemeColor),
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
    return FadeInCard(generation: _fadeGen, child: card);
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
          for (var i = 0; i < noTimeCourses.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _buildNoTimeCard(noTimeCourses[i], uniqueCourseNames),
          ],
        ],
      ),
    );
  }

  /// 修別在英文模式時直接翻成英文（只寫英文、不併中文），中文模式維持原文。
  String _localizedRequiredType(String rawType, bool isEnglish) {
    final type = rawType.trim();
    if (!isEnglish) return type;
    if (type == '必修' || type.toLowerCase() == 'required') return 'Required';
    if (type == '選修' || type.toLowerCase() == 'elective') return 'Elective';
    if (type == '通識' || type.toLowerCase().contains('general')) {
      return 'General Education';
    }
    return type;
  }

  /// 無時間課程的橫向小卡片：左側色條 + 課名 / 修別 / 學分 / 系所課號。
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
      if (event.requiredType.isNotEmpty)
        _localizedRequiredType(event.requiredType, isEnglish), // 修別（必/選）
      if (event.credits.isNotEmpty)
        AppLocalizations.of(context).courseCreditsFormat(event.credits), // 學分
      if (event.deptCourseNo.isNotEmpty) event.deptCourseNo, // 系所課號
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
          color: selected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? cs.primary : cs.outlineVariant),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            height: 1.0,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? cs.onPrimary : cs.onSurfaceVariant,
          ),
        ),
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
