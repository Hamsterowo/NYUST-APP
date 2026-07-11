import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/shimmer_box.dart';
import 'web_view_screen.dart';

class GraduationContent extends ConsumerWidget {
  const GraduationContent({super.key});

  String _formatCreditsText(BuildContext context, String? rawText) {
    if (rawText == null || rawText.isEmpty) return '-';
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    if (isEnglish) {
      return rawText.replaceAll('學分', ' Credits').trim();
    }
    return rawText;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dataProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (data.graduationFailed && data.graduationData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).gradLoadFailed,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).checkNetworkRetry,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () => data.fetchGraduation(force: true),
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      );
    }

    if (data.isLoadingGraduation && data.graduationData == null) {
      return _buildGraduationSkeleton(context, colorScheme);
    }

    final info = data.graduationData?['graduation_info'];
    if (info == null) {
      return Center(child: Text(AppLocalizations.of(context).gradNoData));
    }

    final breakdown =
        info['credits_breakdown'] ??
        {
          "pe": "0",
          "civilization": "0",
          "literature": "0",
          "general": "0",
          "dept_required": "0",
          "elective": "0",
          "total": "0",
        };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(context, info),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context).gradDetailTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildCreditTable(context, breakdown),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).gradTotalNotice,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (info['missing_courses_text'] != null &&
              info['missing_courses_text'].isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).gradMissingRequiredCourses,
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

  Widget _buildGraduationSkeleton(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shadowColor: Colors.transparent,
            color: colorScheme.surfaceContainer,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const ShimmerBox(width: 100, height: 20),
                  const SizedBox(height: 8),
                  const ShimmerBox(width: 80, height: 48),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      ShimmerBox(width: 80, height: 50),
                      ShimmerBox(width: 80, height: 50),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const ShimmerBox(width: 120, height: 28),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: List.generate(
                8,
                (index) => const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: ShimmerBox(width: double.infinity, height: 20),
                ),
              ),
            ),
          ),
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
            Text(
              AppLocalizations.of(context).gradTotalEarnedCredits,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text(
              _formatCreditsText(context, info["total_credits"]?.toString()),
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
                _buildBadge(
                  context,
                  AppLocalizations.of(context).gradEnglishThreshold,
                  info['english_threshold'],
                ),
                _buildBadge(
                  context,
                  AppLocalizations.of(context).gradInternshipThreshold,
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
    final isPassed =
        (value.contains("通過") ||
            value.contains("已修過") ||
            value.contains("免修")) &&
        !value.contains("未") &&
        !value.contains("不");
    final colorScheme = Theme.of(context).colorScheme;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    String displayValue = value;
    if (isEnglish) {
      final trimmed = value.trim();
      if (trimmed.contains('未') || trimmed.contains('不')) {
        if (trimmed.contains('通過')) {
          displayValue = 'Not Passed';
        } else if (trimmed.contains('修過')) {
          displayValue = 'Not Completed';
        } else {
          displayValue = 'Not Passed';
        }
      } else if (trimmed.contains('已通過') || trimmed.contains('通過')) {
        displayValue = 'Passed';
      } else if (trimmed.contains('已修過') || trimmed.contains('修過')) {
        displayValue = 'Completed';
      } else if (trimmed.contains('免修')) {
        displayValue = 'Waived';
      }
    }

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
            displayValue,
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
      'pe': AppLocalizations.of(context).gradLabelPE,
      'civilization': AppLocalizations.of(context).gradLabelCivilization,
      'literature': AppLocalizations.of(context).gradLabelLiterature,
      'general': AppLocalizations.of(context).gradLabelGeneral,
      'dept_required': AppLocalizations.of(context).gradLabelDeptRequired,
      'elective': AppLocalizations.of(context).gradLabelElective,
      'total': AppLocalizations.of(context).gradLabelTotal,
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
            children:
                [
                      AppLocalizations.of(context).gradCategory,
                      AppLocalizations.of(context).gradRequired,
                      AppLocalizations.of(context).gradEarned,
                      AppLocalizations.of(context).gradMissing,
                    ]
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
                    _formatCreditsText(
                      context,
                      breakdown['required_goal'][key],
                    ),
                    style: TextStyle(
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _formatCreditsText(context, breakdown['earned'][key]),
                    style: TextStyle(
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _formatCreditsText(context, breakdown['missing'][key]),
                    style: TextStyle(
                      color:
                          (() {
                            final val =
                                breakdown['missing'][key]?.toString() ?? '';
                            return val == "0" ||
                                val.startsWith('0') ||
                                val == "Pass" ||
                                val.isEmpty;
                          })()
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
            '${year > 0 ? AppLocalizations.of(context).gradYearFormat(year.toString()) : '??'} - ${item['code']} ${item['name']}';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
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

class GraduationScreen extends ConsumerWidget {
  const GraduationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dataProvider);
    return Scaffold(
      appBar: CustomAppBar(
        title: AppLocalizations.of(context).infoGradTitle,
        onRefresh: () => data.fetchGraduation(force: true),
        isLoading: data.isLoadingGraduation,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: AppLocalizations.of(context).courseOpenInBrowser,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppWebViewScreen(
                    url:
                        'https://webapp.yuntech.edu.tw/WebNewCAS/Graduation/Score/StudGradCour.aspx',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      // 預留底部系統導覽列（三鍵/手勢）高度，避免內容被系統列遮擋。
      body: const SafeArea(top: false, child: GraduationContent()),
    );
  }
}
