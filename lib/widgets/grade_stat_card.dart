import 'package:flutter/material.dart';

/// 成績頁的數據統計小卡片（GradesScreen 與 SemesterGradesDetailScreen 共用）。
///
/// 自帶 [Expanded]，需直接放在 Row 內使用。
class GradeStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ColorScheme colorScheme;

  const GradeStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
