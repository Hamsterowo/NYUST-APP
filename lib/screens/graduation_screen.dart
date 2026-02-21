import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../models/schedule_event.dart';
import '../providers/navigation_provider.dart';
import '../utils/top_snack_bar.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/skeleton_loading.dart';

class GraduationContent extends StatelessWidget {
  const GraduationContent({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    if (data.isLoadingGraduation) {
      return const GraduationSkeletonView();
    }

    if (data.graduationFailed && data.graduationData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '無法載入畢業學分',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text('請確認網路連線後重試', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () => data.fetchGraduation(),
              child: const Text('重試'),
            ),
          ],
        ),
      );
    }

    if (data.graduationData == null) {
      return const Center(child: Text('尚無畢業學分資料'));
    }

    final info = data.graduationData!['graduation_info'];
    final breakdown = info['credits_breakdown'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(context, info),
          const SizedBox(height: 24),
          Text(
            '學分統計詳細',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildCreditTable(context, breakdown),
          if (info['missing_courses_text'] != null &&
              info['missing_courses_text'].isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              '未修通過必修課',
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
                child: Text(
                  info['missing_courses_text'],
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
              ),
            ),
          ],
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
            Text('總實得學分', style: Theme.of(context).textTheme.labelLarge),
            Text(
              '${info["total_credits"]}',
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
                _buildBadge(context, '英文門檻', info['english_threshold']),
                _buildBadge(
                  context,
                  '實習門檻',
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
            value,
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
      'pe': '體育',
      'civilization': '文明',
      'literature': '文學',
      'general': '通識',
      'dept_required': '必修',
      'elective': '選修',
      'total': '總計',
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
            children: ['類別', '應修', '實得', '尚缺']
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
                    breakdown['required_goal'][key] ?? '-',
                    style: TextStyle(
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    breakdown['earned'][key] ?? '-',
                    style: TextStyle(
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    breakdown['missing'][key] ?? '-',
                    style: TextStyle(
                      color:
                          (breakdown['missing'][key] == "0" ||
                              breakdown['missing'][key] == "Pass" ||
                              breakdown['missing'][key] == null)
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
}

// ScheduleScreen 也改用 DataProvider
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final List<String> _periods = [
    'W',
    'X',
    'A',
    'B',
    'C',
    'D',
    'Y',
    'Z',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: const CustomAppBar(title: '課表'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                '登入使用所有功能',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () {
                  context.read<NavigationProvider>().setIndex(3);
                  showTopSnackBar(context, '請在此登入以查看課表');
                },
                child: const Text('前往登入'),
              ),
            ],
          ),
        ),
      );
    }

    final data = context.watch<DataProvider>();

    return Scaffold(
      appBar: CustomAppBar(
        title: '課表',
        onRefresh: data.isLoadingSchedule ? null : () => data.fetchSchedule(),
      ),
      body: _buildBody(data),
    );
  }

  Widget _buildBody(DataProvider data) {
    if (data.isLoadingSchedule && data.scheduleData.isEmpty) {
      return const ScheduleSkeletonGrid();
    }

    if (data.scheduleFailed && data.scheduleData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '無法載入課表',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text('請確認網路連線後重試', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () => data.fetchSchedule(),
              child: const Text('重試'),
            ),
          ],
        ),
      );
    }

    if (data.scheduleData.isEmpty) {
      return const Center(child: Text('目前沒有任何課表資料'));
    }

    return _buildScheduleGrid(data.scheduleData);
  }

  Widget _buildScheduleGrid(List<ScheduleEvent> courses) {
    final weekDays = ['一', '二', '三', '四', '五', '六', '日'];
    const cellWidth = 80.0;
    const cellHeight = 100.0;
    const timeColumnWidth = 40.0;
    const headerHeight = 40.0;

    return Column(
      children: [
        Container(
          height: headerHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: timeColumnWidth,
                child: const Center(
                  child: Text(
                    '節',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: Row(
                    children: weekDays
                        .map(
                          (day) => SizedBox(
                            width: cellWidth,
                            child: Center(
                              child: Text(
                                '星期$day',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: timeColumnWidth,
                  child: Column(
                    children: _periods
                        .map(
                          (period) => Container(
                            height: cellHeight,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).dividerColor.withValues(alpha: 0.5),
                                ),
                                right: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                period,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      children: _periods.map((period) {
                        return Row(
                          children: List.generate(7, (dayIndex) {
                            final weekdayStr = (dayIndex + 1).toString();
                            final event = courses.firstWhere(
                              (c) =>
                                  c.weekday == weekdayStr &&
                                  c.times.contains(period),
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

                            return Container(
                              width: cellWidth,
                              height: cellHeight,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).dividerColor.withValues(alpha: 0.5),
                                  ),
                                  right: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).dividerColor.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                              child: event.name.isNotEmpty
                                  ? _buildCourseCard(event)
                                  : null,
                            );
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(ScheduleEvent event) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(event.name),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('教室: ${event.room ?? "未定"}'),
                  Text('教師: ${event.teacher}'),
                  const Divider(),
                  Text('時段: ${event.timeRoomStr}'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('關閉'),
              ),
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                event.name,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (event.room != null && event.room!.isNotEmpty)
              Text(
                event.room!,
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}
