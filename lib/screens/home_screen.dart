import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import 'overview_screen.dart';
import 'grades_screen.dart';
import 'schedule_screen.dart';
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
    GradesScreen(),
    ScheduleScreen(),
    CalendarScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Show PWA install dialog after the first frame renders
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
      // Show on iOS always (manual install), or on other platforms when prompt is available
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

  @override
  Widget build(BuildContext context) {
    final navigation = context.watch<NavigationProvider>();
    final currentIndex = navigation.currentIndex;

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          context.read<NavigationProvider>().setIndex(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: '總覽',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: '成績',
          ),
          NavigationDestination(
            icon: Icon(Icons.table_chart_outlined),
            selectedIcon: Icon(Icons.table_chart),
            label: '課表',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '行事曆',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            selectedIcon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }
}
