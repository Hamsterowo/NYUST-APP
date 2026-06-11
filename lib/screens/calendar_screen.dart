import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../models/calendar_event.dart';
import '../services/api_service.dart';
import '../services/calendar_cache_service.dart';
import '../providers/navigation_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/timeline_painter.dart';

class CalendarScreen extends StatefulWidget {
  final bool embed;
  const CalendarScreen({super.key, this.embed = false});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;

  final Map<int, Map<String, List<CalendarEvent>>> _cachedGroupedEvents = {};

  final Map<int, Map<String, String>> _cachedHolidaysType = {};

  final Set<int> _fetchingYears = {};

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  int _currentYear = DateTime.now().year;

  bool _hasCheckedLegend = false;

  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _currentYear = _focusedDay.year;
    _fetchYearIfNeeded(_currentYear);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkAndShowLegend() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hideLegend = prefs.getBool('hide_calendar_legend') ?? false;
    if (!hideLegend && mounted) {
      _showLegendDialog();
    }
  }

  void _showLegendDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('行事曆圖示說明'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '日期背景顏色：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '1',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('今天日期'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('當前選取日期'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '1',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('國定假日'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '1',
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('寒假 / 暑假'),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '事件小點點：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('一般事件'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('重要事件'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('hide_calendar_legend', true);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('不再顯示'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('確定'),
            ),
          ],
        );
      },
    );
  }

  /// 從合併端點的回應資料解析並填入記憶體快取
  void _parseAndCacheData(int year, Map<String, dynamic> data) {
    final List<dynamic> eventsJson = data['events'] ?? [];
    final List<CalendarEvent> parsed = eventsJson
        .map((e) => CalendarEvent.fromJson(e))
        .toList();

    final Map<String, List<CalendarEvent>> newGrouped = {};
    for (var event in parsed) {
      newGrouped.putIfAbsent(event.date, () => []).add(event);
    }

    final Map<String, String> newHolidaysType = {};
    if (data['holidayDetails'] != null) {
      final Map<String, dynamic> details = data['holidayDetails'];
      details.forEach((date, type) {
        newHolidaysType[date] = type?.toString() ?? 'national';
      });
    } else if (data['holidays'] != null) {
      final List<dynamic> hList = data['holidays'];
      for (var date in hList) {
        newHolidaysType[date.toString()] = 'national';
      }
    }

    _cachedGroupedEvents[year] = newGrouped;
    _cachedHolidaysType[year] = newHolidaysType;
  }

  Future<void> _fetchYearIfNeeded(int year, {bool foreground = true}) async {

    if (_cachedGroupedEvents.containsKey(year)) {
      if (foreground && _isLoading && year == _currentYear) {
        setState(() => _isLoading = false);
      }
      return;
    }
    if (_fetchingYears.contains(year)) return;
    _fetchingYears.add(year);

    if (foreground) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {

      final data = await CalendarCacheService.getOrFetch(
        year,
        (y) => _apiService.getCalendar(y),
      );

      _fetchingYears.remove(year);

      if (data != null) {
        _parseAndCacheData(year, data);
        if (mounted) {
          setState(() {
            if (foreground && year == _currentYear) _isLoading = false;
            _errorMessage = null;
          });

          if (foreground) {
            _prefetchAdjacentYears(year);
          }
        }
      } else {
        if (foreground && mounted) {
          setState(() {
            _errorMessage = '載入失敗';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      _fetchingYears.remove(year);
      if (foreground && mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _prefetchAdjacentYears(int year) {
    _fetchYearIfNeeded(year - 1, foreground: false);
    _fetchYearIfNeeded(year + 1, foreground: false);
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final formattedDate =
        "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
    return _cachedGroupedEvents[_currentYear]?[formattedDate] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  void _onPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
    });
    final newYear = focusedDay.year;
    if (newYear != _currentYear) {
      final hasCached = _cachedGroupedEvents.containsKey(newYear);
      setState(() {
        _currentYear = newYear;
        _isLoading = !hasCached;
        _errorMessage = null;
      });
      _fetchYearIfNeeded(newYear);
    }
  }

  Widget? _buildHolidayBackground(BuildContext context, DateTime day) {
    final holidaysType = _cachedHolidaysType[_currentYear] ?? {};
    final formattedDate =
        "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
    if (!holidaysType.containsKey(formattedDate)) return null;

    final type = holidaysType[formattedDate]!;
    final isVacation = type == 'winter_vacation' || type == 'summer_vacation';
    final color = isVacation
        ? Colors.amber.withValues(alpha: 0.25)
        : Colors.red.withValues(alpha: 0.15);

    final prevDay = day.subtract(const Duration(days: 1));
    final nextDay = day.add(const Duration(days: 1));
    final prevFormatted =
        "${prevDay.year}-${prevDay.month.toString().padLeft(2, '0')}-${prevDay.day.toString().padLeft(2, '0')}";
    final nextFormatted =
        "${nextDay.year}-${nextDay.month.toString().padLeft(2, '0')}-${nextDay.day.toString().padLeft(2, '0')}";

    final prevType = holidaysType[prevFormatted];
    final nextType = holidaysType[nextFormatted];
    final bool isSamePrev =
        prevType == type &&
        day.weekday != DateTime.monday &&
        prevDay.month == day.month;
    final bool isSameNext =
        nextType == type &&
        day.weekday != DateTime.sunday &&
        nextDay.month == day.month;

    if (!isSamePrev && !isSameNext) {
      return Container(
        margin: const EdgeInsets.all(6.0),
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
    }

    final double leftMargin = isSamePrev ? 0.0 : 6.0;
    final double rightMargin = isSameNext ? 0.0 : 6.0;
    final Radius leftRadius = isSamePrev
        ? Radius.zero
        : const Radius.circular(24.0);
    final Radius rightRadius = isSameNext
        ? Radius.zero
        : const Radius.circular(24.0);

    return Container(
      margin: EdgeInsets.only(
        top: 6.0,
        bottom: 6.0,
        left: leftMargin,
        right: rightMargin,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.horizontal(
          left: leftRadius,
          right: rightRadius,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final navProvider = context.watch<NavigationProvider>();
    if ((navProvider.currentIndex == 3 || navProvider.currentIndex == 1) && !_hasCheckedLegend) {
      _hasCheckedLegend = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndShowLegend();
      });
    }

    final colorScheme = Theme.of(context).colorScheme;
    final selectedEvents = _selectedDay != null
        ? _getEventsForDay(_selectedDay!)
        : [];

    final bodyContent = _isLoading
          ? const CalendarSkeletonView()
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.tonal(
                    onPressed: () => _fetchYearIfNeeded(_currentYear),
                    child: const Text('重試'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    color: colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 8),
                              Text(
                                '${_focusedDay.year} 年 ${_focusedDay.month} 月',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              if (widget.embed) ...[
                                IconButton(
                                  icon: const Icon(Icons.info_outline, size: 20),
                                  tooltip: '圖示說明',
                                  onPressed: _showLegendDialog,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.today, size: 20),
                                  tooltip: '回到今日',
                                  onPressed: () {
                                    final now = DateTime.now();
                                    setState(() {
                                      _focusedDay = now;
                                      _selectedDay = now;
                                    });
                                    if (_currentYear != now.year) {
                                      final hasCached = _cachedGroupedEvents.containsKey(now.year);
                                      setState(() {
                                        _currentYear = now.year;
                                        _isLoading = !hasCached;
                                      });
                                      _fetchYearIfNeeded(now.year);
                                    }
                                  },
                                ),
                              ],
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: () {
                                  _pageController?.previousPage(
                                    duration: const Duration(
                                      milliseconds: 300,
                                    ),
                                    curve: Curves.easeOut,
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: () {
                                  _pageController?.nextPage(
                                    duration: const Duration(
                                      milliseconds: 300,
                                    ),
                                    curve: Curves.easeOut,
                                  );
                                },
                              ),
                            ],
                          ),
                          TableCalendar<CalendarEvent>(
                            onCalendarCreated: (controller) =>
                                _pageController = controller,
                              firstDay: DateTime.utc(2000, 1, 1),
                              lastDay: DateTime.utc(2100, 12, 31),
                              focusedDay: _focusedDay,
                              selectedDayPredicate: (day) =>
                                  isSameDay(_selectedDay, day),
                              onDaySelected: _onDaySelected,
                              onPageChanged: _onPageChanged,
                              eventLoader: _getEventsForDay,
                              headerVisible: false,
                              holidayPredicate: (day) {
                                final formattedDate =
                                    "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
                                return (_cachedHolidaysType[_currentYear] ?? {})
                                    .containsKey(formattedDate);
                              },
                              startingDayOfWeek: StartingDayOfWeek.monday,
                              rowHeight: 48,
                              daysOfWeekHeight: 24,
                              calendarStyle: CalendarStyle(
                                cellMargin: const EdgeInsets.all(
                                  6.0,
                                ),
                                todayDecoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                todayTextStyle: TextStyle(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                                selectedDecoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              calendarBuilders: CalendarBuilders(
                                selectedBuilder: (context, day, focusedDay) {
                                  final isOutside =
                                      day.month != focusedDay.month;
                                  final bg = isOutside
                                      ? null
                                      : _buildHolidayBackground(context, day);
                                  return Stack(
                                    children: [
                                      ?bg,
                                      Container(
                                        margin: const EdgeInsets.all(6.0),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${day.day}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                                todayBuilder: (context, day, focusedDay) {
                                  final isOutside =
                                      day.month != focusedDay.month;
                                  final bg = isOutside
                                      ? null
                                      : _buildHolidayBackground(context, day);
                                  return Stack(
                                    children: [
                                      ?bg,
                                      Container(
                                        margin: const EdgeInsets.all(6.0),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primaryContainer,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${day.day}',
                                          style: TextStyle(
                                            color:
                                                colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                                holidayBuilder: (context, day, focusedDay) {
                                  final isOutside =
                                      day.month != focusedDay.month;
                                  final formattedDate =
                                      "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
                                  final type =
                                      (_cachedHolidaysType[_currentYear] ??
                                          {})[formattedDate] ??
                                      'national';
                                  final isVacation =
                                      type == 'winter_vacation' ||
                                      type == 'summer_vacation';

                                  if (isOutside) {
                                    return Container(
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${day.day}',
                                        style: TextStyle(
                                          color: isVacation
                                              ? Colors.amber.withValues(
                                                  alpha: 0.55,
                                                )
                                              : Colors.red.withValues(
                                                  alpha: 0.55,
                                                ),
                                        ),
                                      ),
                                    );
                                  }

                                  final bg = _buildHolidayBackground(
                                    context,
                                    day,
                                  );
                                  return Stack(
                                    children: [
                                      ?bg,
                                      Container(
                                        margin: const EdgeInsets.all(6.0),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${day.day}',
                                          style: TextStyle(
                                            color: isVacation
                                                ? Colors.amber.shade900
                                                : Colors.red.shade900,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                                markerBuilder: (context, day, events) {
                                  if (events.isEmpty) return const SizedBox();
                                  if (isSameDay(_selectedDay, day)) {
                                    return const SizedBox();
                                  }
                                  final bool hasImportant = events
                                      .cast<CalendarEvent>()
                                      .any((e) => e.isImportant);

                                  return Positioned(
                                    bottom: 2,
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: hasImportant
                                            ? Colors.amber
                                            : colorScheme.primary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text('發生錯誤：$_errorMessage'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () =>
                                    _fetchYearIfNeeded(_currentYear),
                                child: const Text('重試'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                            left: 8,
                            right: 16,
                            bottom: 16,
                          ),
                          itemCount: selectedEvents.isEmpty
                              ? 2
                              : selectedEvents.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      child: CustomPaint(
                                        painter: TimelinePainter(
                                          isFirst: true,
                                          isLast: selectedEvents
                                              .isEmpty,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16.0,
                                        ),
                                        child: Text(
                                          '${_selectedDay?.year} 年 ${_selectedDay?.month} 月 ${_selectedDay?.day} 日',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (selectedEvents.isEmpty) {

                              return const Padding(
                                padding: EdgeInsets.only(left: 48.0, top: 16.0),
                                child: Text(
                                  '本日無行程',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            }

                            final eventIndex = index - 1;
                            final event = selectedEvents[eventIndex];
                            final bool isFirst = false;
                            final bool isLast =
                                eventIndex == selectedEvents.length - 1;
                            final bool isImportant = event.isImportant;

                            final Color lineColor = isImportant
                                ? Colors.amber
                                : colorScheme.primary;

                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [

                                  SizedBox(
                                    width: 40,
                                    child: CustomPaint(
                                      painter: TimelinePainter(
                                        isFirst: isFirst,
                                        isLast: isLast,
                                        color: lineColor,
                                      ),
                                    ),
                                  ),

                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2.0,
                                      ),
                                      child: Card(
                                        elevation: 0,
                                        color: isImportant
                                            ? Colors.amber.withValues(
                                                alpha: 0.15,
                                              )
                                            : colorScheme
                                                  .surfaceContainerHighest,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          side: BorderSide(
                                            color: isImportant
                                                ? Colors.amber.withValues(
                                                    alpha: 0.3,
                                                  )
                                                : Colors.transparent,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                            vertical: 8.0,
                                          ),
                                          child: Row(
                                            children: [
                                              if (isImportant) ...[
                                                Icon(
                                                  Icons.star,
                                                  color: Colors.amber.shade700,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              Expanded(
                                                child: Text(
                                                  event.name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight
                                                        .normal,
                                                    fontSize: 15,
                                                    color: isImportant
                                                        ? Colors.amber.shade900
                                                        : colorScheme
                                                              .onSurfaceVariant,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );

    if (widget.embed) {
      return bodyContent;
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: '行事曆',
        onRefresh: () async {
          await CalendarCacheService.clearAllCache();
          _cachedGroupedEvents.clear();
          _cachedHolidaysType.clear();
          _fetchingYears.clear();
          _fetchYearIfNeeded(_currentYear);
        },
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: '圖示說明',
            onPressed: _showLegendDialog,
          ),
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: '回到今日',
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                _focusedDay = now;
                _selectedDay = now;
              });
              if (_currentYear != now.year) {
                final hasCached = _cachedGroupedEvents.containsKey(now.year);
                setState(() {
                  _currentYear = now.year;
                  _isLoading = !hasCached;
                });
                _fetchYearIfNeeded(now.year);
              }
            },
          ),
        ],
      ),
      body: bodyContent,
    );
  }
}
