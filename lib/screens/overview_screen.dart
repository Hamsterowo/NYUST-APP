import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../models/schedule_event.dart';
import '../models/calendar_event.dart';
import '../services/calendar_cache_service.dart';
import '../widgets/shimmer_box.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/top_snack_bar.dart';
import 'course_detail_screen.dart';
import 'terms_of_service_screen.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  List<CalendarEvent>? _todayEvents;
  List<CalendarEvent>? _allEvents;
  bool _isLoadingCalendar = true;

  @override
  void initState() {
    super.initState();
    _fetchTodayCalendar();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTermsAgreement();
    });
  }

  Future<void> _checkTermsAgreement() async {
    final prefs = await SharedPreferences.getInstance();
    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;

    final String lastAcceptedVersion =
        prefs.getString('accepted_terms_version') ?? '';

    if (lastAcceptedVersion != currentVersion) {
      if (mounted) {
        final bool? agreed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const TermsOfServiceScreen(showAgreementButtons: true),
          ),
        );

        if (agreed == true) {
          await prefs.setString('accepted_terms_version', currentVersion);
        }
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchTodayCalendar();
  }

  Future<void> _fetchTodayCalendar() async {
    try {
      final now = DateTime.now();
      final api = Provider.of<AuthProvider>(context, listen: false).api;

      final response = await CalendarCacheService.getOrFetch(
        now.year,
        (year) => api.getCalendar(year),
      );

      if (response != null && response['success'] == true && mounted) {
        final List<dynamic> data = response['events'] ?? [];
        final events = data.map((e) => CalendarEvent.fromJson(e)).toList();

        final todayStr =
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

        setState(() {
          _allEvents = events;
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
            _allEvents = [];
            _isLoadingCalendar = false;
            _todayEvents = [];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _allEvents = [];
          _isLoadingCalendar = false;
          _todayEvents = [];
        });
      }
    }
  }

  Map<String, dynamic> _getCountdownData(
    List<CalendarEvent> events,
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

      if ((name.contains('寒假') &&
              (name.contains('開始') ||
                  name.contains('起') ||
                  name.contains('放'))) &&
          (date.month == 12 || date.month == 1)) {
        winterStart = date;
      }
      if ((name.contains('開始上課') ||
              name.contains('上課開始') ||
              name.contains('開學') ||
              name.contains('正式上課')) &&
          (date.month == 2 || date.month == 3)) {
        if (sem2Start == null || date.isBefore(sem2Start)) {
          sem2Start = date;
        }
      }
      if ((name.contains('暑假') &&
              (name.contains('開始') ||
                  name.contains('起') ||
                  name.contains('放'))) &&
          (date.month == 5 || date.month == 6 || date.month == 7)) {
        summerStart = date;
      }
      if ((name.contains('開始上課') ||
              name.contains('上課開始') ||
              name.contains('開學') ||
              name.contains('正式上課')) &&
          (date.month == 8 || date.month == 9)) {
        if (sem1Start == null || date.isBefore(sem1Start)) {
          sem1Start = date;
        }
      }
    }

    if (winterStart == null ||
        sem2Start == null ||
        summerStart == null ||
        sem1Start == null) {
      return {'error': true, 'message': '無法顯示寒暑假時間'};
    }

    DateTime start;
    DateTime end;
    String label;
    bool isVacation;

    final nowZero = DateTime(now.year, now.month, now.day);
    final winterStartZero = DateTime(
      winterStart.year,
      winterStart.month,
      winterStart.day,
    );
    final sem2StartZero = DateTime(
      sem2Start.year,
      sem2Start.month,
      sem2Start.day,
    );
    final summerStartZero = DateTime(
      summerStart.year,
      summerStart.month,
      summerStart.day,
    );
    final sem1StartZero = DateTime(
      sem1Start.year,
      sem1Start.month,
      sem1Start.day,
    );

    if (nowZero.isAfter(winterStartZero) && nowZero.isBefore(sem2StartZero)) {
      start = winterStartZero;
      end = sem2StartZero;
      label = '開學';
      isVacation = true;
    } else if (nowZero.isAfter(sem2StartZero) &&
        nowZero.isBefore(summerStartZero)) {
      start = sem2StartZero;
      end = summerStartZero;
      label = '暑假';
      isVacation = false;
    } else if (nowZero.isAfter(summerStartZero) &&
        nowZero.isBefore(sem1StartZero)) {
      start = summerStartZero;
      end = sem1StartZero;
      label = '開學';
      isVacation = true;
    } else if (nowZero.isAfter(sem1StartZero)) {
      start = sem1StartZero;
      end = DateTime(year + 1, winterStartZero.month, winterStartZero.day);
      label = '寒假';
      isVacation = false;
    } else {
      start = DateTime(year - 1, sem1StartZero.month, sem1StartZero.day);
      end = winterStartZero;
      label = '寒假';
      isVacation = false;
    }

    final totalDays = end.difference(start).inDays;
    final remainingDays = end.difference(nowZero).inDays;

    if (totalDays <= 0 || remainingDays < 0) {
      return {'error': true, 'message': '無法顯示寒暑假時間'};
    }

    final elapsedDays = totalDays - remainingDays;
    double progress = elapsedDays / totalDays;
    if (progress < 0.0) progress = 0.0;
    if (progress > 1.0) progress = 1.0;

    return {
      'error': false,
      'label': label,
      'remainingDays': remainingDays,
      'progress': progress,
      'isVacation': isVacation,
      'startStr':
          '${start.month.toString().padLeft(2, '0')}/${start.day.toString().padLeft(2, '0')}',
      'endStr':
          '${end.month.toString().padLeft(2, '0')}/${end.day.toString().padLeft(2, '0')}',
    };
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

    final data = _getCountdownData(_allEvents!, now);

    if (data['error'] == true) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [Color(0xFF64748B), Color(0xFF475569)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF475569).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white70, size: 24),
              const SizedBox(width: 12),
              Text(
                data['message'] ?? '無法顯示寒暑假時間',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bool isVacation = data['isVacation'] ?? false;
    final List<Color> gradientColors = isVacation
        ? const [Color(0xFFEA580C), Color(0xFFF59E0B)]
        : const [Color(0xFF0284C7), Color(0xFF10B981)];

    final double progress = data['progress'] ?? 0.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.3),
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
                  '${data['label']}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      '還有',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${data['remainingDays']}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '天',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
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
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '已度過 ${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${data['startStr']} - ${data['endStr']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    return Scaffold(
      appBar: const CustomAppBar(title: '總覽'),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Consumer2<AuthProvider, DataProvider>(
          builder: (context, auth, data, child) {
            final userName = auth.user?['user']?['name']?.toString() ?? '';

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
            borderRadius: BorderRadius.circular(10),
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
              borderRadius: BorderRadius.circular(10),
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
                  borderRadius: BorderRadius.circular(8),
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
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text('今日無課程！', style: TextStyle(color: Colors.grey)),
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
        Text(
          '今日課程',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
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
    required String state,
    String? year,
    String? semester,
    String? courseNo,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

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
                  borderRadius: BorderRadius.circular(8),
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
