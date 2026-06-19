import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../providers/navigation_provider.dart';
import '../utils/top_snack_bar.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/shimmer_box.dart';
import 'graduation_screen.dart';
import 'course_detail_screen.dart';

class GradesScreen extends StatefulWidget {
  final bool embed;
  const GradesScreen({super.key, this.embed = false});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  int _selectedSegment = 0;

  final Map<String, bool> _expandedStates = {};

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!auth.isInitialized) {
      if (widget.embed) {
        return const Center(child: CircularProgressIndicator());
      }
      return const Scaffold(
        appBar: CustomAppBar(title: '成績查詢'),
        body: Center(child: CircularProgressIndicator()),
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
              '登入使用所有功能',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () {
                context.read<NavigationProvider>().setIndex(4);
                showTopSnackBar(context, '請在此登入以查看成績');
              },
              child: const Text('前往登入'),
            ),
          ],
        ),
      );

      if (widget.embed) {
        return notLoggedInBody;
      }

      return Scaffold(
        appBar: const CustomAppBar(title: '成績查詢'),
        body: notLoggedInBody,
      );
    }

    final bodyContent = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              segments: const <ButtonSegment<int>>[
                ButtonSegment<int>(
                  value: 0,
                  label: Text('學期'),
                  icon: Icon(Icons.calendar_view_day),
                ),
                ButtonSegment<int>(
                  value: 1,
                  label: Text('歷年'),
                  icon: Icon(Icons.history),
                ),
              ],
              selected: <int>{_selectedSegment},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() => _selectedSegment = newSelection.first);
              },
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.comfortable,
              ),
            ),
          ),
        ),
        Expanded(child: _buildGradesContent(data, colorScheme)),
      ],
    );

    if (widget.embed) {
      return bodyContent;
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: '成績查詢',
        onRefresh: data.isLoadingGrades ? null : () => data.fetchGrades(),
      ),
      body: bodyContent,
    );
  }

  Widget _buildGradesContent(DataProvider data, ColorScheme colorScheme) {
    if (data.gradesFailed && data.gradesData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '無法載入成績',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text('請確認網路連線後重試', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () => data.fetchGrades(),
              child: const Text('重試'),
            ),
          ],
        ),
      );
    }

    if (data.isLoadingGrades && data.gradesData == null) {
      return _buildGradesSkeleton(colorScheme);
    }

    if (data.gradesData == null) {
      return const Center(child: Text('尚無成績資料'));
    }

    return _buildGradesList(data.gradesData!, colorScheme);
  }

  Widget _buildGradesList(
    Map<String, dynamic> gradesData,
    ColorScheme colorScheme,
  ) {
    final List originalGrades = gradesData['grades'] ?? [];

    if (originalGrades.isEmpty) {
      return Center(
        child: Text(
          _selectedSegment == 0 ? '尚無成績資料' : '尚無歷年成績資料',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    // 計算當前真實世界的台灣學年與學期
    final now = DateTime.now();
    int currentYear = now.year - 1911;
    int currentSem = 1;
    if (now.month >= 2 && now.month <= 7) {
      currentYear -= 1;
      currentSem = 2;
    } else if (now.month == 1) {
      currentYear -= 1;
      currentSem = 1;
    }
    final currentSemesterIndex = currentYear * 2 + currentSem;

    // 解析資料庫中最新一學期的學年與學期
    final latestSemester = originalGrades.last;
    final int latestYear =
        int.tryParse(latestSemester['academic_year']?.toString() ?? '0') ?? 0;
    final int latestSem =
        int.tryParse(latestSemester['semester']?.toString() ?? '0') ?? 0;
    final latestSemesterIndex = latestYear * 2 + latestSem;

    // 計算學期差距，如果差距大於 1，代表最新成績學期已經是過去的歷史（使用者可能已畢業或長期休學）
    final diff = currentSemesterIndex - latestSemesterIndex;
    final isGraduatedOrInactive = diff > 1;

    List grades = [];

    if (_selectedSegment == 0) {
      if (isGraduatedOrInactive) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 48, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                '尚無當前學期的成績資料',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '（已畢業或本學期未在學）',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      } else {
        // 在學學生：學期成績分頁直接呈現「直觀成績儀表板」
        final semester = originalGrades.last;
        final courses = semester['courses'] as List;

        // 計算統計數據
        double totalWeightedScore = 0;
        double totalGradedCredits = 0;
        double totalCredits = 0;
        double earnedCredits = 0;

        for (var course in courses) {
          final credit =
              double.tryParse(course['credits']?.toString() ?? '0') ?? 0;
          final scoreStr = course['score']?.toString() ?? '';
          final score = double.tryParse(scoreStr);
          totalCredits += credit;
          bool isPass = false;
          if (score != null) {
            if (score >= 60) isPass = true;
          } else {
            if (scoreStr.contains('通過') ||
                scoreStr.toLowerCase().contains('pass')) {
              isPass = true;
            }
          }
          if (isPass) earnedCredits += credit;
          if (score != null) {
            totalWeightedScore += score * credit;
            totalGradedCredits += credit;
          }
        }

        final calculatedAverage = totalGradedCredits > 0
            ? (totalWeightedScore / totalGradedCredits).toStringAsFixed(2)
            : 'N/A';

        String formatCredit(double c) =>
            c.truncateToDouble() == c ? c.toInt().toString() : c.toString();
        final passRate =
            '${formatCredit(earnedCredits)}/${formatCredit(totalCredits)}';

        final apiAverage = semester['summary']?['average_score']?.toString();
        final displayAverage =
            (apiAverage != null && apiAverage.isNotEmpty && apiAverage != 'N/A')
            ? apiAverage
            : calculatedAverage;
        final displayRank =
            (semester["summary"]?["rank"]?.toString().isEmpty ?? true)
            ? "-"
            : semester["summary"]["rank"];

        return ListView(
          key: const ValueKey('semester_grades_dashboard'),
          padding: const EdgeInsets.all(16),
          children: [
            // 學期標題
            Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 4),
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
                    '${semester["academic_year"]}學年 第${semester["semester"]}學期',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // 數據儀表板橫列
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard(
                  label: '平均成績',
                  value: displayAverage,
                  icon: Icons.analytics_outlined,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  label: '班級排名',
                  value: displayRank,
                  icon: Icons.format_list_numbered_outlined,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  label: '實得學分',
                  value: passRate,
                  icon: Icons.menu_book_outlined,
                  colorScheme: colorScheme,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 課程列表標籤
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 4),
              child: Text(
                '本學期修課成績明細',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            // 課程卡片列表
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerHighest,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: courses.map<Widget>((course) {
                  final scoreRaw = course['score']?.toString() ?? '';
                  final isEmpty = scoreRaw.isEmpty;
                  final score = isEmpty ? null : double.tryParse(scoreRaw);
                  final isPass =
                      !isEmpty &&
                      (score != null
                          ? score >= 60
                          : scoreRaw.contains('通過') ||
                                scoreRaw.toLowerCase().contains('pass'));
                  final effectivePass = isPass;
                  final displayScore = isEmpty ? '無資料' : scoreRaw;

                  return InkWell(
                    onTap: () {
                      final courseNo = course['courseNo']?.toString();
                      if (courseNo != null &&
                          courseNo.isNotEmpty &&
                          semester['academic_year'] != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourseDetailScreen(
                              year: semester['academic_year'].toString(),
                              semester: semester['semester'].toString(),
                              courseNo: courseNo,
                              courseName: course['name'] ?? 'Unknown Course',
                            ),
                          ),
                        );
                      } else {
                        showTopSnackBar(
                          context,
                          '這門課沒有提供詳細課綱',
                          type: SnackBarType.warning,
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    course['name'] ?? 'Unknown Course',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.secondaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          course['type'] ?? '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme
                                                .onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${course["credits"]} 學分',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isEmpty
                                    ? colorScheme.surfaceContainerHighest
                                    : effectivePass
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                displayScore,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isEmpty
                                      ? colorScheme.onSurfaceVariant
                                      : effectivePass
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      }
    }

    // 歷年成績分頁：使用 ListView.builder 搭配原有的 Card + ExpansionTile
    grades = [];
    if (isGraduatedOrInactive) {
      grades = originalGrades.reversed.toList();
    } else {
      if (originalGrades.length > 1) {
        grades = originalGrades
            .sublist(0, originalGrades.length - 1)
            .reversed
            .toList();
      } else {
        return Center(
          child: Text(
            '尚無歷年成績資料',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        );
      }
    }

    return ListView.builder(
      key: ValueKey(_selectedSegment),
      padding: const EdgeInsets.all(16),
      itemCount: grades.length,
      itemBuilder: (context, index) {
        final semester = grades[index];
        final courses = semester['courses'] as List;
        final semesterKey =
            '${semester["academic_year"]}-${semester["semester"]}';

        if (!_expandedStates.containsKey(semesterKey)) {
          final isLastSemester = _selectedSegment == 0;
          _expandedStates[semesterKey] = isLastSemester;
        }

        double totalWeightedScore = 0;
        double totalGradedCredits = 0;
        double totalCredits = 0;
        double earnedCredits = 0;

        for (var course in courses) {
          final credit =
              double.tryParse(course['credits']?.toString() ?? '0') ?? 0;
          final scoreStr = course['score']?.toString() ?? '';
          final score = double.tryParse(scoreStr);
          totalCredits += credit;
          bool isPass = false;
          if (score != null) {
            if (score >= 60) isPass = true;
          } else {
            if (scoreStr.contains('通過') ||
                scoreStr.toLowerCase().contains('pass')) {
              isPass = true;
            }
          }
          if (isPass) earnedCredits += credit;
          if (score != null) {
            totalWeightedScore += score * credit;
            totalGradedCredits += credit;
          }
        }

        final calculatedAverage = totalGradedCredits > 0
            ? (totalWeightedScore / totalGradedCredits).toStringAsFixed(2)
            : 'N/A';

        String formatCredit(double c) =>
            c.truncateToDouble() == c ? c.toInt().toString() : c.toString();
        final passRate =
            '${formatCredit(earnedCredits)}/${formatCredit(totalCredits)}';

        final apiAverage = semester['summary']?['average_score']?.toString();
        final displayAverage =
            (apiAverage != null && apiAverage.isNotEmpty && apiAverage != 'N/A')
            ? apiAverage
            : calculatedAverage;

        return Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest,
          margin: const EdgeInsets.only(bottom: 12),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SemesterGradesDetailScreen(
                    semester: semester,
                  ),
                ),
              );
            },
            title: Text(
              '${semester["academic_year"]}學年 第${semester["semester"]}學期',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '平均: $displayAverage  |  排名: ${(semester["summary"]?["rank"]?.toString().isEmpty ?? true) ? "-" : semester["summary"]["rank"]}  |  學分: $passRate',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            trailing: Icon(Icons.chevron_right, color: colorScheme.primary),
          ),
        );
      },
    );
  }

  Widget _buildGradesSkeleton(ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 2,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    ShimmerBox(width: 120, height: 24),
                    ShimmerBox(width: 60, height: 24),
                  ],
                ),
              ),
              const Divider(height: 1),
              for (int i = 0; i < 3; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 16.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            ShimmerBox(
                              width: 150,
                              height: 20,
                              margin: EdgeInsets.only(bottom: 8),
                            ),
                            Row(
                              children: [
                                ShimmerBox(
                                  width: 40,
                                  height: 16,
                                  margin: EdgeInsets.only(right: 8),
                                ),
                                ShimmerBox(width: 60, height: 16),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      const ShimmerBox(width: 40, height: 32),
                    ],
                  ),
                ),
                if (i < 2) const Divider(height: 1),
              ],
            ],
          ),
        );
      },
    );
  }
}

// 數據統計小卡片（全域私有函數，供 GradesScreen 和 SemesterGradesDetailScreen 使用）
Widget _buildStatCard({
  required String label,
  required String value,
  required IconData icon,
  required ColorScheme colorScheme,
}) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

// 歷年學期成績詳細資訊頁面（與學期成績分頁排版完全一致）
class SemesterGradesDetailScreen extends StatelessWidget {
  final Map<String, dynamic> semester;
  const SemesterGradesDetailScreen({super.key, required this.semester});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final courses = semester['courses'] as List;

    // 計算統計數據
    double totalWeightedScore = 0;
    double totalGradedCredits = 0;
    double totalCredits = 0;
    double earnedCredits = 0;

    for (var course in courses) {
      final credit = double.tryParse(course['credits']?.toString() ?? '0') ?? 0;
      final scoreStr = course['score']?.toString() ?? '';
      final score = double.tryParse(scoreStr);
      totalCredits += credit;
      bool isPass = false;
      if (score != null) {
        if (score >= 60) isPass = true;
      } else {
        if (scoreStr.contains('通過') ||
            scoreStr.toLowerCase().contains('pass')) {
          isPass = true;
        }
      }
      if (isPass) earnedCredits += credit;
      if (score != null) {
        totalWeightedScore += score * credit;
        totalGradedCredits += credit;
      }
    }

    final calculatedAverage = totalGradedCredits > 0
        ? (totalWeightedScore / totalGradedCredits).toStringAsFixed(2)
        : 'N/A';

    String formatCredit(double c) =>
        c.truncateToDouble() == c ? c.toInt().toString() : c.toString();
    final passRate =
        '${formatCredit(earnedCredits)}/${formatCredit(totalCredits)}';

    final apiAverage = semester['summary']?['average_score']?.toString();
    final displayAverage =
        (apiAverage != null && apiAverage.isNotEmpty && apiAverage != 'N/A')
            ? apiAverage
            : calculatedAverage;
    final displayRank =
        (semester["summary"]?["rank"]?.toString().isEmpty ?? true)
            ? "-"
            : semester["summary"]["rank"];

    return Scaffold(
      appBar: CustomAppBar(
        title: '${semester["academic_year"]}學年 第${semester["semester"]}學期',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 數據儀表板橫列
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(
                label: '平均成績',
                value: displayAverage,
                icon: Icons.analytics_outlined,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                label: '班級排名',
                value: displayRank,
                icon: Icons.format_list_numbered_outlined,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                label: '實得學分',
                value: passRate,
                icon: Icons.menu_book_outlined,
                colorScheme: colorScheme,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 課程列表標籤
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Text(
              '修課成績明細',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // 課程卡片列表
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: courses.map<Widget>((course) {
                final scoreRaw = course['score']?.toString() ?? '';
                final isEmpty = scoreRaw.isEmpty;
                final score = isEmpty ? null : double.tryParse(scoreRaw);
                final isPass = !isEmpty &&
                    (score != null
                        ? score >= 60
                        : scoreRaw.contains('通過') ||
                            scoreRaw.toLowerCase().contains('pass'));
                final effectivePass = isPass;
                final displayScore = isEmpty ? '無資料' : scoreRaw;

                return InkWell(
                  onTap: () {
                    final courseNo = course['courseNo']?.toString();
                    if (courseNo != null &&
                        courseNo.isNotEmpty &&
                        semester['academic_year'] != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CourseDetailScreen(
                            year: semester['academic_year'].toString(),
                            semester: semester['semester'].toString(),
                            courseNo: courseNo,
                            courseName: course['name'] ?? 'Unknown Course',
                          ),
                        ),
                      );
                    } else {
                      showTopSnackBar(
                        context,
                        '這門課沒有提供詳細課綱',
                        type: SnackBarType.warning,
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course['name'] ?? 'Unknown Course',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.secondaryContainer,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        course['type'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onSecondaryContainer,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${course["credits"]} 學分',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isEmpty
                                  ? colorScheme.surfaceContainerHighest
                                  : effectivePass
                                      ? Colors.green.withValues(alpha: 0.15)
                                      : Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              displayScore,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isEmpty
                                    ? colorScheme.onSurfaceVariant
                                    : effectivePass
                                        ? Colors.green[700]
                                        : Colors.red[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
