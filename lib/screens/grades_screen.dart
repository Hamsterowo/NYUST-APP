import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../utils/top_snack_bar.dart';
import 'graduation_screen.dart'; // Import GraduationScreen

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  _GradesScreenState createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  int _selectedSegment = 0; // 0: Current, 1: All, 2: Graduation

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text('成績查詢')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: colorScheme.outline),
              SizedBox(height: 16),
              Text(
                '登入使用所有功能',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () {
                  context.read<NavigationProvider>().setIndex(
                    3,
                  ); // Switch to Profile tab
                  showTopSnackBar(context, '請在此登入以查看成績');
                },
                child: Text('前往登入'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedSegment == 2 ? '畢業學分' : '成績查詢'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                  setState(() {
                    _selectedSegment = newSelection.first;
                  });
                },
                showSelectedIcon: false,
                style: ButtonStyle(visualDensity: VisualDensity.comfortable),
              ),
            ),
          ),
        ),
      ),
      body: _selectedSegment == 2
          ? const GraduationContent()
          : _buildGradesView(context),
    );
  }

  Widget _buildGradesView(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<Map<String, dynamic>>(
      future: auth.api.getGrades(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final data = snapshot.data;

        if (data == null || data['success'] != true) {
          return Center(
            child: Text('Failed to load grades: ${data?['message']}'),
          );
        }

        List grades = data['grades'];

        // Filter for "Current Semester"
        if (_selectedSegment == 0 && grades.isNotEmpty) {
          grades = [grades.last];
        } else if (_selectedSegment == 0 && grades.isEmpty) {
          return Center(child: Text("尚無成績資料"));
        }

        // Reverse to show latest first for "All Semesters"
        if (_selectedSegment == 1) {
          grades = grades.reversed.toList();
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
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

              // 總學分 (Total Credits)
              totalCredits += credit;

              // 已獲得學分 (Earned Credits)
              bool isPass = false;
              if (score != null) {
                if (score >= 60) isPass = true;
              } else {
                if (scoreStr.contains('通過') ||
                    scoreStr.toLowerCase().contains('pass')) {
                  isPass = true;
                }
              }

              if (isPass) {
                earnedCredits += credit;
              }

              // 平均計算 (Average Calculation) - Exclude Pass/Fail
              // Only include numeric scores in the average
              if (score != null) {
                totalWeightedScore += score * credit;
                totalGradedCredits += credit;
              }
            }

            final calculatedAverage = totalGradedCredits > 0
                ? (totalWeightedScore / totalGradedCredits).toStringAsFixed(2)
                : "N/A";

            // Format for display: 17/17 (Remove decimal if integer)
            String formatCredit(double c) =>
                c.truncateToDouble() == c ? c.toInt().toString() : c.toString();
            final passRate =
                "${formatCredit(earnedCredits)}/${formatCredit(totalCredits)}";

            // Use API average if available and not empty/N/A, otherwise use calculated
            final apiAverage = semester["summary"]?["average_score"]
                ?.toString();
            final displayAverage =
                (apiAverage != null &&
                    apiAverage.isNotEmpty &&
                    apiAverage != "N/A")
                ? apiAverage
                : calculatedAverage;

            return Card(
              elevation: 0,
              color: colorScheme.surfaceContainerHighest,
              margin: EdgeInsets.only(bottom: 12),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                initiallyExpanded: false,
                shape: Border(), // Remove default borders
                collapsedShape: Border(),
                backgroundColor: Colors.transparent,
                collapsedBackgroundColor: Colors.transparent,
                textColor: colorScheme.onSurface,
                iconColor: colorScheme.primary,
                title: Text(
                  '${semester["academic_year"]}學年 第${semester["semester"]}學期',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '平均: $displayAverage  |  排名: ${(semester["summary"]?["rank"]?.toString().isEmpty ?? true) ? "-" : semester["summary"]["rank"]}  |  學分: $passRate',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                children: courses.map<Widget>((course) {
                  final score =
                      double.tryParse(course["score"]?.toString() ?? "0") ?? 0;
                  final isPass =
                      score >= 60; // Simple pass/fail check, might vary

                  // For "Pass" string scores
                  final isPassString = course["score"].toString().contains(
                    "通過",
                  );
                  final effectivePass = isPass || isPassString;

                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.outlineVariant.withOpacity(0.5),
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
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.secondaryContainer,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        course["type"] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              colorScheme.onSecondaryContainer,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
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
                          SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: effectivePass
                                      ? colorScheme.primaryContainer
                                      : colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${course["score"]}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: effectivePass
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
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
      },
    );
  }
}
