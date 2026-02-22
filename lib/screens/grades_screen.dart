import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../providers/navigation_provider.dart';
import '../utils/top_snack_bar.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/skeleton_loading.dart';
import 'graduation_screen.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  int _selectedSegment = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: const CustomAppBar(title: '成績查詢'),
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
                  showTopSnackBar(context, '請在此登入以查看成績');
                },
                child: const Text('前往登入'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: _selectedSegment == 2 ? '畢業學分' : '成績查詢',
        onRefresh: data.isLoadingGrades
            ? null
            : () {
                if (_selectedSegment == 2) {
                  data.fetchGraduation();
                } else {
                  data.fetchGrades();
                }
              },
      ),
      body: Column(
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
                  ButtonSegment<int>(
                    value: 2,
                    label: Text('畢業'),
                    icon: Icon(Icons.school),
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
          Expanded(
            child: _selectedSegment == 2
                ? const GraduationContent()
                : _buildGradesContent(data, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildGradesContent(DataProvider data, ColorScheme colorScheme) {
    if (data.isLoadingGrades) {
      // 骨架框架
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          GradesSkeletonCard(),
          GradesSkeletonCard(),
          GradesSkeletonCard(),
        ],
      );
    }

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

    if (data.gradesData == null) {
      return const Center(child: Text('尚無成績資料'));
    }

    return _buildGradesList(data.gradesData!, colorScheme);
  }

  Widget _buildGradesList(
    Map<String, dynamic> gradesData,
    ColorScheme colorScheme,
  ) {
    List grades = gradesData['grades'] ?? [];

    if (_selectedSegment == 0 && grades.isNotEmpty) {
      grades = [grades.last];
    } else if (_selectedSegment == 0 && grades.isEmpty) {
      return const Center(child: Text('尚無成績資料'));
    }

    if (_selectedSegment == 1) {
      if (grades.length > 1) {
        grades = grades.sublist(0, grades.length - 1).reversed.toList();
      } else {
        return const Center(child: Text('尚無歷年成績資料'));
      }
    }

    return ListView.builder(
      key: ValueKey(_selectedSegment),
      padding: const EdgeInsets.all(16),
      itemCount: grades.length,
      itemBuilder: (context, index) {
        final semester = grades[index];
        final courses = semester['courses'] as List;

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
          child: ExpansionTile(
            initiallyExpanded: false,
            shape: const Border(),
            collapsedShape: const Border(),
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            textColor: colorScheme.onSurface,
            iconColor: colorScheme.primary,
            title: Text(
              '${semester["academic_year"]}學年 第${semester["semester"]}學期',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '平均: $displayAverage  |  排名: ${(semester["summary"]?["rank"]?.toString().isEmpty ?? true) ? "-" : semester["summary"]["rank"]}  |  學分: $passRate',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
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

              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                              ? colorScheme.primaryContainer
                              : colorScheme.errorContainer,
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
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
