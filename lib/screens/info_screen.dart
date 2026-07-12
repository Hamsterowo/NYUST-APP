import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'grades_screen.dart';
import 'graduation_screen.dart';
import 'map_screen.dart';
import 'yun_report_screen.dart';
import 'absent_screen.dart';
import '../widgets/custom_app_bar.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color themeColor,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.transparent,
        border: Border.all(color: colorScheme.outlineVariant, width: 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: themeColor.withValues(alpha: 0.1),
          highlightColor: themeColor.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 28, color: themeColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: AppLocalizations.of(context).infoTitle),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card 1: Grades
              _buildDashboardCard(
                context,
                title: AppLocalizations.of(context).infoGradesTitle,
                description: AppLocalizations.of(context).infoGradesDesc,
                icon: Icons.school_rounded,
                themeColor: const Color(0xFF0D9488),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GradesScreen(embed: false),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Card 2: Graduation Credits
              _buildDashboardCard(
                context,
                title: AppLocalizations.of(context).infoGradTitle,
                description: AppLocalizations.of(context).infoGradDesc,
                icon: Icons.workspace_premium_rounded,
                themeColor: const Color(0xFFD97706),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GraduationScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Card 3: Campus Map
              _buildDashboardCard(
                context,
                title: AppLocalizations.of(context).infoMapTitle,
                description: AppLocalizations.of(context).infoMapDesc,
                icon: Icons.map_rounded,
                themeColor: const Color(0xFF4F46E5),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MapScreen(embed: false),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Card 4: Enrollment Certificate (在學證明) — app-endpoint /api
              _buildDashboardCard(
                context,
                title: AppLocalizations.of(context).infoYunReportTitle,
                description: AppLocalizations.of(context).infoYunReportDesc,
                icon: Icons.verified_rounded,
                themeColor: const Color(0xFF0EA5E9),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const YunReportScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Card 5: Leave records (請假記錄) — WebASXASG scraper
              _buildDashboardCard(
                context,
                title: AppLocalizations.of(context).infoAbsentTitle,
                description: AppLocalizations.of(context).infoAbsentDesc,
                icon: Icons.event_busy_rounded,
                themeColor: const Color(0xFFDB2777),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AbsentScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
