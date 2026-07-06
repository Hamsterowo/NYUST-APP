import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/providers.dart';
import 'overview_screen.dart';
import 'schedule_screen.dart';
import 'info_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';
import '../utils/pwa_interop.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
    final activeColor = const Color(0xFF14B8A6);
    final inactiveColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.7);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          ref.read(navIndexProvider.notifier).state = index;
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontFamily: 'JFOpenHuninn',
                  fontSize: 10,
                  height: 1.0,
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
        ref.read(dataProvider).forceFetchAll();
      });
    }
    _lastLocale = newLocale;

    int currentIndex = ref.watch(navIndexProvider);

    if (currentIndex >= _screens.length) {
      currentIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(navIndexProvider.notifier).state = 0;
      });
    }

    final colorScheme = Theme.of(context).colorScheme;
    // StreamProvider 尚未回報前預設為線上，避免啟動瞬間閃現離線橫幅。
    final isOnline = ref.watch(isOnlineProvider).value ?? true;

    const navItems = <_NavItemData>[
      _NavItemData(Icons.dashboard, Icons.dashboard_outlined),
      _NavItemData(Icons.table_chart, Icons.table_chart_outlined),
      _NavItemData(Icons.info, Icons.info_outline),
      _NavItemData(Icons.calendar_month, Icons.calendar_month_outlined),
      _NavItemData(Icons.settings, Icons.settings_outlined),
    ];
    final labels = [
      AppLocalizations.of(context).navOverview,
      AppLocalizations.of(context).navSchedule,
      AppLocalizations.of(context).navInfo,
      AppLocalizations.of(context).navCalendar,
      AppLocalizations.of(context).navSettings,
    ];

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: _screens),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OfflineBanner(visible: !isOnline, colorScheme: colorScheme),
            Container(
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / navItems.length;
              // The sliding "pill" background behind the selected tab.
              const pillHInset = 10.0;
              const pillVInset = 8.0;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    top: pillVInset,
                    bottom: pillVInset,
                    left: currentIndex * itemWidth + pillHInset,
                    width: itemWidth - pillHInset * 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < navItems.length; i++)
                        _buildNavItem(
                          context: context,
                          index: i,
                          activeIcon: navItems[i].active,
                          inactiveIcon: navItems[i].inactive,
                          label: labels[i],
                          currentIndex: currentIndex,
                          colorScheme: colorScheme,
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData active;
  final IconData inactive;
  const _NavItemData(this.active, this.inactive);
}

/// 浮動導覽列上方的離線提示條。線上時佔零高度（以動畫收合）。
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.visible, required this.colorScheme});

  final bool visible;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: visible
          ? Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.92,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      AppLocalizations.of(context).offlineBanner,
                      style: TextStyle(
                        fontFamily: 'JFOpenHuninn',
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
