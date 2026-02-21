import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../models/calendar_event.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';
import '../providers/navigation_provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;

  // 依據日期分組的事件：Map<String, List<CalendarEvent>> => String 為 'yyyy-MM-dd'
  late Map<String, List<CalendarEvent>> _groupedEvents;

  // 節假日清單：Map<String, String> => 'yyyy-MM-dd': 'type'
  Map<String, String> _holidaysType = {};

  // Calendar 狀態
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 當前瀏覽的年份，若使用者翻頁到新的一年，則呼叫 API
  late int _loadedYear;

  // 記錄是否已經在此次掛載時檢查過，防止重複彈出
  bool _hasCheckedLegend = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadedYear = _focusedDay.year;
    _groupedEvents = {};
    _holidaysType = {};
    _fetchCalendarData(_loadedYear);
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
                      color: Colors.red.withOpacity(0.15),
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
                      color: Colors.amber.withOpacity(0.25),
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

  Future<void> _fetchCalendarData(int year) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getCalendar(year);
      if (data['success'] == true) {
        final List<dynamic> eventsJson = data['events'];

        final List<CalendarEvent> parsed = eventsJson
            .map((e) => CalendarEvent.fromJson(e))
            .toList();

        // 分組
        Map<String, List<CalendarEvent>> newGrouped = {};
        for (var event in parsed) {
          if (newGrouped[event.date] == null) {
            newGrouped[event.date] = [];
          }
          newGrouped[event.date]!.add(event);
        }

        // Fetch holidays simultaneously or subsequently
        Map<String, String> newHolidaysType = {};
        try {
          final holidayData = await _apiService.getHolidays(year);
          if (holidayData['success'] == true &&
              holidayData['holidays'] != null) {
            final List<dynamic> hList = holidayData['holidays'];
            if (holidayData['holidayDetails'] != null) {
              final Map<String, dynamic> details =
                  holidayData['holidayDetails'];
              for (var date in hList) {
                newHolidaysType[date.toString()] =
                    details[date.toString()]?.toString() ?? 'national';
              }
            } else {
              for (var date in hList) {
                newHolidaysType[date.toString()] = 'national';
              }
            }
          }
        } catch (e) {
          // Ignore holiday fetch failure, just don't show holidays
        }

        setState(() {
          _loadedYear = year;
          _groupedEvents = newGrouped;
          _holidaysType = newHolidaysType;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = data['message'] ?? '載入失敗';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    // API 給的日期格式是 yyyy-MM-dd
    final formattedDate =
        "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
    return _groupedEvents[formattedDate] ?? [];
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
    _focusedDay = focusedDay;
    // 如果切換到不同的年份，重新拉取該年份資料
    if (focusedDay.year != _loadedYear) {
      _fetchCalendarData(focusedDay.year);
    }
  }

  Widget? _buildHolidayBackground(BuildContext context, DateTime day) {
    final formattedDate =
        "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
    if (!_holidaysType.containsKey(formattedDate)) return null;

    final type = _holidaysType[formattedDate]!;
    final isVacation = type == 'winter_vacation' || type == 'summer_vacation';

    final prevDay = day.subtract(const Duration(days: 1));
    final nextDay = day.add(const Duration(days: 1));

    final prevFormatted =
        "${prevDay.year}-${prevDay.month.toString().padLeft(2, '0')}-${prevDay.day.toString().padLeft(2, '0')}";
    final nextFormatted =
        "${nextDay.year}-${nextDay.month.toString().padLeft(2, '0')}-${nextDay.day.toString().padLeft(2, '0')}";

    final prevType = _holidaysType[prevFormatted];
    final nextType = _holidaysType[nextFormatted];

    final bool isSamePrev = prevType == type && day.weekday != DateTime.monday;
    final bool isSameNext = nextType == type && day.weekday != DateTime.sunday;

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
        color: isVacation
            ? Colors.amber.withValues(alpha: 0.25)
            : Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.horizontal(
          left: leftRadius,
          right: rightRadius,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 監聽目前 Navigation 狀態，如果 currentIndex == 2 (行事曆) 則觸發檢查
    final navProvider = context.watch<NavigationProvider>();
    if (navProvider.currentIndex == 2 && !_hasCheckedLegend) {
      _hasCheckedLegend = true; // 標記為已檢查過
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndShowLegend();
      });
    }

    final colorScheme = Theme.of(context).colorScheme;
    final selectedEvents = _selectedDay != null
        ? _getEventsForDay(_selectedDay!)
        : [];

    return Scaffold(
      appBar: CustomAppBar(
        title: '行事曆',
        onRefresh: () => _fetchCalendarData(_loadedYear),
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
              if (_loadedYear != now.year) {
                _fetchCalendarData(now.year);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 月曆視圖
          TableCalendar<CalendarEvent>(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            onPageChanged: _onPageChanged,
            eventLoader: _getEventsForDay,
            holidayPredicate: (day) {
              final formattedDate =
                  "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
              return _holidaysType.containsKey(formattedDate);
            },
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false, // 隱藏 Weekly/Monthly 切換按鈕
              titleCentered: true,
            ),
            calendarStyle: CalendarStyle(
              cellMargin: const EdgeInsets.all(6.0), // 縮小圈圈範圍避免壓到下方 Marker
              todayDecoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(color: colorScheme.onPrimaryContainer),
              selectedDecoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              selectedBuilder: (context, day, focusedDay) {
                final bg = _buildHolidayBackground(context, day);
                return Stack(
                  children: [
                    if (bg != null) bg,
                    Container(
                      margin: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                );
              },
              todayBuilder: (context, day, focusedDay) {
                final bg = _buildHolidayBackground(context, day);
                return Stack(
                  children: [
                    if (bg != null) bg,
                    Container(
                      margin: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: TextStyle(color: colorScheme.onPrimaryContainer),
                      ),
                    ),
                  ],
                );
              },
              holidayBuilder: (context, day, focusedDay) {
                final bg = _buildHolidayBackground(context, day);
                final formattedDate =
                    "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
                final type = _holidaysType[formattedDate] ?? 'national';
                final isVacation =
                    type == 'winter_vacation' || type == 'summer_vacation';

                return Stack(
                  children: [
                    if (bg != null) bg,
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
                if (isSameDay(_selectedDay, day)) return const SizedBox();
                final bool hasImportant = events.cast<CalendarEvent>().any(
                  (e) => e.isImportant,
                );

                return Positioned(
                  bottom: 2,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasImportant ? Colors.amber : colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(),

          // 狀態或事件列表顯示區
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
                          onPressed: () => _fetchCalendarData(_loadedYear),
                          child: const Text('重試'),
                        ),
                      ],
                    ),
                  )
                : selectedEvents.isEmpty
                ? const Center(child: Text('本日無行程'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: selectedEvents.length,
                    itemBuilder: (context, index) {
                      final event = selectedEvents[index];
                      // 使風格更貼近 Android 16 (Material Design 3):
                      // 依照重要性切換顏色
                      final bool isImportant = event.isImportant;
                      final Color cardColor = isImportant
                          ? Colors.amber.withOpacity(0.2)
                          : colorScheme.secondaryContainer.withOpacity(0.5);
                      final Color barColor = isImportant
                          ? Colors.amber
                          : colorScheme.primary;

                      return Card(
                        elevation: 0,
                        color: cardColor,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            // 可擴充點擊事件
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 24, // 縮短高度
                                  decoration: BoxDecoration(
                                    color: barColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
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
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15, // 字體可微調
                                            color: isImportant
                                                ? Colors.amber.shade900
                                                : colorScheme
                                                      .onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
