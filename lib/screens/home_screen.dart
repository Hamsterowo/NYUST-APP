import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
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
        title: const Text('安裝 NYUST+ APP'),
        content: Text(
          isIos
              ? '將 NYUST+ 捷徑安裝到您的裝置：\n\n'
                    '1️⃣  點擊底部「分享」圖示 ⧧\n'
                    '2️⃣  往下滞動，選擇「加入主畫面」\n'
                    '3️⃣  點擊「加入」'
              : '將 NYUST+ 安裝到您的裝置，不用開啟瀏覽器即可直接操作。',
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
            child: const Text('不再提示'),
          ),
          if (isIos)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('好的'),
            )
          else ...[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('確定'),
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
              child: const Text('安裝'),
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
    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.7);

    return Expanded(
      child: InkWell(
        onTap: () {
          context.read<NavigationProvider>().setIndex(index);
        },
        borderRadius: BorderRadius.circular(24),
        splashColor: colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: Colors.transparent,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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

  @override
  Widget build(BuildContext context) {
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
                label: '總覽',
                currentIndex: currentIndex,
                colorScheme: colorScheme,
              ),
              _buildNavItem(
                context: context,
                index: 1,
                activeIcon: Icons.table_chart,
                inactiveIcon: Icons.table_chart_outlined,
                label: '課表',
                currentIndex: currentIndex,
                colorScheme: colorScheme,
              ),
              _buildNavItem(
                context: context,
                index: 2,
                activeIcon: Icons.info,
                inactiveIcon: Icons.info_outline,
                label: '資訊',
                currentIndex: currentIndex,
                colorScheme: colorScheme,
              ),
              _buildNavItem(
                context: context,
                index: 3,
                activeIcon: Icons.calendar_month,
                inactiveIcon: Icons.calendar_month_outlined,
                label: '行事曆',
                currentIndex: currentIndex,
                colorScheme: colorScheme,
              ),
              _buildNavItem(
                context: context,
                index: 4,
                activeIcon: Icons.settings,
                inactiveIcon: Icons.settings_outlined,
                label: '設定',
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
