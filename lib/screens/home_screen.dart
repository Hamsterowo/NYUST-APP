import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../providers/providers.dart';
import 'overview_screen.dart';
import 'schedule_screen.dart';
import 'info_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';
import '../router/app_router.dart';
import '../utils/english_notice_policy.dart';
import '../utils/pwa_interop.dart';
import '../widgets/notice_dialog.dart';
import '../services/calendar_reminder_service.dart';
import '../services/notification_navigator.dart';
import '../services/notification_payload.dart';
import '../services/update_service.dart';
import '../theme/app_colors.dart';

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
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationNavigator.pending.addListener(_consumeNotificationTap);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowInstallDialog();
      // 進到主畫面後檢查 Play 是否有新版（非 Android/非 Play 來源會靜默略過）。
      UpdateService.checkForUpdate(context);
      // 冷啟動也算一次「進前景」：跨年後第一次開 App 的次年補齊靠這一趟。
      _refreshCalendarReminders();
      // 冷啟動時目的地在 main() 就放好了，這裡是它唯一的取件時機。
      _consumeNotificationTap();
    });
  }

  /// 取走待處理的通知目的地並導航過去。
  ///
  /// 冷啟動與「App 已在執行時點通知」共用這一段：兩者都只是把目的地放進
  /// [NotificationNavigator]，差別僅在放進去的時間點。
  void _consumeNotificationTap() {
    if (!mounted) return;
    final payload = NotificationNavigator.take();
    if (payload == null) return;

    switch (payload.type) {
      case NotificationPayload.typeGrades:
        appRouter.push('/grades');
      case NotificationPayload.typeCalendar:
        final date = payload.date;
        if (date == null) return;
        // 先收掉疊在上面的詳情頁：分頁切過去了但被課程詳情蓋著，等於沒切。
        rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
        ref.read(navIndexProvider.notifier).state = navIndexCalendar;
        ref.read(calendarFocusDateProvider.notifier).state = date;
      // 不認得的類型（例如舊版排下、新版已移除的通知）就只開啟 App。
    }
  }

  /// 行事曆內容或設定變了才重排（沒變就完全不動系統排程）。
  ///
  /// 觸發時機：冷啟動、回到前景、換語言、以及設定頁自己的變更。前三者都在這裡，
  /// 因為 HomeScreen 已經是生命週期觀察者、也已經在盯語系。
  void _refreshCalendarReminders() {
    if (!CalendarReminderService.isSupported || !mounted) return;
    CalendarReminderService.refreshIfNeeded(AppLocalizations.of(context));
  }

  @override
  void dispose() {
    NotificationNavigator.pending.removeListener(_consumeNotificationTap);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 回到前景時，補檢查是否有「已下載但未安裝」的更新（處理使用者下載中/
    // 下載完成後關閉 app 的情況）。
    if (state == AppLifecycleState.resumed && mounted) {
      UpdateService.resumeCheck(context);
      // 使用者可能剛從系統設定回來（改了通知權限），或學校更新了行事曆。
      _refreshCalendarReminders();
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

  static const Color _navActiveColor = AppColors.brandTeal;

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
      // 裸 GestureDetector 沒有語意節點，螢幕閱讀器讀不出「已選取／可點擊」，
      // 這裡補上與 NavigationBar 相同層級的語意資訊。
      child: Semantics(
        selected: isSelected,
        button: true,
        label: label,
        // 子樹的 Text 會再產生一次相同文字的語意節點，排除以免重複朗讀。
        excludeSemantics: true,
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
                    fontFamily: 'SarasaGothic',
                    fontSize: 10,
                    height: 1.0,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? _navActiveColor : inactiveColor,
                  ),
                ),
              ],
            ),
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
                // 每頁各自成一個繪製圖層：交叉淡入時直接以快取圖層做透明度
                // 合成，不必每幀重繪螢幕內容，避免切換時掉幀拖累導覽列動畫。
                child: RepaintBoundary(child: _screens[i]),
              ),
            ),
          ),
      ],
    );
  }

  /// 頂線滑動風格的底部導覽列（窄螢幕用）。
  /// 高度固定 64，系統字級放太大會垂直溢位，故限制字級縮放上限。
  Widget _buildTopLineBar({
    required int currentIndex,
    required List<_NavItemData> navItems,
    required List<String> labels,
    required ColorScheme colorScheme,
  }) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Container(
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
                // 滑到選中分頁上方的 teal 細線。自成一個繪製圖層，移動時只
                // 重繪這條線，不牽動下方整排圖示／文字，避免動畫掉幀。
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  top: 0,
                  left: lineLeft,
                  width: lineWidth,
                  height: 3,
                  child: const RepaintBoundary(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _navActiveColor,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
                // 圖示列獨立成層：滑線移動時不會被連帶重繪。
                RepaintBoundary(
                  child: Row(
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
                ),
              ],
            );
          },
        ),
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
        fontFamily: 'SarasaGothic',
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontFamily: 'SarasaGothic',
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

  /// 目前資料是照哪個語系抓的；null = 語言設定還沒讀完。
  String? _appliedLocale;

  /// 換語言後重抓全部資料（成績、畢業審查等頁面是照語系從學校抓回來的），
  /// 並順帶判定要不要跳英文語系提示。
  ///
  /// 只在語言設定讀完之後才開始計較：開機時設定是非同步讀進來的，讀完前畫面上的
  /// 語系只是「跟隨系統」的暫定值，把那一次 settle 當成使用者換語言，等於每次開機
  /// 都多打一輪強制重抓（也是總覽頁三張卡片一起重畫的來源）。
  void _refetchOnLanguageChange() {
    if (!ref.watch(localeProvider.select((s) => s.isResolved))) return;

    final newLocale = Localizations.localeOf(context).toString();
    final previous = _appliedLocale;
    _appliedLocale = newLocale;

    // 英文提示沿用同一組前後比對，不另建第二套語系追蹤。previous 為 null 就是
    // 冷啟動的第一次判定，那條得先排隊等開場動畫（見 [_maybeShowColdStartNotice]）；
    // 切換這條不必等，使用者人在設定頁時開場早就結束了。
    if (previous == null) {
      _pendingColdStartLocale = newLocale;
    } else {
      _maybeShowEnglishNotice(
        previousLocale: previous,
        currentLocale: newLocale,
      );
    }

    if (previous == null || previous == newLocale) return;

    if (kDebugMode) {
      print(
        'HomeScreen: Locale changed from $previous to $newLocale. Refreshing all data...',
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dataProvider).forceFetchAll();
      // 排進系統的是固定字串，語言換了就得整批換掉。
      _refreshCalendarReminders();
    });
  }

  /// 已看過英文語系提示的旗標；切換與冷啟動兩條路徑共用同一份記錄。
  static const String _englishNoticeShownKey = 'english_notice_shown';

  /// 冷啟動當下的語系，等著開場動畫結束才判定；`null` = 沒有待處理的。
  ///
  /// 語言設定通常在開場動畫還在跑的時候就讀完了，而那一刻的判定不能丟掉：主畫面
  /// 之後不會再有第二次 `previous == null` 的機會，丟掉就等於冷啟動永遠不跳。
  String? _pendingColdStartLocale;

  /// 開場動畫結束後補判冷啟動那條路徑。
  ///
  /// 每次 build 都問一次，靠 `watch` 在訊號翻成 true 的那一刻回來。
  void _maybeShowColdStartNotice() {
    final locale = _pendingColdStartLocale;
    if (locale == null) return;
    if (!ref.watch(splashDoneProvider)) return;

    _pendingColdStartLocale = null;
    _maybeShowEnglishNotice(previousLocale: null, currentLocale: locale);
  }

  /// 判定並跳出英文語系提示。所有判斷都在 [EnglishNoticePolicy] 裡，這裡只負責
  /// 讀寫旗標與顯示彈窗。
  Future<void> _maybeShowEnglishNotice({
    required String? previousLocale,
    required String currentLocale,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final decision = EnglishNoticePolicy.decide(
      previousLocale: previousLocale,
      currentLocale: currentLocale,
      alreadyShown: prefs.getBool(_englishNoticeShownKey) ?? false,
    );
    if (decision.trigger == EnglishNoticeTrigger.none) return;

    if (decision.shouldPersist) {
      await prefs.setBool(_englishNoticeShownKey, true);
    }
    if (!mounted) return;
    _showEnglishNoticeDialog();
  }

  /// 一則單向的聲明，所以只有一顆「Got it」：這裡不放回報捷徑（跳出來的當下
  /// 使用者還沒遇到任何錯誤），也不放「切回中文」（對真心要用英文的人像在勸退）。
  ///
  /// 外觀沿用隱私權更新提示的同一支彈窗；差別只在這則可以點背景關掉。
  void _showEnglishNoticeDialog() {
    showNoticeDialog(
      context,
      title: AppLocalizations.of(context).englishNoticeTitle,
      message: AppLocalizations.of(context).englishNoticeBody,
      buttonLabel: AppLocalizations.of(context).englishNoticeGotIt,
      barrierLabel: 'EnglishNotice',
      dismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    _refetchOnLanguageChange();
    // 排在 PWA 安裝提示與 Play 更新提示之後：那兩個在 initState 的第一個
    // post-frame 就送出，這個要等開場動畫結束、再等旗標從儲存空間讀回來。
    _maybeShowColdStartNotice();

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
    // 與底部導覽列同步限制字級縮放，避免超大字級把橫幅撐爆版面。
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: visible
            ? Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
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
                          fontFamily: 'SarasaGothic',
                          fontSize: 12,
                          color: foreground,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox(width: double.infinity),
      ),
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
