import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/grade_notification_service.dart';
import '../utils/top_snack_bar.dart';

/// 就地開關「成績更新通知」的底部面板（供成績頁右上角鈴鐺使用），
/// 讓使用者不必離開成績頁、也不會產生返回鍵無法回上頁的問題。
Future<void> showGradeNotificationSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _GradeNotificationSheet(),
  );
}

class _GradeNotificationSheet extends StatefulWidget {
  const _GradeNotificationSheet();

  @override
  State<_GradeNotificationSheet> createState() =>
      _GradeNotificationSheetState();
}

class _GradeNotificationSheetState extends State<_GradeNotificationSheet> {
  bool? _enabled; // null = 載入中
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await GradeNotificationService.isEnabled();
    if (mounted) setState(() => _enabled = value);
  }

  Future<void> _toggle(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await GradeNotificationService.setEnabled(value);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _enabled = result == GradeNotificationResult.permissionDenied
          ? false
          : value;
    });
    if (result == GradeNotificationResult.permissionDenied) {
      showTopSnackBar(
        context,
        AppLocalizations.of(context).notificationPermissionDenied,
        type: SnackBarType.warning,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
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
                if (_enabled == null || _busy)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Switch.adaptive(value: _enabled!, onChanged: _toggle),
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
