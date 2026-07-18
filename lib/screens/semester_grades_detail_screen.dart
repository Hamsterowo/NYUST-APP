import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../utils/status_colors.dart';
import '../utils/top_snack_bar.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/grade_stat_card.dart';
import 'course_detail_screen.dart';

// 歷年學期成績詳細資訊頁面（與學期成績分頁排版完全一致）
class SemesterGradesDetailScreen extends StatelessWidget {
  final Map<String, dynamic> semester;
  const SemesterGradesDetailScreen({super.key, required this.semester});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final courses = semester['courses'] as List;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

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

    final displayAverage = calculatedAverage;
    final displayRank =
        (semester["summary"]?["rank"]?.toString().isEmpty ?? true)
        ? "-"
        : semester["summary"]["rank"];

    return Scaffold(
      appBar: CustomAppBar(
        title: AppLocalizations.of(context).gradesSemesterTitle(
          semester["academic_year"]?.toString() ?? '',
          semester["semester"]?.toString() ?? '',
        ),
      ),
      body: ListView(
        // 底部加上系統導覽列高度，避免最後一列被系統列遮擋。
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          // 數據儀表板橫列
          // 數據儀表板橫列 (一排四個)
          Row(
            children: [
              GradeStatCard(
                label: AppLocalizations.of(context).gradesAverage,
                value: displayAverage,
                icon: Icons.analytics_outlined,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 8),
              GradeStatCard(
                label: AppLocalizations.of(context).gradesGPA,
                value: (semester['summary']?['gpa']?.toString().isEmpty ?? true)
                    ? "-"
                    : semester['summary']['gpa'].toString(),
                icon: Icons.grade_outlined,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 8),
              GradeStatCard(
                label: AppLocalizations.of(context).gradesRank,
                value: displayRank,
                icon: Icons.format_list_numbered_outlined,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 8),
              GradeStatCard(
                label: AppLocalizations.of(context).gradesEarnedCredits,
                value: passRate,
                icon: Icons.menu_book_outlined,
                colorScheme: colorScheme,
              ),
            ],
          ),
          const SizedBox(height: 24),

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

                String displayScore = scoreRaw;
                if (isEmpty) {
                  displayScore = AppLocalizations.of(context).notSpecified;
                } else if (isEnglish) {
                  if (scoreRaw == '通過') displayScore = 'Pass';
                  if (scoreRaw == '不通過') displayScore = 'Fail';
                }

                final cName =
                    (isEnglish &&
                        course['name_en'] != null &&
                        course['name_en'].toString().trim().isNotEmpty)
                    ? course['name_en']
                    : (course['name'] ?? 'Unknown Course');

                final typeZh = course['type'] ?? '';
                String type = typeZh;
                if (isEnglish) {
                  if (typeZh == '必修') {
                    type = 'Required';
                  } else if (typeZh == '選修') {
                    type = 'Elective';
                  } else if (typeZh == '通識') {
                    type = 'General Education';
                  }
                }

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
                            courseName: cName,
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
                                  cName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (type.isNotEmpty) ...[
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
                                          type,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme
                                                .onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      ).courseCreditsFormat(
                                        course["credits"]?.toString() ?? '0',
                                      ),
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
                                  ? StatusColors.success.withValues(alpha: 0.15)
                                  : colorScheme.error.withValues(alpha: 0.15),
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
                                    ? StatusColors.success
                                    : colorScheme.error,
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
