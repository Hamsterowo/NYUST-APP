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
import '../services/update_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowInstallDialog();
      // 進到主畫面後檢查 Play 是否有新版（非 Android/非 Play 來源會靜默略過）。
      UpdateService.checkForUpdate(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 回到前景時，補檢查是否有「已下載但未安裝」的更新（處理使用者下載中/
    // 下載完成後關閉 app 的情況）。
    if (state == AppLifecycleState.resumed && mounted) {
      UpdateService.resumeCheck(context);
    }
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

  static const Color _navActiveColor = Color(0xFF14B8A6);

  /// 底部導覽列的單一分頁（頂線滑動風格：圖示＋文字，選中變 teal，不放大）。
  Widget _buildNavItem({
    required int index,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
    required int currentIndex,
    required ColorScheme colorScheme,
  }) {
    final isSelected = index == currentIndex;
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
              Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: isSelected ? _navActiveColor : inactiveColor,
                size: 24,
              ),
              const SizedBox(height: 4),
              // 字重即時切換，不做動畫：AnimatedDefaultTextStyle 會對 fontWeight
              // 做離散跳階插值，粗體中文較寬會造成切換時文字抖動／位移。
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'JFOpenHuninn',
                  fontSize: 10,
                  height: 1.0,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? _navActiveColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 各分頁畫面以「淡入交叉」切換：全部保持掛載（保留捲動位置等狀態），
  /// 只有選中的那頁不透明並可互動。opacity 0 的頁面不會被繪製（Flutter 於
  /// alpha==0 時略過繪製子節點），因此效能與原本的 IndexedStack 相當。
  Widget _buildBody(BuildContext context, int currentIndex) {
    final noAnim = MediaQuery.of(context).disableAnimations;
    return Stack(
      children: [
        for (var i = 0; i < _screens.length; i++)
          ExcludeSemantics(
            excluding: i != currentIndex,
            child: IgnorePointer(
              ignoring: i != currentIndex,
              child: AnimatedOpacity(
                opacity: i == currentIndex ? 1.0 : 0.0,
                duration: noAnim
                    ? Duration.zero
                    : const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                child: _screens[i],
              ),
            ),
          ),
      ],
    );
  }

  /// 頂線滑動風格的底部導覽列（窄螢幕用）。
  Widget _buildTopLineBar({
    required int currentIndex,
    required List<_NavItemData> navItems,
    required List<String> labels,
    required ColorScheme colorScheme,
  }) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final n = navItems.length;
          final itemWidth = constraints.maxWidth / n;
          const lineFraction = 0.36;
          final lineWidth = itemWidth * lineFraction;
          final lineLeft =
              currentIndex * itemWidth + (itemWidth - lineWidth) / 2;
          return Stack(
            children: [
              // 滑到選中分頁上方的 teal 細線。
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                top: 0,
                left: lineLeft,
                width: lineWidth,
                height: 3,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: _navActiveColor,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(3),
                    ),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < n; i++)
                    _buildNavItem(
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
    );
  }

  /// 寬螢幕（平板/桌機視窗）用的側邊導覽列。
  Widget _buildRail({
    required int currentIndex,
    required List<_NavItemData> navItems,
    required List<String> labels,
    required ColorScheme colorScheme,
  }) {
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: (i) =>
          ref.read(navIndexProvider.notifier).state = i,
      labelType: NavigationRailLabelType.all,
      backgroundColor: colorScheme.surface,
      indicatorColor: _navActiveColor.withValues(alpha: 0.16),
      selectedIconTheme: const IconThemeData(color: _navActiveColor),
      selectedLabelTextStyle: const TextStyle(
        color: _navActiveColor,
        fontFamily: 'JFOpenHuninn',
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontFamily: 'JFOpenHuninn',
        fontSize: 12,
      ),
      destinations: [
        for (var i = 0; i < navItems.length; i++)
          NavigationRailDestination(
            icon: Icon(navItems[i].inactive),
            selectedIcon: Icon(navItems[i].active),
            label: Text(labels[i]),
          ),
      ],
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
    // 尚未收到伺服器時間前預設無誤差。
    final isClockSkewed = ref.watch(isClockSkewedProvider).value ?? false;

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

    final body = _buildBody(context, currentIndex);

    return LayoutBuilder(
      builder: (context, constraints) {
        // 寬螢幕（平板/桌機視窗）改用左側 NavigationRail；窄螢幕用底部頂線列。
        final isWide = constraints.maxWidth >= 720;

        if (isWide) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  _buildRail(
                    currentIndex: currentIndex,
                    navItems: navItems,
                    labels: labels,
                    colorScheme: colorScheme,
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(
                    child: Column(
                      children: [
                        _OfflineBanner(
                          visible: !isOnline,
                          colorScheme: colorScheme,
                        ),
                        _ClockSkewBanner(
                          visible: isClockSkewed,
                          colorScheme: colorScheme,
                        ),
                        Expanded(child: body),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: body,
          bottomNavigationBar: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _OfflineBanner(visible: !isOnline, colorScheme: colorScheme),
                _ClockSkewBanner(
                  visible: isClockSkewed,
                  colorScheme: colorScheme,
                ),
                _buildTopLineBar(
                  currentIndex: currentIndex,
                  navItems: navItems,
                  labels: labels,
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavItemData {
  final IconData active;
  final IconData inactive;
  const _NavItemData(this.active, this.inactive);
}

/// 浮動導覽列上方的狀態提示條（離線、時間誤差等共用）。
/// 不可見時佔零高度（以動畫收合）。
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.visible,
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
    required this.border,
  });

  final bool visible;
  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;
  final Color border;

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
                color: background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border, width: 1.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: foreground),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontFamily: 'JFOpenHuninn',
                        fontSize: 12,
                        color: foreground,
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

/// 離線提示條。
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.visible, required this.colorScheme});

  final bool visible;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return _StatusBanner(
      visible: visible,
      icon: Icons.cloud_off_rounded,
      text: AppLocalizations.of(context).offlineBanner,
      background: colorScheme.surfaceContainerHighest.withValues(alpha: 0.92),
      foreground: colorScheme.onSurfaceVariant,
      border: colorScheme.outlineVariant.withValues(alpha: 0.2),
    );
  }
}

/// 裝置時間誤差過大提示條（警示色，與離線提示區隔）。
class _ClockSkewBanner extends StatelessWidget {
  const _ClockSkewBanner({required this.visible, required this.colorScheme});

  final bool visible;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return _StatusBanner(
      visible: visible,
      icon: Icons.access_time_rounded,
      text: AppLocalizations.of(context).clockSkewBanner,
      background: colorScheme.errorContainer.withValues(alpha: 0.92),
      foreground: colorScheme.onErrorContainer,
      border: colorScheme.error.withValues(alpha: 0.2),
    );
  }
}
