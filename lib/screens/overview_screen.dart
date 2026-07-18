import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../providers/providers.dart';
import '../models/schedule_event.dart';
import '../models/calendar_event.dart';
import '../services/calendar_cache_service.dart';
import '../widgets/shimmer_box.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/top_snack_bar.dart';
import 'course_detail_screen.dart';
import 'map_screen.dart';
import 'web_view_screen.dart';

class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key});

  @override
  ConsumerState<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen> {
  List<CalendarEvent>? _upcomingEvents;
  List<CalendarEvent>? _allEvents;
  List<String>? _holidays;
  bool _isLoadingCalendar = true;
  String? _currentLanguageCode;

  // 總覽頁的語意色：暖橘=需注意（放假倒數／重要行事曆／今日放假）、
  // 天藍=上課中、石板灰=錯誤。集中於此，避免同組色碼散落在多個 build 方法。
  static const Color _warmAccent = Color(0xFFEA580C);
  static const Color _schoolAccent = Color(0xFF0284C7);
  static const Color _countdownErrorColor = Color(0xFF475569);

  // 前述彩色卡片（暖橘／天藍／石板灰）上的文字色。集中管理，避免白字色碼散落。
  static const Color _onAccent = Colors.white;
  static const Color _onAccentMuted = Colors.white70;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentLanguageCode = Localizations.localeOf(context).languageCode;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchTodayCalendar();
      }
    });
  }

  Future<void> _handleRefresh() async {
    await _fetchTodayCalendar();
  }

  Future<void> _fetchTodayCalendar() async {
    try {
      final now = DateTime.now();
      final api = ref.read(authProvider).api;
      final lang = _currentLanguageCode ?? 'zh';

      final response = await CalendarCacheService.getOrFetch(
        now.year,
        lang,
        (year, {lang}) => api.getCalendar(year, lang: lang),
      );

      if (response != null && response['success'] == true && mounted) {
        final List<dynamic> data = response['events'] ?? [];
        final events = data.map((e) => CalendarEvent.fromJson(e)).toList();
        events.sort((a, b) => a.date.compareTo(b.date));
        final List<dynamic> holidaysData = response['holidays'] ?? [];
        final holidays = holidaysData.map((h) => h.toString()).toList();

        final todayStr =
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

        setState(() {
          _allEvents = events;
          _holidays = holidays;
          _upcomingEvents = events
              .where((e) => e.date.compareTo(todayStr) >= 0)
              .toList();
          _isLoadingCalendar = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _allEvents = [];
            _holidays = [];
            _isLoadingCalendar = false;
            _upcomingEvents = [];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _allEvents = [];
          _holidays = [];
          _isLoadingCalendar = false;
          _upcomingEvents = [];
        });
      }
    }
  }

  Map<String, dynamic> _getCountdownData(
    List<CalendarEvent> events,
    List<String> holidays,
    DateTime now,
  ) {
    final year = now.year;

    DateTime? winterStart;
    DateTime? sem2Start;
    DateTime? summerStart;
    DateTime? sem1Start;

    for (var event in events) {
      final date = event.getDateTime();
      if (date.year != year) continue;

      final name = event.name;
      final normalized = name.toLowerCase();

      final isWinterVacationStart =
          (name.contains('寒假') &&
              (name.contains('開始') ||
                  name.contains('起') ||
                  name.contains('放'))) ||
          (normalized.contains('winter vacation') &&
              (normalized.contains('begin') ||
                  normalized.contains('start') ||
                  normalized.contains('first day')));

      final isSummerVacationStart =
          (name.contains('暑假') &&
              (name.contains('開始') ||
                  name.contains('起') ||
                  name.contains('放'))) ||
          (normalized.contains('summer vacation') &&
              (normalized.contains('begin') ||
                  normalized.contains('start') ||
                  normalized.contains('first day')));

      final isClassesStart =
          name.contains('開始上課') ||
          name.contains('上課開始') ||
          name.contains('開學') ||
          name.contains('正式上課') ||
          normalized.contains('classes begin') ||
          normalized.contains('classes start') ||
          normalized.contains('school begin') ||
          normalized.contains('school start');

      if (isWinterVacationStart && (date.month == 12 || date.month == 1)) {
        winterStart = date;
      }
      if (isClassesStart && (date.month == 2 || date.month == 3)) {
        // Classes start must be at least 21 days after winter vacation starts.
        // This avoids matching administrative semester starts (like Feb 1st).
        if (winterStart != null && date.difference(winterStart).inDays < 21) {
          continue;
        }
        if (sem2Start == null || date.isBefore(sem2Start)) {
          sem2Start = date;
        }
      }
      if (isSummerVacationStart &&
          (date.month == 5 || date.month == 6 || date.month == 7)) {
        summerStart = date;
      }
      if (isClassesStart && (date.month == 8 || date.month == 9)) {
        // Classes start must be at least 35 days after summer vacation starts.
        // This avoids matching administrative semester starts (like Aug 1st).
        if (summerStart != null && date.difference(summerStart).inDays < 35) {
          continue;
        }
        if (sem1Start == null || date.isBefore(sem1Start)) {
          sem1Start = date;
        }
      }
    }

    if (winterStart == null ||
        sem2Start == null ||
        summerStart == null ||
        sem1Start == null) {
      return {'error': true, 'messageKey': 'vacationError'};
    }

    final adjustedWinterStart = _adjustStartDate(winterStart, holidays, year);
    final adjustedSummerStart = _adjustStartDate(summerStart, holidays, year);

    DateTime start;
    DateTime end;
    String labelKey;
    bool isVacation;

    final nowZero = DateTime(now.year, now.month, now.day);
    final winterStartZero = DateTime(
      adjustedWinterStart.year,
      adjustedWinterStart.month,
      adjustedWinterStart.day,
    );
    final sem2StartZero = DateTime(
      sem2Start.year,
      sem2Start.month,
      sem2Start.day,
    );
    final summerStartZero = DateTime(
      adjustedSummerStart.year,
      adjustedSummerStart.month,
      adjustedSummerStart.day,
    );
    final sem1StartZero = DateTime(
      sem1Start.year,
      sem1Start.month,
      sem1Start.day,
    );

    if (!nowZero.isBefore(winterStartZero) && nowZero.isBefore(sem2StartZero)) {
      start = winterStartZero;
      end = sem2StartZero;
      labelKey = 'winter';
      isVacation = true;
    } else if (!nowZero.isBefore(sem2StartZero) &&
        nowZero.isBefore(summerStartZero)) {
      start = sem2StartZero;
      end = summerStartZero;
      labelKey = 'summer';
      isVacation = false;
    } else if (!nowZero.isBefore(summerStartZero) &&
        nowZero.isBefore(sem1StartZero)) {
      start = summerStartZero;
      end = sem1StartZero;
      labelKey = 'summer';
      isVacation = true;
    } else if (!nowZero.isBefore(sem1StartZero)) {
      start = sem1StartZero;
      end = DateTime(year + 1, winterStartZero.month, winterStartZero.day);
      labelKey = 'winter';
      isVacation = false;
    } else {
      start = DateTime(year - 1, sem1StartZero.month, sem1StartZero.day);
      end = winterStartZero;
      labelKey = 'winter';
      isVacation = false;
    }

    final totalDays = end.difference(start).inDays;
    final remainingDays = end.difference(nowZero).inDays;

    if (totalDays <= 0 || remainingDays < 0) {
      return {'error': true, 'messageKey': 'vacationError'};
    }

    final elapsedDays = totalDays - remainingDays;
    double progress = elapsedDays / totalDays;
    if (progress < 0.0) progress = 0.0;
    if (progress > 1.0) progress = 1.0;

    final displayEnd = end.subtract(const Duration(days: 1));

    return {
      'error': false,
      'labelKey': labelKey,
      'remainingDays': remainingDays,
      'progress': progress,
      'isVacation': isVacation,
      'startStr':
          '${start.month.toString().padLeft(2, '0')}/${start.day.toString().padLeft(2, '0')}',
      'endStr':
          '${displayEnd.month.toString().padLeft(2, '0')}/${displayEnd.day.toString().padLeft(2, '0')}',
    };
  }

  DateTime _adjustStartDate(
    DateTime nominalStart,
    List<String> holidays,
    int currentYear,
  ) {
    DateTime adjusted = nominalStart;
    while (true) {
      final prevDay = adjusted.subtract(const Duration(days: 1));
      if (_isHoliday(prevDay, holidays, currentYear)) {
        adjusted = prevDay;
      } else {
        break;
      }
    }
    return adjusted;
  }

  bool _isHoliday(DateTime date, List<String> holidays, int currentYear) {
    if (date.year == currentYear) {
      final dateStr =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      return holidays.contains(dateStr);
    } else {
      return date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday;
    }
  }

  Widget _buildCountdownCard(
    BuildContext context,
    ColorScheme colorScheme,
    DateTime now,
  ) {
    if (_isLoadingCalendar || _allEvents == null) {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            ShimmerBox(
              width: 120,
              height: 18,
              margin: EdgeInsets.only(bottom: 12),
            ),
            ShimmerBox(
              width: double.infinity,
              height: 8,
              margin: EdgeInsets.only(bottom: 12),
            ),
            ShimmerBox(width: 80, height: 14),
          ],
        ),
      );
    }

    final data = _getCountdownData(_allEvents!, _holidays ?? [], now);

    if (data['error'] == true) {
      final msgKey = data['messageKey'] as String;
      String errorMsg = '無法顯示寒暑假時間';
      if (msgKey == 'vacationError') {
        errorMsg = AppLocalizations.of(context).vacationError;
      }
      const Color errorColor = _countdownErrorColor;
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: errorColor,
          boxShadow: [
            BoxShadow(
              color: errorColor.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: _onAccentMuted, size: 24),
              const SizedBox(width: 12),
              Text(
                errorMsg,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _onAccent,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final String labelKey = data['labelKey'] ?? '';
    String label = '';
    if (labelKey == 'winter') {
      label = AppLocalizations.of(context).vacationLabelWinter;
    } else if (labelKey == 'summer') {
      label = AppLocalizations.of(context).vacationLabelSummer;
    }

    final bool isVacation = data['isVacation'] ?? false;
    final Color cardColor = isVacation ? _warmAccent : _schoolAccent;

    // progress 為「已度過」比例；上課與放假兩狀態的進度條一律 0→100 填滿。
    final double progress = data['progress'] ?? 0.0;

    return GestureDetector(
      onTap: () => _showVacationInfoDialog(context),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: cardColor,
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _onAccent,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        isVacation
                            ? AppLocalizations.of(
                                context,
                              ).vacationCountdownPrefix
                            : AppLocalizations.of(
                                context,
                              ).vacationCountdownPrefixSchool,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _onAccentMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${data['remainingDays']}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _onAccent,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context).vacationCountdownSuffix,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _onAccentMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: _onAccent.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(_onAccent),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(
                      context,
                    ).vacationElapsed((progress * 100).toStringAsFixed(0)),
                    style: const TextStyle(
                      fontSize: 12,
                      color: _onAccentMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${data['startStr']} - ${data['endStr']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _onAccentMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVacationInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).vacationInfoTitle),
          content: Text(AppLocalizations.of(context).vacationInfoContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context).close),
            ),
          ],
        );
      },
    );
  }

  String? _lastLocale;

  @override
  Widget build(BuildContext context) {
    final newLocale = Localizations.localeOf(context).toString();
    if (_lastLocale != null && _lastLocale != newLocale) {
      _isLoadingCalendar = true;
      _allEvents = null;
      _upcomingEvents = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchTodayCalendar();
      });
    }
    _lastLocale = newLocale;

    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    return Scaffold(
      appBar: CustomAppBar(title: AppLocalizations.of(context).navOverview),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Builder(
          builder: (context) {
            final auth = ref.watch(authProvider);
            final data = ref.watch(dataProvider);
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCountdownCard(context, colorScheme, now),
                  const SizedBox(height: 24),

                  _buildTodayClassesSection(context, auth, data, colorScheme),

                  const SizedBox(height: 32),

                  _buildCalendarSection(colorScheme),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCalendarSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).upcomingEventsTitle,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16.0),
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.surfaceContainerHighest),
          ),
          child:
              (_isLoadingCalendar &&
                  (_upcomingEvents == null || _upcomingEvents!.isEmpty))
              ? _buildCalendarSkeleton()
              : (_upcomingEvents == null || _upcomingEvents!.isEmpty) &&
                    !_isLoadingCalendar
              ? Text(
                  AppLocalizations.of(context).noUpcomingEvents,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: Scrollbar(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _upcomingEvents!.length,
                      itemBuilder: (context, i) => _buildCalendarEventRow(
                        _upcomingEvents![i],
                        colorScheme,
                        isFirst: i == 0,
                        isLast: i == _upcomingEvents!.length - 1,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  /// 近期行事曆的時間軸單列：左側日期、中間圓點連接線、右側事件名。
  /// 有連結的事件整列可點擊，用 WebView 開啟。
  Widget _buildCalendarEventRow(
    CalendarEvent e,
    ColorScheme colorScheme, {
    required bool isFirst,
    required bool isLast,
  }) {
    final hasLink = e.link.isNotEmpty;
    final date = e.getDateTime();
    final dateStr =
        '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

    final Color dotColor = e.isImportant ? _warmAccent : colorScheme.primary;
    final Color lineColor = colorScheme.outlineVariant;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(date.year, date.month, date.day);
    final diffDays = eventDay.difference(today).inDays;
    final l10n = AppLocalizations.of(context);
    final String relativeStr = diffDays <= 0
        ? l10n.eventToday
        : diffDays == 1
        ? l10n.eventTomorrow
        : l10n.eventInDays(diffDays);
    final bool isSoon = diffDays <= 1;

    final row = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 日期
          SizedBox(
            width: 44,
            child: Center(
              child: Text(
                dateStr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          // 時間軸：上連接線、圓點、下連接線
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst ? Colors.transparent : lineColor,
                  ),
                ),
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: e.isImportant ? dotColor : colorScheme.surface,
                    border: Border.all(color: dotColor, width: 2),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : lineColor,
                  ),
                ),
              ],
            ),
          ),
          // 事件名稱與相對時間
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (e.isImportant)
                              const Text('⭐ ', style: TextStyle(fontSize: 14)),
                            Expanded(
                              child: Text(
                                e.name,
                                style: TextStyle(
                                  height: 1.3,
                                  fontWeight: e.isImportant
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          relativeStr,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSoon
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSoon
                                ? dotColor
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasLink)
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (!hasLink) return row;

    return InkWell(onTap: () => _openEventLink(e.link), child: row);
  }

  void _openEventLink(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppWebViewScreen(url: url, injectCookies: false),
      ),
    );
  }

  /// 「今日課程」標題；若今天是行事曆上的假日，於標題右側附註一個小標籤。
  Widget _buildTodayClassesHeader(BuildContext context) {
    final title = Text(
      AppLocalizations.of(context).todayClassesTitle,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );

    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final isTodayHoliday = _holidays?.contains(todayStr) ?? false;

    if (!isTodayHoliday) return title;

    const holidayColor = _warmAccent;
    return Row(
      children: [
        Flexible(child: title),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: holidayColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            AppLocalizations.of(context).todayHolidayNote,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: holidayColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayClassesSection(
    BuildContext context,
    AuthProvider auth,
    DataProvider data,
    ColorScheme colorScheme,
  ) {
    if (!auth.isLoggedIn) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTodayClassesHeader(context),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  AppLocalizations.of(context).notLoggedInMessage,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final now = DateTime.now();
    final todayWeekday = now.weekday.toString();
    final isLoading =
        !data.isCacheLoaded ||
        ((data.isPrefetching || data.isLoadingSchedule) &&
            data.scheduleData.isEmpty);

    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTodayClassesHeader(context),
          const SizedBox(height: 16),
          for (int i = 0; i < 2; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Card(
                elevation: 0,
                color: colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          ShimmerBox(
                            width: 120,
                            height: 16,
                            margin: EdgeInsets.only(bottom: 8),
                          ),
                          ShimmerBox(width: 180, height: 18),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const ShimmerBox(width: 60, height: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    }

    final schedule = data.scheduleData;

    final todayClasses = schedule
        .where((c) => c.weekday == todayWeekday)
        .toList();

    if (todayClasses.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTodayClassesHeader(context),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  AppLocalizations.of(context).noClassesToday,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final periods = [
      'M',
      'A',
      '1',
      '2',
      '3',
      '4',
      'B',
      '5',
      '6',
      '7',
      '8',
      'C',
      'D',
      'E',
      'F',
      'G',
    ];
    todayClasses.sort((a, b) {
      final aFirst = a.times.isNotEmpty ? a.times.first : '';
      final bFirst = b.times.isNotEmpty ? b.times.first : '';
      final aIdx = periods.indexOf(aFirst);
      final bIdx = periods.indexOf(bFirst);
      return aIdx.compareTo(bIdx);
    });

    ScheduleEvent? highlightClass;

    final periodEndTimes = {
      'X': const TimeOfDay(hour: 8, minute: 0),
      'A': const TimeOfDay(hour: 9, minute: 0),
      'B': const TimeOfDay(hour: 10, minute: 0),
      'C': const TimeOfDay(hour: 11, minute: 0),
      'D': const TimeOfDay(hour: 12, minute: 0),
      'Y': const TimeOfDay(hour: 13, minute: 0),
      'E': const TimeOfDay(hour: 14, minute: 0),
      'F': const TimeOfDay(hour: 15, minute: 0),
      'G': const TimeOfDay(hour: 16, minute: 0),
      'H': const TimeOfDay(hour: 17, minute: 0),
      'Z': const TimeOfDay(hour: 18, minute: 0),
      'I': const TimeOfDay(hour: 19, minute: 15),
      'J': const TimeOfDay(hour: 20, minute: 10),
      'K': const TimeOfDay(hour: 21, minute: 5),
      'L': const TimeOfDay(hour: 22, minute: 0),
    };

    final periodTimeRanges = {
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

    final currentMinutes = now.hour * 60 + now.minute;

    for (var c in todayClasses) {
      if (c.times.isNotEmpty) {
        final lastPeriod = c.times.last;
        final endTime = periodEndTimes[lastPeriod];
        if (endTime != null) {
          final endMinutes = endTime.hour * 60 + endTime.minute;
          if (currentMinutes <= endMinutes) {
            highlightClass = c;
            break;
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTodayClassesHeader(context),
        const SizedBox(height: 16),
        ...todayClasses.map((c) {
          String classState = 'future';
          if (c == highlightClass) {
            classState = 'current';
          } else {
            if (c.times.isNotEmpty) {
              final lastPeriod = c.times.last;
              final endTime = periodEndTimes[lastPeriod];
              if (endTime != null) {
                final endMinutes = endTime.hour * 60 + endTime.minute;
                if (currentMinutes > endMinutes) {
                  classState = 'past';
                }
              }
            }
          }

          String timeStr = AppLocalizations.of(
            context,
          ).classPeriods(c.times.join(", "));

          if (c.times.isNotEmpty) {
            final firstPeriod = c.times.first;
            final lastPeriod = c.times.last;
            if (periodTimeRanges.containsKey(firstPeriod) &&
                periodTimeRanges.containsKey(lastPeriod)) {
              final startTime = periodTimeRanges[firstPeriod]!.split(' - ')[0];
              final endTime = periodTimeRanges[lastPeriod]!.split(' - ')[1];
              timeStr += ' ($startTime - $endTime)';
            }
          }

          final isEnglish =
              Localizations.localeOf(context).languageCode == 'en';
          final displayName =
              (isEnglish && c.nameEn != null && c.nameEn!.trim().isNotEmpty)
              ? c.nameEn!
              : c.name;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildUpcomingClass(
              context,
              time: timeStr,
              className: displayName,
              location: (c.room != null && c.room!.isNotEmpty)
                  ? c.room!
                  : AppLocalizations.of(context).notSpecified,
              roomCode: c.room,
              state: classState,
              year: c.year,
              semester: c.semester,
              courseNo: c.courseNo,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildUpcomingClass(
    BuildContext context, {
    required String time,
    required String className,
    required String location,
    required String state,
    String? roomCode,
    String? year,
    String? semester,
    String? courseNo,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final isCurrent = state == 'current';
    final isPast = state == 'past';

    final cardColor = isCurrent
        ? const Color.fromARGB(255, 172, 255, 251)
        : colorScheme.surface;
    final borderColor = isCurrent
        ? Colors.transparent
        : colorScheme.outlineVariant;
    final titleColor = isPast
        ? colorScheme.onSurfaceVariant
        : (isCurrent ? colorScheme.onPrimaryContainer : colorScheme.onSurface);
    final subtitleColor = isPast
        ? colorScheme.onSurfaceVariant
        : (isCurrent
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant);
    final iconBgColor = isPast
        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.1)
        : (isCurrent
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surfaceContainerHighest);
    final iconColor = isPast
        ? colorScheme.onSurfaceVariant
        : (isCurrent ? colorScheme.primary : colorScheme.onSurfaceVariant);

    return Card(
      elevation: isCurrent ? 2 : 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (year != null && semester != null && courseNo != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseDetailScreen(
                  year: year,
                  semester: semester,
                  courseNo: courseNo,
                  courseName: className,
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.45,
                    child: Text(
                      className,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _buildLocationBadge(
                context,
                location: location,
                roomCode: roomCode,
                iconBgColor: iconBgColor,
                iconColor: iconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 每日課程卡片右側的地點膠囊。有教室時可點擊，導向地圖頁並定位該教室。
  Widget _buildLocationBadge(
    BuildContext context, {
    required String location,
    required String? roomCode,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    final hasRoom = roomCode != null && roomCode.trim().isNotEmpty;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_outlined, size: 16, color: iconColor),
          const SizedBox(width: 4),
          Text(
            location,
            style: TextStyle(color: iconColor, fontWeight: FontWeight.w500),
          ),
          if (hasRoom) ...[
            const SizedBox(width: 4),
            Icon(Icons.near_me_rounded, size: 14, color: iconColor),
          ],
        ],
      ),
    );

    if (!hasRoom) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: iconBgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: content,
      );
    }

    return Material(
      color: iconBgColor,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  MapScreen(embed: false, targetRoomCode: roomCode),
            ),
          );
        },
        child: content,
      ),
    );
  }

  Widget _buildCalendarSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        ShimmerBox(
          width: double.infinity,
          height: 18,
          margin: EdgeInsets.only(bottom: 10),
        ),
        ShimmerBox(
          width: double.infinity,
          height: 18,
          margin: EdgeInsets.only(bottom: 10),
        ),
        ShimmerBox(width: 200, height: 18),
      ],
    );
  }
}
