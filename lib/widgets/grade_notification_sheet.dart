import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../services/grade_notification_service.dart';
import '../utils/top_snack_bar.dart';

/// 就地開關「成績更新通知」的底部面板（供成績頁右上角鈴鐺使用），
/// 讓使用者不必離開成績頁、也不會產生返回鍵無法回上頁的問題。
///
/// 狀態透過 [gradeNotificationEnabledProvider] 共享，與設定分頁即時同步。
Future<void> showGradeNotificationSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _GradeNotificationSheet(),
  );
}

class _GradeNotificationSheet extends ConsumerWidget {
  const _GradeNotificationSheet();

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool value) async {
    final result = await ref
        .read(gradeNotificationEnabledProvider.notifier)
        .setEnabled(value);
    if (result == GradeNotificationResult.permissionDenied && context.mounted) {
      showTopSnackBar(
        context,
        AppLocalizations.of(context).notificationPermissionDenied,
        type: SnackBarType.warning,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = ref.watch(gradeNotificationEnabledProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.settingsGradeNotification,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: enabled,
                  onChanged: (value) => _toggle(context, ref, value),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l.settingsGradeNotificationSub,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
