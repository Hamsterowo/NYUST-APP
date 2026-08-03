import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../services/calendar_reminder_service.dart';
import '../utils/calendar_reminder_planner.dart';
import '../utils/top_snack_bar.dart';
import '../widgets/custom_app_bar.dart';

/// 行事曆提醒的設定頁：訂閱哪些分類，以及（之後）什麼時候提醒。
///
/// 設定頁與行事曆頁的鈴鐺都導到這裡，兩邊看到的是同一份狀態
/// （[calendarReminderCategoriesProvider]）。
class CalendarReminderScreen extends ConsumerStatefulWidget {
  const CalendarReminderScreen({super.key});

  @override
  ConsumerState<CalendarReminderScreen> createState() =>
      _CalendarReminderScreenState();
}

class _CalendarReminderScreenState
    extends ConsumerState<CalendarReminderScreen> {
  /// 重排期間擋住其他開關：重排會取消全部再重新排入，中途插入第二次會讓兩趟
  /// 的取消與排入交錯。
  bool _busy = false;

  /// 每次重排後遞增，讓 debug 檢視區塊重讀（release build 未使用）。
  int _debugRefreshToken = 0;

  Future<void> _toggle(ReminderCategory category, bool enabled) async {
    if (_busy) return;
    setState(() => _busy = true);

    final l10n = AppLocalizations.of(context);
    final result = await ref
        .read(calendarReminderCategoriesProvider.notifier)
        .setEnabled(category, enabled, l10n);

    if (!mounted) return;
    setState(() {
      _busy = false;
      _debugRefreshToken++;
    });

    if (result == CalendarReminderResult.permissionDenied) {
      showTopSnackBar(
        context,
        l10n.notificationPermissionDenied,
        type: SnackBarType.warning,
      );
    }
  }

  String _label(AppLocalizations l10n, ReminderCategory category) =>
      switch (category) {
        ReminderCategory.courseSelection =>
          l10n.calendarReminderCategoryCourseSelection,
        ReminderCategory.exam => l10n.calendarReminderCategoryExam,
        ReminderCategory.registration =>
          l10n.calendarReminderCategoryRegistration,
        ReminderCategory.semester => l10n.calendarReminderCategorySemester,
      };

  String _sublabel(AppLocalizations l10n, ReminderCategory category) =>
      switch (category) {
        ReminderCategory.courseSelection =>
          l10n.calendarReminderCategoryCourseSelectionSub,
        ReminderCategory.exam => l10n.calendarReminderCategoryExamSub,
        ReminderCategory.registration =>
          l10n.calendarReminderCategoryRegistrationSub,
        ReminderCategory.semester => l10n.calendarReminderCategorySemesterSub,
      };

  IconData _icon(ReminderCategory category) => switch (category) {
    ReminderCategory.courseSelection => Icons.playlist_add_check_rounded,
    ReminderCategory.exam => Icons.edit_note_rounded,
    ReminderCategory.registration => Icons.receipt_long_rounded,
    ReminderCategory.semester => Icons.event_available_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final enabled = ref.watch(calendarReminderCategoriesProvider);

    return Scaffold(
      appBar: CustomAppBar(title: l10n.calendarReminderTitle),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.calendarReminderCategoriesTitle,
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                for (final category in ReminderCategory.values)
                  SwitchListTile.adaptive(
                    value: enabled.contains(category),
                    onChanged: _busy
                        ? null
                        : (value) => _toggle(category, value),
                    title: Text(_label(l10n, category)),
                    subtitle: Text(_sublabel(l10n, category)),
                    secondary: Icon(
                      _icon(category),
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.calendarReminderCategoriesHint,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          Text(l10n.calendarReminderTimingTitle, style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest,
            child: ListTile(
              leading: Icon(
                Icons.schedule_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              title: Text(l10n.calendarReminderTimingFixed),
            ),
          ),

          if (kDebugMode) ...[
            const SizedBox(height: 32),
            _DebugScheduleInspector(refreshToken: _debugRefreshToken),
          ],
        ],
      ),
    );
  }
}

/// 除錯用的排程檢視（只在 debug build 出現）。
///
/// 存在的理由：行事曆提醒排下去之後，要等到事件前一天早上八點才看得到任何
/// 東西，中間沒有可觀察的狀態 —— 沒有這個區塊，「排程有沒有正確排入」與
/// 「重開機後還在不在」都無法在實機上驗證。
class _DebugScheduleInspector extends StatefulWidget {
  const _DebugScheduleInspector({required this.refreshToken});

  /// 分類開關變動時遞增，用來觸發重讀。
  final int refreshToken;

  @override
  State<_DebugScheduleInspector> createState() =>
      _DebugScheduleInspectorState();
}

class _DebugScheduleInspectorState extends State<_DebugScheduleInspector> {
  List<PlannedReminder> _planned = const [];
  List<int> _pendingIds = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_DebugScheduleInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final planned = await CalendarReminderService.debugPlan();
    final pending = await CalendarReminderService.debugPendingIds();
    if (!mounted) return;
    setState(() {
      _planned = planned;
      _pendingIds = pending;
      _loading = false;
    });
  }

  Future<void> _scheduleTest(Duration delay) async {
    final l10n = AppLocalizations.of(context);
    await CalendarReminderService.debugScheduleTest(l10n, delay);
    if (!mounted) return;
    showTopSnackBar(
      context,
      l10n.devCalendarReminderTestScheduled,
      type: SnackBarType.info,
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.science_outlined, size: 18, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.devCalendarReminderSection,
                style: textTheme.titleSmall,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _loading ? null : _load,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.devCalendarReminderCounts(
                          _planned.length,
                          _pendingIds.length,
                        ),
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      if (_planned.isEmpty)
                        Text(
                          l10n.devCalendarReminderEmpty,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      else
                        for (final reminder in _planned)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_pendingIds.contains(reminder.id) ? '✓' : '✗'} '
                                  '${DateFormat('MM/dd HH:mm').format(reminder.triggerTime)}'
                                  '  ·  #${reminder.id}',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: Text(
                                    reminder.eventNames.join(' / '),
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.devCalendarReminderPendingNote,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _scheduleTest(const Duration(seconds: 15)),
          icon: const Icon(Icons.play_arrow, size: 18),
          label: Text(l10n.devCalendarReminderTestNow),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _scheduleTest(const Duration(minutes: 3)),
          icon: const Icon(Icons.restart_alt, size: 18),
          label: Text(l10n.devCalendarReminderTestReboot),
        ),
      ],
    );
  }
}
