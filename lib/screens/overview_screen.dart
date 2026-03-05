import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../models/schedule_event.dart';
import '../models/calendar_event.dart';
import '../services/calendar_cache_service.dart';
import '../widgets/shimmer_box.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/top_snack_bar.dart';
import 'course_detail_screen.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  List<CalendarEvent>? _todayEvents;
  bool _isLoadingCalendar = true;

  @override
  void initState() {
    super.initState();
    _fetchTodayCalendar();
  }

  Future<void> _fetchTodayCalendar() async {
    try {
      final now = DateTime.now();
      final api = Provider.of<AuthProvider>(context, listen: false).api;

      // 使用 getOrFetch：自動讀快取 → miss 則呼叫 API → 寫快取，並行去重
      final response = await CalendarCacheService.getOrFetch(
        now.year,
        (year) => api.getCalendar(year),
      );

      if (response != null && response['success'] == true && mounted) {
        final List<dynamic> data = response['events'] ?? [];
        final events = data.map((e) => CalendarEvent.fromJson(e)).toList();

        // Filter for upcoming
        final todayStr =
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

        setState(() {
          final upcomingEvents = events
              .where((e) => e.date.compareTo(todayStr) >= 0)
              .toList();
          final todaysEvents = upcomingEvents
              .where((e) => e.date == todayStr)
              .toList();

          if (todaysEvents.length >= 4) {
            _todayEvents = todaysEvents;
          } else {
            _todayEvents = upcomingEvents.take(4).toList();
          }
          _isLoadingCalendar = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoadingCalendar = false;
            _todayEvents = [];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCalendar = false;
          _todayEvents = [];
        });
      }
    }
  }

  String _getGreeting(String name) {
    final now = DateTime.now();
    final timeDouble = now.hour + now.minute / 60.0;

    final displayName = name.isNotEmpty ? name : '';

    if (timeDouble >= 5.0 && timeDouble < 11.5) {
      return '早安，$displayName同學';
    } else if (timeDouble >= 11.5 && timeDouble < 17.0) {
      return '午安，$displayName同學';
    } else if (timeDouble >= 17.0 && timeDouble < 24.0) {
      return '晚安，$displayName同學';
    } else {
      return '別爆肝了...我也想休息...💤';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year} 年 ${date.month} 月 ${date.day} 日';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    return Scaffold(
      appBar: const CustomAppBar(title: '總覽'),
      body: Consumer2<AuthProvider, DataProvider>(
        builder: (context, auth, data, child) {
          final userName = auth.user?['user']?['name']?.toString() ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 歡迎與時間區域
                Text(
                  _getGreeting(userName),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '今天是 ${_formatDate(now)}',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 32),

                // 今日課程
                _buildTodayClassesSection(context, auth, data, colorScheme),

                const SizedBox(height: 32),

                // 近期行事曆
                _buildCalendarSection(colorScheme),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendarSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '近期校園行事曆',
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
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.surfaceContainerHighest),
          ),
          child:
              (_isLoadingCalendar &&
                  (_todayEvents == null || _todayEvents!.isEmpty))
              ? _buildCalendarSkeleton()
              : (_todayEvents == null || _todayEvents!.isEmpty) &&
                    !_isLoadingCalendar
              ? const Text(
                  '近期無任何校園行事曆事項安排。',
                  style: TextStyle(color: Colors.grey),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _todayEvents!.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.isImportant ? '⭐ ' : '📌 ',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Expanded(
                            child: Text(
                              '${e.date}  ${e.name}',
                              style: TextStyle(
                                height: 1.5,
                                fontWeight: e.isImportant
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
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
          Text(
            '今日課程',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  '您尚未登入，請先登入以使用完整功能',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final now = DateTime.now();
    final todayWeekday = now.weekday.toString();
    final isLoading = data.isLoadingSchedule && data.scheduleData.isEmpty;

    // 如果正在載入且沒有本地快取資料，顯示骨架屏
    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今日課程',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < 2; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(
                      width: 200,
                      height: 18,
                      margin: EdgeInsets.only(bottom: 8),
                    ),
                    ShimmerBox(
                      width: 150,
                      height: 14,
                      margin: EdgeInsets.only(bottom: 4),
                    ),
                    ShimmerBox(width: 100, height: 14),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    final schedule = data.scheduleData;

    // 過濾出今天的課
    final todayClasses = schedule
        .where((c) => c.weekday == todayWeekday)
        .toList();

    if (todayClasses.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今日課程',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  '今日無課程，好好放鬆吧！',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // 依照節次排序
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

    // 判斷當下或下一堂課
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
        // 取這堂課最後一節的結束時間
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

    // 將課程顯示出來
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '今日課程',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...todayClasses.map((c) {
          // 判斷狀態
          String classState = 'future';
          if (c == highlightClass) {
            classState = 'current';
          } else {
            // 如果比 Highlight class 早，或者是時間已經全走完
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

          String timeStr = '第 ${c.times.join(", ")} 節';

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

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildUpcomingClass(
              context,
              time: timeStr,
              className: c.name,
              location: (c.room != null && c.room!.isNotEmpty)
                  ? c.room!
                  : '未指定',
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
    required String state, // 'past', 'current', 'future'
    String? year,
    String? semester,
    String? courseNo,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    // 定義各狀態顏色
    final isCurrent = state == 'current';
    final isPast = state == 'past';

    final cardColor = isCurrent
        ? colorScheme.primaryContainer
        : colorScheme.surface;
    final borderColor = isCurrent
        ? Colors.transparent
        : colorScheme.outlineVariant;
    final titleColor = isPast
        ? Colors.grey
        : (isCurrent ? colorScheme.onPrimaryContainer : colorScheme.onSurface);
    final subtitleColor = isPast
        ? Colors.grey
        : (isCurrent
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant);
    final iconBgColor = isPast
        ? Colors.grey.withValues(alpha: 0.1)
        : (isCurrent
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surfaceContainerHighest);
    final iconColor = isPast
        ? Colors.grey
        : (isCurrent ? colorScheme.primary : colorScheme.onSurfaceVariant);

    return Card(
      elevation: isCurrent ? 2 : 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias, // 為 InkWell 保留波紋邊角
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
            showTopSnackBar(context, '這門課沒有提供詳細課綱', type: SnackBarType.warning);
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: iconColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: TextStyle(
                        color: iconColor,
                        fontWeight: FontWeight.w500,
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
