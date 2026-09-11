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
import '../widgets/skeleton_loading.dart';
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

  /// 骨架示意課程方塊的亂數種子。每個 State 實例固定一次：骨架顯示期間畫面
  /// 仍會因為每分鐘的時間線重繪而重建，每次重建都換位置會變成閃爍的雜訊。
  final int _skeletonSeed = Random().nextInt(1 << 30);

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
        // 離屏的分享卡。尺寸必須明確——`RepaintBoundary.toImage` 擷取的是已
        // 完成佈局的 RenderObject，沒有尺寸就沒有圖。高度隨課程內容變動，
        // 由 `ShareScheduleCard.heightFor` 用與卡片佈局相同的常數算出。
        Positioned(
          left: -9999,
          top: -9999,
          width: ShareScheduleCard.cardWidth + 16,
          height: ShareScheduleCard.heightFor(data.displayedSchedule) + 16,
          child: RepaintBoundary(
            key: _repaintKey,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              // 分享目前「顯示中」的學期，而非固定的當前學期——否則切到其他
              // 學期後分享出來的圖仍是當前學期。
              child: ShareScheduleCard(courses: data.displayedSchedule),
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

  /// 骨架某一天的格子：`(佔用節數, 是否是課程方塊)`。
  ///
  /// 約三分之一的節次起一個 1～3 節的方塊，做出真實課表那種疏密不均的樣子。
  /// 亂數由 [_skeletonSeed] 與 [dayIndex] 決定，同一次顯示中每次重建都相同。
  List<(int, bool)> _skeletonColumn(int dayIndex, int periodCount) {
    final rand = Random(_skeletonSeed + dayIndex);
    final cells = <(int, bool)>[];
    var i = 0;
    while (i < periodCount) {
      if (rand.nextInt(3) == 0) {
        final span = min(1 + rand.nextInt(3), periodCount - i);
        cells.add((span, true));
        i += span;
      } else {
        cells.add((1, false));
        i += 1;
      }
    }
    return cells;
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
              ? const Center(child: SkeletonBox(width: 24, height: 12))
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

        final cellDecoration = BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            ),
            right: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            ),
          ),
        );

        Widget buildColumnForDay(int dayIndex) {
          List<Widget> cells = [];

          // 骨架：把一天的格子填成疏密不一的示意課程方塊，讓使用者看得出
          // 正在載入的是一張課表，而不是一片空格線。
          if (isLoading) {
            for (final (span, filled) in _skeletonColumn(
              dayIndex,
              activePeriods.length,
            )) {
              cells.add(
                Container(
                  height: cellHeight * span,
                  decoration: cellDecoration,
                  width: needsScroll ? minCellWidth : double.infinity,
                  child: filled
                      ? Padding(
                          padding: const EdgeInsets.all(2),
                          child: SkeletonBox(
                            height: cellHeight * span - 4,
                            borderRadius: 4,
                          ),
                        )
                      : null,
                ),
              );
            }
            return needsScroll
                ? SizedBox(
                    width: minCellWidth,
                    child: Column(children: cells),
                  )
                : Expanded(child: Column(children: cells));
          }

          for (final cell in layout.column(dayIndex)) {
            final event = cell.event;
            final span = cell.span;

            final child = event == null
                ? null
                : _buildCourseCard(event, uniqueCourseNames);

            final cellWidget = Container(
              height: cellHeight * span,
              decoration: cellDecoration,
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
                            ? const Center(
                                child: SkeletonBox(width: 12, height: 12),
                              )
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
                                            ? const Center(
                                                child: SkeletonBox(
                                                  width: 11,
                                                  height: 10,
                                                ),
                                              )
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

/// 修別在英文模式時直接翻成英文（只寫英文、不併中文），中文模式維持原文。
///
/// 放在檔案層級而非畫面 State 裡，是因為分享卡是獨立的 widget，拿不到
/// `_ScheduleScreenState` 的私有方法，但兩邊要印出一模一樣的修別字樣。
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

/// 分享出去的課表圖卡。
///
/// 尺寸規則：**寬度固定、高度依內容算出**。高度不是讓 widget 自然撐開的——
/// 離屏 `RepaintBoundary.toImage` 需要一個已完成佈局的明確尺寸，所以由
/// [heightFor] 用下方那組常數先算好，外層再把這個數字釘在 `Positioned` 上。
/// 公式與佈局共用同一組常數，改任何一個都會兩邊一起變。
///
/// 之所以不沿用舊的固定 480×640：節次列數本來就會變（只有白天課是 9 列、
/// 有夜間課是 15 列），固定高度必然讓一部分人被壓扁——15 列時每列只剩 35 px，
/// 課名一定爆版。
class ShareScheduleCard extends StatelessWidget {
  final List<ScheduleEvent> courses;

  const ShareScheduleCard({super.key, required this.courses});

  // ── 尺寸常數（[heightFor] 與 build 共用）──────────────────────────
  static const double cardWidth = 560;
  static const double _cardPadding = 16;
  static const double _cardBorder = 4; // 卡片外框上下各 2
  static const double _headerHeight = 40;
  static const double _headerGap = 16;
  static const double _periodColumnWidth = 44;
  static const double _dayHeaderHeight = 24;
  static const double _rowHeight = 54;
  static const double _endStripHeight = 14;
  static const double _gridBorder = 2; // 外框上下各 1
  static const double _noTimeGap = 12;
  static const double _noTimeTitleHeight = 28;
  static const double _noTimeCardHeight = 36;
  static const double _noTimeCardGap = 8;

  /// 有排定時段的課才進格線；一門都沒有時回 null，格線整區省略。
  ///
  /// 傳進 [TimetableLayout.from] 的仍是完整的 [courses]（含無時間課），因為
  /// `courseNames` 決定配色順序——無時間課的色條要跟格線裡的課同一套顏色。
  static TimetableLayout? _layoutFor(List<ScheduleEvent> courses) {
    final hasScheduled = courses.any(
      (c) => c.name.isNotEmpty && c.times.isNotEmpty,
    );
    if (!hasScheduled) return null;
    return TimetableLayout.from(courses, allPeriods: ClassPeriods.codes);
  }

  static List<ScheduleEvent> _noTimeCoursesOf(List<ScheduleEvent> courses) =>
      courses.where((c) => c.name.isNotEmpty && c.times.isEmpty).toList();

  /// 這批課程畫出來的卡片高度。外層據此設定離屏容器的尺寸。
  static double heightFor(List<ScheduleEvent> courses) {
    final layout = _layoutFor(courses);
    final noTimeCount = _noTimeCoursesOf(courses).length;

    double height = _cardBorder + _cardPadding * 2 + _headerHeight;
    if (layout != null) {
      height +=
          _headerGap +
          _gridBorder +
          _dayHeaderHeight +
          layout.periods.length * _rowHeight +
          _endStripHeight;
    }
    if (noTimeCount > 0) {
      height +=
          _noTimeGap +
          _noTimeTitleHeight +
          noTimeCount * _noTimeCardHeight +
          (noTimeCount - 1) * _noTimeCardGap;
    }
    return height;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    final layout = _layoutFor(courses);
    final noTimeCourses = _noTimeCoursesOf(courses);

    final uniqueCourseNames =
        courses
            .map((c) => c.name)
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    // 學年與學期：取第一筆有值的。
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

    final String titleText;
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

    final card = Container(
      width: cardWidth,
      height: heightFor(courses),
      padding: const EdgeInsets.all(_cardPadding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant, width: 2),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _headerHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schoolName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // 行高釘死：header 是固定 [_headerHeight] 高，讓字體度量
                  // 決定行高的話換一套字型就會爆版。
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  titleText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.2,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (layout != null) ...[
            const SizedBox(height: _headerGap),
            _buildGrid(context, layout, uniqueCourseNames, isEnglish),
          ],
          if (noTimeCourses.isNotEmpty) ...[
            const SizedBox(height: _noTimeGap),
            _buildNoTimeSection(
              context,
              noTimeCourses,
              uniqueCourseNames,
              isEnglish,
            ),
          ],
        ],
      ),
    );

    // 分享圖的尺寸是算出來的固定值，不能被使用者的系統字級縮放推翻——
    // 放大字級時整張圖會爆版。截圖一律以標準字級繪製。
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: card,
    );
  }

  // ── 格線 ────────────────────────────────────────────────────────
  Widget _buildGrid(
    BuildContext context,
    TimetableLayout layout,
    List<String> uniqueCourseNames,
    bool isEnglish,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final periods = layout.periods;
    final dayIndices = layout.dayIndices;
    final gridHeight =
        _gridBorder +
        _dayHeaderHeight +
        periods.length * _rowHeight +
        _endStripHeight;

    const allWeekDays = ['一', '二', '三', '四', '五', '六', '日'];
    const englishWeekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final bandColor = colorScheme.surfaceContainerHighest;
    final lastEndText = ClassPeriods.byCode(periods.last)?.endText ?? '';

    return Container(
      height: gridHeight,
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左側節次欄：代碼（主）+ 起始時刻（輔）。
          //
          // 時刻是這張圖能被外校的人讀懂的關鍵：App 裡點一下節次會跳出時間，
          // 圖片上沒有那條路，只剩 A／B／C 這種雲科內部代碼。
          SizedBox(
            width: _periodColumnWidth,
            child: Column(
              children: [
                Container(
                  height: _dayHeaderHeight,
                  decoration: BoxDecoration(
                    color: bandColor,
                    border: Border(
                      bottom: BorderSide(color: colorScheme.outlineVariant),
                      right: BorderSide(color: colorScheme.outlineVariant),
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
                for (int i = 0; i < periods.length; i++)
                  Container(
                    height: _rowHeight,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: i == periods.length - 1
                            ? BorderSide.none
                            : BorderSide(color: colorScheme.outlineVariant),
                        right: BorderSide(color: colorScheme.outlineVariant),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            periods[i],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            ClassPeriods.byCode(periods[i])?.startText ?? '',
                            style: TextStyle(
                              fontSize: 8.5,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // 收尾列：最後一節的結束時刻。其他列的結束時刻可以從下一列的
                // 起始時刻讀出來，只有最後一列沒有下一列。
                Container(
                  height: _endStripHeight,
                  decoration: BoxDecoration(
                    color: bandColor,
                    border: Border(
                      top: BorderSide(color: colorScheme.outlineVariant),
                      right: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      lastEndText,
                      style: TextStyle(
                        fontSize: 8.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 右側星期欄與課程格。
          Expanded(
            child: Column(
              children: [
                Container(
                  height: _dayHeaderHeight,
                  decoration: BoxDecoration(
                    color: bandColor,
                    border: Border(
                      bottom: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  child: Row(
                    children: dayIndices.map((i) {
                      final displayDay = isEnglish
                          ? englishWeekDays[i]
                          : '週${allWeekDays[i]}';
                      return Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: i == dayIndices.last
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
                SizedBox(
                  height: periods.length * _rowHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: dayIndices.map((dayIndex) {
                      return Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _dayCells(
                            context,
                            layout,
                            dayIndex,
                            uniqueCourseNames,
                            isEnglish,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Container(
                  height: _endStripHeight,
                  decoration: BoxDecoration(
                    color: bandColor,
                    border: Border(
                      top: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 一天的格子。擺位（哪一格放什麼課、跨節合併幾格）由 [TimetableLayout]
  /// 決定，這裡只負責把它畫成固定列高的方塊。
  List<Widget> _dayCells(
    BuildContext context,
    TimetableLayout layout,
    int dayIndex,
    List<String> uniqueCourseNames,
    bool isEnglish,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final cells = layout.column(dayIndex);
    final isLastDay = dayIndex == layout.dayIndices.last;

    final widgets = <Widget>[];
    int consumed = 0;
    for (final cell in cells) {
      consumed += cell.span;
      final isLastRow = consumed >= layout.periods.length;
      final event = cell.event;

      Widget child = const SizedBox.shrink();
      if (event != null) {
        final displayName =
            (isEnglish &&
                event.nameEn != null &&
                event.nameEn!.trim().isNotEmpty)
            ? event.nameEn!
            : event.name;
        final courseColor = getCourseColor(
          context,
          uniqueCourseNames.indexOf(event.name),
        );

        child = Container(
          margin: const EdgeInsets.all(2.0),
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            color: courseColor.backgroundColor,
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(color: courseColor.borderColor, width: 0.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                displayName,
                maxLines: cell.span > 1 ? 4 : 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: cell.span > 1 ? 13.5 : 12.5,
                  fontWeight: FontWeight.bold,
                  color: courseColor.textColor,
                  height: 1.1,
                ),
              ),
              if (event.room != null && event.room!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  event.room!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: courseColor.textColor.withValues(alpha: 0.75),
                    height: 1.0,
                  ),
                ),
              ],
            ],
          ),
        );
      }

      widgets.add(
        Container(
          height: cell.span * _rowHeight,
          decoration: BoxDecoration(
            border: Border(
              bottom: isLastRow
                  ? BorderSide.none
                  : BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
              right: isLastDay
                  ? BorderSide.none
                  : BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
            ),
          ),
          child: child,
        ),
      );
    }
    return widgets;
  }

  // ── 無安排上課時間的課程 ──────────────────────────────────────────
  //
  // 這些課在格線上沒有任何落點，舊版分享圖等於把它們整批丟掉——分享出去的
  // 課表少了幾門課，而且沒有任何跡象。
  Widget _buildNoTimeSection(
    BuildContext context,
    List<ScheduleEvent> noTimeCourses,
    List<String> uniqueCourseNames,
    bool isEnglish,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _noTimeTitleHeight,
          child: Row(
            children: [
              Container(
                width: 4,
                height: 14,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).scheduleNoTimeTitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${noTimeCourses.length})',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        for (var i = 0; i < noTimeCourses.length; i++) ...[
          if (i > 0) const SizedBox(height: _noTimeCardGap),
          _buildNoTimeCard(
            context,
            noTimeCourses[i],
            uniqueCourseNames,
            isEnglish,
          ),
        ],
      ],
    );
  }

  Widget _buildNoTimeCard(
    BuildContext context,
    ScheduleEvent event,
    List<String> uniqueCourseNames,
    bool isEnglish,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayName =
        (isEnglish && event.nameEn != null && event.nameEn!.trim().isNotEmpty)
        ? event.nameEn!
        : event.name;
    final courseColor = getCourseColor(
      context,
      uniqueCourseNames.indexOf(event.name),
    );

    final meta = <String>[
      if (event.requiredType.isNotEmpty)
        _localizedRequiredType(event.requiredType, isEnglish),
      if (event.credits.isNotEmpty)
        AppLocalizations.of(context).courseCreditsFormat(event.credits),
    ].join(' · ');

    return Container(
      height: _noTimeCardHeight,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 5, color: courseColor.borderColor),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(width: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}
