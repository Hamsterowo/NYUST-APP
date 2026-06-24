import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/navigation_provider.dart';
import '../providers/data_provider.dart';
import 'overview_screen.dart';
import 'schedule_screen.dart';
import 'info_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';
import '../utils/pwa_interop.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Widget> _screens = [
    const OverviewScreen(),
    const ScheduleScreen(),
    const InfoScreen(),
    const CalendarScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowInstallDialog();
    });
  }

  void _maybeShowInstallDialog() {
    if (!kIsWeb) return;
    try {
      final isDismissed = isPwaInstallDismissed();
      if (isDismissed) return;
      final isIosDevice = isIos();
      final isAvailable = isPwaPromptAvailable();

      if (!isIosDevice && !isAvailable) return;
      _showInstallDialog(isIos: isIosDevice);
    } catch (_) {}
  }

  void _showInstallDialog({bool isIos = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).installTitle),
        content: Text(
          isIos
              ? AppLocalizations.of(context).installDescIos
              : AppLocalizations.of(context).installDescAndroid,
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (kIsWeb) {
                try {
                  setPwaInstallDismissed();
                } catch (_) {}
              }
              Navigator.of(ctx).pop();
            },
            child: Text(AppLocalizations.of(context).notPromoted),
          ),
          if (isIos)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppLocalizations.of(context).ok),
            )
          else ...[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppLocalizations.of(context).confirm),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                if (kIsWeb) {
                  try {
                    showPwaInstallPrompt();
                  } catch (_) {}
                }
              },
              child: Text(AppLocalizations.of(context).install),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
    required int currentIndex,
    required ColorScheme colorScheme,
  }) {
    final isSelected = index == currentIndex;
    final activeColor = const Color.fromARGB(255, 45, 177, 163);
    final inactiveColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final splashFillColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF0FDFA);

    return Expanded(
      child: InkWell(
        onTap: () {
          context.read<NavigationProvider>().setIndex(index);
        },
        borderRadius: BorderRadius.circular(24),
        splashColor: splashFillColor,
        hoverColor: splashFillColor,
        focusColor: splashFillColor,
        highlightColor: Colors.transparent,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: AnimatedScale(
                  scale: isSelected ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    isSelected ? activeIcon : inactiveIcon,
                    color: isSelected ? activeColor : inactiveColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontFamily: 'JFOpenHuninn',
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? activeColor : inactiveColor,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _lastLocale;

  @override
  Widget build(BuildContext context) {
    final newLocale = Localizations.localeOf(context).toString();
    if (_lastLocale != null && _lastLocale != newLocale) {
      if (kDebugMode) {
        print(
          'HomeScreen: Locale changed from $_lastLocale to $newLocale. Refreshing all data...',
        );
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<DataProvider>().forceFetchAll();
      });
    }
    _lastLocale = newLocale;

    final navigation = context.watch<NavigationProvider>();
    int currentIndex = navigation.currentIndex;

    if (currentIndex >= _screens.length) {
      currentIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<NavigationProvider>().setIndex(0);
      });
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: _screens),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          height: 66,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildNavItem(
                context: context,
                index: 0,
                activeIcon: Icons.dashboard,
                inactiveIcon: Icons.dashboard_outlined,
                label: AppLocalizations.of(context).navOverview,
                currentIndex: currentIndex,
                colorScheme: colorScheme,
              ),
              _buildNavItem(
                context: context,
                index: 1,
                activeIcon: Icons.table_chart,
                inactiveIcon: Icons.table_chart_outlined,
                label: AppLocalizations.of(context).navSchedule,
                currentIndex: currentIndex,
                colorScheme: colorScheme,
              ),
              _buildNavItem(
                context: context,
                index: 2,
                activeIcon: Icons.info,
                inactiveIcon: Icons.info_outline,
                label: AppLocalizations.of(context).navInfo,
                currentIndex: currentIndex,
                colorScheme: colorScheme,
              ),
              _buildNavItem(
                context: context,
                index: 3,
                activeIcon: Icons.calendar_month,
                inactiveIcon: Icons.calendar_month_outlined,
                label: AppLocalizations.of(context).navCalendar,
                currentIndex: currentIndex,
                colorScheme: colorScheme,
              ),
              _buildNavItem(
                context: context,
                index: 4,
                activeIcon: Icons.settings,
                inactiveIcon: Icons.settings_outlined,
                label: AppLocalizations.of(context).navSettings,
                currentIndex: currentIndex,
                colorScheme: colorScheme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
