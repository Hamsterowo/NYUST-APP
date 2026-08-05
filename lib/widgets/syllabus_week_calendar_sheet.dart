import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../utils/course_time_slot.dart';

/// 某一週某一個上課時段實際落在哪一天。
class SyllabusSession {
  final DateTime date;
  final CourseTimeSlot slot;

  const SyllabusSession({required this.date, required this.slot});

  DateTime get start => slot.startOn(date);
  DateTime get end => slot.endOn(date);
}

/// 加入行事曆前的確認面板。
///
/// 存在的理由是**讓使用者在按下去之前就知道會進來幾筆**：一週有多個上課時段時
/// 會一次產生多則事件，而行事曆是使用者自己的東西，不該在他不知情的狀況下多出
/// 三則。確認後才交給系統日曆（系統自己還會再問一次，那是它的匯入流程）。
///
/// 回傳 `true` 表示使用者確認要加入。
Future<bool?> showSyllabusWeekCalendarSheet(
  BuildContext context, {
  required String courseName,
  required String weekLabel,
  required List<SyllabusSession> sessions,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      final colorScheme = Theme.of(context).colorScheme;
      final dateFormat = DateFormat.yMMMMEEEEd(
        Localizations.localeOf(context).toString(),
      );

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.syllabusAddTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '$courseName・$weekLabel',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              // 每一筆都列出來，不摺疊也不只顯示第一筆。
              ...sessions.map(
                (session) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.schedule_outlined,
                    color: colorScheme.primary,
                  ),
                  title: Text(dateFormat.format(session.date)),
                  subtitle: Text(
                    '${session.slot.timeText}　${session.slot.room}',
                  ),
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                l10n.syllabusAddCount(sessions.length),
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(l10n.confirm),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}
