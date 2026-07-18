import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:workmanager/workmanager.dart';
import 'l10n/app_localizations.dart';
import 'providers/providers.dart';
import 'router/app_router.dart';
import 'screens/desktop_screen.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';
import 'services/firebase_service.dart';
import 'services/server_time_service.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 監聽 App 生命週期，於背景／恢復時作廢陳舊的時間錨點，避免恢復後誤判時間誤差。
  ServerTimeService.instance.startLifecycleWatch();

  // 初始化 Firebase（僅在 USE_FIREBASE=true 且平台已設定時，否則為 no-op）。
  await firebaseService.init();

  if (!kIsWeb) {
    // 初始化本地通知服務
    final notificationService = NotificationService();
    await notificationService.init();

    // 初始化背景排程 Workmanager
    await Workmanager().initialize(callbackDispatcher);
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // App 內語言覆寫（null = 跟隨系統）。
    final locale = ref.watch(localeProvider);

    final isDesktopWeb =
        kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux);

    final localizationsDelegates = [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];

    const supportedLocales = [Locale('zh'), Locale('en')];

    // seed 用品牌 teal（同底部導覽列），避免 Material teal / Tailwind teal
    // 兩種色相並存。
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.brandTeal),
      useMaterial3: true,
      fontFamily: 'SarasaGothic',
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    if (isDesktopWeb) {
      return MaterialApp(
        title: '雲科工具箱',
        // 與 go_router 共用同一把根 navigator key（同一時間只會有一個
        // MaterialApp 存在），讓 showTopSnackBar 一律能從根 navigator 取 Overlay。
        navigatorKey: rootNavigatorKey,
        locale: locale,
        localizationsDelegates: localizationsDelegates,
        supportedLocales: supportedLocales,
        theme: theme,
        home: const DesktopScreen(),
      );
    }

    return MaterialApp.router(
      title: '雲科工具箱',
      locale: locale,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      theme: theme,
      routerConfig: appRouter,
    );
  }
}
