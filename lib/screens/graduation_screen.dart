import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/graduation_report.dart';
import '../providers/data_provider.dart';
import '../providers/providers.dart';
import '../services/scrape_result.dart';
import '../utils/refresh_body_state.dart';
import '../utils/top_snack_bar.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/skeleton_loading.dart';
import 'web_view_screen.dart';

/// 連線類錯誤 → 具名「無法連線至畢業審核系統」；其他 → 通用提示。
/// 錯誤頁與失敗提示共用同一句，兩種呈現方式才不會像是兩種不同的問題。
String graduationFailureMessage(BuildContext context, RefreshOutcome? reason) {
  final l10n = AppLocalizations.of(context);
  return reason == RefreshOutcome.networkError
      ? l10n.serviceUnavailable(l10n.serviceGraduation)
      : l10n.checkNetworkRetry;
}

class GraduationContent extends ConsumerWidget {
  /// 使用者主動觸發的更新進行中——由持有重新整理按鈕的 [GraduationScreen] 傳入，
  /// 為真時蓋上骨架。
  final bool manualRefreshing;

  /// 錯誤頁的重試改走上層的主動更新（才有骨架與失敗提示）；
  /// 沒有上層時（`/graduation` 深連結）退回直接重抓。
  final Future<void> Function()? onManualRefresh;

  const GraduationContent({
    super.key,
    this.manualRefreshing = false,
    this.onManualRefresh,
  });

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

    // 畢業學分是單一份報表，沒有「零筆」這回事：拿到了就是有內容。
    final state = resolveRefreshBody(
      isEmpty: data.graduationData == null ? null : false,
      failed: data.graduationFailed,
      manualRefreshing: manualRefreshing,
    );
    switch (state) {
      case RefreshBodyState.skeleton:
        return _buildGraduationSkeleton(context, colorScheme);
      case RefreshBodyState.error:
        return _buildGraduationError(context, data, colorScheme);
      case RefreshBodyState.empty:
      case RefreshBodyState.list:
        return _buildReport(context, data.graduationData!, colorScheme);
    }
  }

  Widget _buildGraduationError(
    BuildContext context,
    DataProvider data,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).gradLoadFailed,
            style: TextStyle(fontSize: 18, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            graduationFailureMessage(context, data.graduationFailReason),
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: () =>
                onManualRefresh?.call() ?? data.fetchGraduation(force: true),
            child: Text(AppLocalizations.of(context).retry),
          ),
        ],
      ),
    );
  }

  Widget _buildReport(
    BuildContext context,
    GraduationReport info,
    ColorScheme colorScheme,
  ) {
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
          _buildCreditTable(context, info),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).gradTotalNotice,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (info.missingCoursesText.isNotEmpty) ...[
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
                child: _buildMissingCoursesList(context, info.missingCourses),
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
                  const SkeletonBox(width: 100, height: 20),
                  const SizedBox(height: 8),
                  const SkeletonBox(width: 80, height: 48),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      SkeletonBox(width: 80, height: 50),
                      SkeletonBox(width: 80, height: 50),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SkeletonBox(width: 120, height: 28),
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
                  child: SkeletonBox(width: double.infinity, height: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, GraduationReport info) {
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
              _formatCreditsText(context, info.totalCredits),
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
                  info.englishThreshold,
                ),
                _buildBadge(
                  context,
                  AppLocalizations.of(context).gradInternshipThreshold,
                  info.internshipThreshold.isNotEmpty
                      ? info.internshipThreshold
                      : "N/A",
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

  Widget _buildCreditTable(BuildContext context, GraduationReport info) {
    // 每一列 = 標籤 + 從各分組取出該類別的具名選取器（順序即畫面列順序）。
    final rows =
        <({String label, String Function(CreditGroup) value, bool isTotal})>[
          (
            label: AppLocalizations.of(context).gradLabelPE,
            value: (g) => g.pe,
            isTotal: false,
          ),
          (
            label: AppLocalizations.of(context).gradLabelCivilization,
            value: (g) => g.civilization,
            isTotal: false,
          ),
          (
            label: AppLocalizations.of(context).gradLabelLiterature,
            value: (g) => g.literature,
            isTotal: false,
          ),
          (
            label: AppLocalizations.of(context).gradLabelGeneral,
            value: (g) => g.general,
            isTotal: false,
          ),
          (
            label: AppLocalizations.of(context).gradLabelDeptRequired,
            value: (g) => g.deptRequired,
            isTotal: false,
          ),
          (
            label: AppLocalizations.of(context).gradLabelElective,
            value: (g) => g.elective,
            isTotal: false,
          ),
          (
            label: AppLocalizations.of(context).gradLabelTotal,
            value: (g) => g.total,
            isTotal: true,
          ),
        ];
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
          ...rows.map((row) {
            final isTotal = row.isTotal;
            final missingValue = row.value(info.missing);
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
                    row.label,
                    style: TextStyle(
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _formatCreditsText(context, row.value(info.requiredGoal)),
                    style: TextStyle(
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _formatCreditsText(context, row.value(info.earned)),
                    style: TextStyle(
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _formatCreditsText(context, missingValue),
                    style: TextStyle(
                      color:
                          (missingValue == "0" ||
                              missingValue.startsWith('0') ||
                              missingValue == "Pass" ||
                              missingValue.isEmpty)
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

  Widget _buildMissingCoursesList(
    BuildContext context,
    List<MissingCourse> items,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        final year = item.year;
        final label =
            '${year > 0 ? AppLocalizations.of(context).gradYearFormat(year.toString()) : '??'} - ${item.code} ${item.name}';
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

class GraduationScreen extends ConsumerStatefulWidget {
  const GraduationScreen({super.key});

  @override
  ConsumerState<GraduationScreen> createState() => _GraduationScreenState();
}

class _GraduationScreenState extends ConsumerState<GraduationScreen> {
  /// 使用者主動觸發的更新進行中。與資料層的 `isLoadingGraduation` 並存而不混用：
  /// 背景預抓也會設那個旗標，只有這個為真時才蓋上骨架。
  bool _manualRefreshing = false;

  /// 主動更新：蓋上骨架，失敗時跳提示。失敗不動資料，骨架一收畫面自己回到原形態。
  Future<void> _refresh(DataProvider data) async {
    setState(() => _manualRefreshing = true);
    try {
      final outcome = await data.fetchGraduation(force: true);
      if (!mounted) return;
      if (outcome != null && !outcome.isSuccess) {
        showTopSnackBar(
          context,
          graduationFailureMessage(context, outcome),
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _manualRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(dataProvider);
    return Scaffold(
      appBar: CustomAppBar(
        title: AppLocalizations.of(context).infoGradTitle,
        onRefresh: () => _refresh(data),
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
      body: SafeArea(
        top: false,
        child: GraduationContent(
          manualRefreshing: _manualRefreshing,
          onManualRefresh: () => _refresh(data),
        ),
      ),
    );
  }
}
