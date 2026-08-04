import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../services/calendar_reminder_service.dart';
import '../utils/calendar_reminder_planner.dart';
import '../utils/top_snack_bar.dart';
import '../widgets/custom_app_bar.dart';

/// 行事曆提醒的設定頁：訂閱哪些分類，以及要在事件前多久提醒。
///
/// 設定頁與行事曆頁的鈴鐺都導到這裡，兩邊看到的是同一份狀態
/// （[calendarReminderCategoriesProvider]、[calendarReminderRulesProvider]）。
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

  /// 一筆提醒在清單上的文字，例如「1 天前  08:00」。
  ///
  /// 時刻交給 [TimeOfDay.format]，12／24 小時制跟著系統設定走。
  String _ruleLabel(
    BuildContext context,
    AppLocalizations l10n,
    ReminderRule rule,
  ) {
    final days = rule.daysBefore == 0
        ? l10n.calendarReminderRuleDayOf
        : l10n.calendarReminderRuleDaysBefore(rule.daysBefore);
    final time = TimeOfDay(
      hour: rule.hour,
      minute: rule.minute,
    ).format(context);
    return '$days  $time';
  }

  Future<void> _addRule() async {
    final l10n = AppLocalizations.of(context);
    final rule = await showModalBottomSheet<ReminderRule>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _ReminderRuleSheet(),
    );
    if (rule == null || !mounted) return;

    final current = ref.read(calendarReminderRulesProvider);
    // 重複的提醒會算出同一個通知 id，排第二次只會覆蓋第一次 —— 與其讓它看起來
    // 像憑空消失，不如當場說清楚。
    if (current.contains(rule)) {
      showTopSnackBar(
        context,
        l10n.calendarReminderRuleDuplicate,
        type: SnackBarType.info,
      );
      return;
    }
    await _applyRules([...current, rule]);
  }

  Future<void> _removeRule(ReminderRule rule) async {
    final current = ref.read(calendarReminderRulesProvider);
    await _applyRules(current.where((r) => r != rule).toList());
  }

  Future<void> _applyRules(List<ReminderRule> rules) async {
    if (_busy) return;
    setState(() => _busy = true);

    final l10n = AppLocalizations.of(context);
    await ref
        .read(calendarReminderRulesProvider.notifier)
        .setRules(rules, l10n);

    if (!mounted) return;
    setState(() {
      _busy = false;
      _debugRefreshToken++;
    });
  }

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
    final rules = ref.watch(calendarReminderRulesProvider);

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
          const SizedBox(height: 24),

          Text(l10n.calendarReminderTimingTitle, style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                for (final rule in rules)
                  ListTile(
                    leading: Icon(
                      Icons.schedule_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    title: Text(_ruleLabel(context, l10n, rule)),
                    trailing: IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: l10n.calendarReminderRuleDelete,
                      // 最後一筆不給刪：分類全開著卻永遠不發通知的狀態看起來
                      // 像壞掉而不像設定。要完全靜音是把分類關掉。
                      onPressed: _busy || rules.length <= 1
                          ? null
                          : () => _removeRule(rule),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _busy ? null : _addRule,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(l10n.calendarReminderRuleAdd),
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

/// 新增一筆提醒的底部面板。回傳新的 [ReminderRule]，取消則回傳 null。
class _ReminderRuleSheet extends StatefulWidget {
  const _ReminderRuleSheet();

  @override
  State<_ReminderRuleSheet> createState() => _ReminderRuleSheetState();
}

class _ReminderRuleSheetState extends State<_ReminderRuleSheet> {
  /// 提前天數的可選範圍。從 0（事件當天）起跳 —— 選單裡根本沒有負數，
  /// 所以「事件之後的提醒」在介面上就不可能設得出來。
  static const _maxDaysBefore = 30;

  int _daysBefore = ReminderRule.defaultRule.daysBefore;
  TimeOfDay _time = TimeOfDay(
    hour: ReminderRule.defaultRule.hour,
    minute: ReminderRule.defaultRule.minute,
  );

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null && mounted) setState(() => _time = picked);
  }

  String _dayLabel(AppLocalizations l10n, int days) => days == 0
      ? l10n.calendarReminderRuleDayOf
      : l10n.calendarReminderRuleDaysBefore(days);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.calendarReminderRuleAdd,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Icon(
                  Icons.today_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(l10n.calendarReminderRuleDaysLabel)),
                DropdownButton<int>(
                  value: _daysBefore,
                  onChanged: (value) {
                    if (value != null) setState(() => _daysBefore = value);
                  },
                  items: [
                    for (var d = 0; d <= _maxDaysBefore; d++)
                      DropdownMenuItem(
                        value: d,
                        child: Text(_dayLabel(l10n, d)),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(l10n.calendarReminderRuleTimeLabel)),
                TextButton(
                  onPressed: _pickTime,
                  child: Text(_time.format(context)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                ReminderRule(
                  daysBefore: _daysBefore,
                  hour: _time.hour,
                  minute: _time.minute,
                ),
              ),
              child: Text(l10n.confirm),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
          ],
        ),
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

  /// 上一次讀取時的錯誤訊息；`null` = 沒出錯。
  String? _error;

  /// 目前這份清單是用哪個語系算的，用來偵測換語言。
  Locale? _loadedLocale;

  @override
  void didUpdateWidget(_DebugScheduleInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 首次載入放在這裡而不是 initState：[_load] 會讀 [AppLocalizations]，那是一次
    // inherited widget 查找，在 initState 完成前呼叫會直接丟例外 —— 每次進入這一頁
    // 都會，面板上就只剩一段紅字。didChangeDependencies 保證在 initState 之後、
    // 第一次 build 之前跑到，是這種查找最早的合法時機。
    //
    // 同一個判斷也涵蓋語言變更：換語言後事件名稱會換成另一份，重讀一次才不會停在
    // 舊語言的清單上。
    final locale = Localizations.localeOf(context);
    if (_loadedLocale != locale) _load();
    _loadedLocale = locale;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final planned = await CalendarReminderService.debugPlan(
        AppLocalizations.of(context),
      );
      final pending = await CalendarReminderService.debugPendingIds();
      if (!mounted) return;
      setState(() {
        _planned = planned;
        _pendingIds = pending;
        _error = null;
      });
    } catch (e) {
      // 沒有這個 catch 的話，任何一次失敗都會把 _loading 永遠留在 true，
      // 面板就變成一個轉不停的圈圈，而且看不出是壞了還是還在抓。
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 把面板上看到的東西原樣複製成純文字。
  ///
  /// 排程檢視是拿來回報問題的，而截圖沒辦法搜尋、沒辦法比對、長清單還會被裁掉。
  /// 所以複製的是**畫面上的內容**，不是另一份為複製而生的格式 —— 貼出來的東西
  /// 必須就是使用者看到的東西。
  Future<void> _copyReport() async {
    final l10n = AppLocalizations.of(context);
    final buffer = StringBuffer()
      ..writeln(
        l10n.devCalendarReminderCounts(_planned.length, _pendingIds.length),
      );

    if (_planned.isEmpty) {
      buffer.writeln(l10n.devCalendarReminderEmpty);
    } else {
      for (final reminder in _planned) {
        buffer
          ..writeln(
            '${_pendingIds.contains(reminder.id) ? '✓' : '✗'} '
            '${DateFormat('MM/dd HH:mm').format(reminder.triggerTime)}'
            '  ·  #${reminder.id}',
          )
          ..writeln('    ${reminder.eventNames.join(' / ')}');
      }
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    showTopSnackBar(
      context,
      l10n.devCalendarReminderCopied,
      type: SnackBarType.info,
    );
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
              icon: const Icon(Icons.copy_all_outlined, size: 20),
              tooltip: l10n.devCalendarReminderCopy,
              onPressed: _loading ? null : _copyReport,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 讀取中只在最上面顯示一條細線，下面照樣留著上一次的結果。
                // 整塊換成轉圈圈的話，慢一點就會看起來像卡住。
                if (_loading) ...[
                  const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: 12),
                ],
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
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
