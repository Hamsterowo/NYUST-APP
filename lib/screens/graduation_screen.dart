import 'dart:math';
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
          const SizedBox(height: 6),
          Text(
            '* 合計欄位為通識 + 必修 + 選修',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
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
      'total': '合計',
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

  Widget _buildMissingCoursesList(BuildContext context, String raw) {
    final colorScheme = Theme.of(context).colorScheme;
    // 格式：系所課號 + 課程名稱 + [年級]，例如 COE3007工程倫理與產業導論[2]
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
            '${year > 0 ? '$year年級' : '??'} - ${item['code']} ${item['name']}';
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

// ScheduleScreen 也改用 DataProvider
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
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
      return const Scaffold(
        appBar: CustomAppBar(title: '課表'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                  context.read<NavigationProvider>().setIndex(4);
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
    // 只要是在載入中（包含重新整理），就一律顯示簡化的骨架框架
    if (data.isLoadingSchedule) {
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
    final allWeekDays = ['一', '二', '三', '四', '五', '六', '日'];
    const timeColumnWidth = 36.0; // 稍微縮減節次欄寬度
    const headerHeight = 36.0; // 稍微縮減標題高度
    const minCellWidth = 46.0; // 稍微縮減最小日欄寬度
    const minCellHeight = 28.0; // 稍微縮小最小格子高度，讓整體更緊湊

    int minDayIndex = 0;
    int maxDayIndex = 4;
    int minPeriodIndex = 1; // Default to 'A'
    int maxPeriodIndex = 9; // Default to 'H'

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
        minDayIndex = min(minDay, 0).clamp(0, 6); // 星期一開始
        maxDayIndex = max(maxDay, 4).clamp(minDayIndex, 6); // 最少顯示到星期五
        minPeriodIndex = min(minP, 1).clamp(0, _periods.length - 1); // 提早到 'A'
        maxPeriodIndex = max(
          maxP,
          8,
        ).clamp(minPeriodIndex, _periods.length - 1); // 最晚到 'G'
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
        // 計算動態高度：(總高度 - 標題高度 - Padding) / 節次數量
        final availableHeight = constraints.maxHeight - headerHeight - 24.0;
        final rawCellHeight = availableHeight / activePeriods.length;
        final needsVerticalScroll = rawCellHeight < minCellHeight;
        final cellHeight = needsVerticalScroll ? minCellHeight : rawCellHeight;

        // 扣掉外層 Padding(12*2) 與節次欄，判斷每欄是否過窄
        final availableForDays = constraints.maxWidth - 24.0 - timeColumnWidth;
        final needsScroll =
            availableForDays / activeDayIndices.length < minCellWidth;

        // 標題列日期欄
        // 不捲動：Expanded 均分；捲動：固定 minCellWidth
        Widget dayCell(String day) {
          final label = Center(
            child: Text(
              '星期$day',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
          return needsScroll
              ? SizedBox(width: minCellWidth, child: label)
              : Expanded(child: label);
        }

        // 取得該節次該天的課程，若無則回傳空的 ScheduleEvent
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

        // 建立單日的所有節次欄位 (Column) 支援合併連續相同節次
        Widget buildColumnForDay(int dayIndex) {
          List<Widget> cells = [];

          for (int i = 0; i < activePeriods.length; i++) {
            final period = activePeriods[i];
            final event = getEventFor(dayIndex, period);

            int span = 1;
            if (event.name.isNotEmpty) {
              // 往後尋找連續的相同課程
              while (i + span < activePeriods.length) {
                final nextPeriod = activePeriods[i + span];
                final nextEvent = getEventFor(dayIndex, nextPeriod);

                // 比對課程是否相同 (以名稱和課程代碼作為依據)
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

            final child = event.name.isNotEmpty
                ? _buildCourseCard(event)
                : null;

            final cellWidget = Container(
              height: cellHeight * span, // 動態設定高度為 單節高度 x 節數
              decoration: decoration,
              width: needsScroll ? minCellWidth : double.infinity,
              child: child,
            );

            cells.add(cellWidget);
            i += span - 1; // 跳過已經合併的節次
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
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // 標題列
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
                        child: const Center(
                          child: Text(
                            '節',
                            style: TextStyle(fontWeight: FontWeight.bold),
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
                // 格子區
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
                          // 節次欄（固定，不水平捲動）
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
                                          '第 $period 節：$time',
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
                                        child: Center(
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
                          // 課表格（依需求決定是否水平捲動）
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
                  fontSize: 15, // 放大字體 (原本 12)
                  color: colorScheme.onPrimaryContainer,
                  height: 1.15, // 稍微壓縮行距，避免字被切掉
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (event.room != null && event.room!.isNotEmpty)
              Text(
                event.room!,
                style: TextStyle(
                  fontSize: 12,
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
