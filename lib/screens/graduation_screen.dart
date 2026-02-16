import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class GraduationContent extends StatelessWidget {
  const GraduationContent({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<Map<String, dynamic>>(
      future: auth.api.getGraduation(),
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
            child: Text('Failed to load data: ${data?['message']}'),
          );
        }

        final info = data['graduation_info'];
        final breakdown = info['credits_breakdown'];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(context, info),
              SizedBox(height: 24),
              Text(
                '學分統計詳細',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              SizedBox(height: 16),
              _buildCreditTable(context, breakdown),
              if (info['missing_courses_text'] != null &&
                  info['missing_courses_text'].isNotEmpty) ...[
                SizedBox(height: 24),
                Text(
                  '未修通過必修課',
                  style: TextStyle(
                    color: colorScheme.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      info['missing_courses_text'],
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context, Map info) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shadowColor: Colors
          .transparent, // M3 style usually elevation via surface color + tone
      color: colorScheme.surfaceContainer, // M3 Container
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text('總實得學分', style: Theme.of(context).textTheme.labelLarge),
            Text(
              '${info["total_credits"]}',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBadge(context, '英文門檻', info['english_threshold']),
                _buildBadge(
                  context,
                  '實習門檻',
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
    final isPassed = value.contains("通過") || value == "已修過";
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            value,
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
    // breakdown keys: required_goal, earned, not_received, missing
    // each has: pe, civilization, literature, general, dept_required, elective, total

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
      'pe': '體育',
      'civilization': '文明',
      'literature': '文學',
      'general': '通識',
      'dept_required': '必修',
      'elective': '選修',
      'total': '總計',
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
            children: [
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  '類別',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  '應修',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  '實得',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  '尚缺',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          ...rows.map((key) {
            final isTotal = key == 'total';
            return TableRow(
              decoration: isTotal
                  ? BoxDecoration(
                      color: colorScheme.secondaryContainer.withOpacity(0.3),
                    )
                  : null,
              children: [
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    labels[key] ?? key,
                    style: TextStyle(
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    breakdown['required_goal'][key] ?? '-',
                    style: TextStyle(
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    breakdown['earned'][key] ?? '-',
                    style: TextStyle(
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    breakdown['missing'][key] ?? '-',
                    style: TextStyle(
                      color:
                          (breakdown['missing'][key] == "0" ||
                              breakdown['missing'][key] == "Pass" ||
                              breakdown['missing'][key] == null)
                          ? colorScheme.onSurface
                          : colorScheme.error,
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}
