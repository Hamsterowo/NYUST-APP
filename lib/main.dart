import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:workmanager/workmanager.dart';
import 'l10n/app_localizations.dart';
import 'router/app_router.dart';
import 'screens/desktop_screen.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';
import 'services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
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

    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      useMaterial3: true,
      fontFamily: 'JFOpenHuninn',
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    if (isDesktopWeb) {
      return MaterialApp(
        title: '雲科工具箱',
        localizationsDelegates: localizationsDelegates,
        supportedLocales: supportedLocales,
        theme: theme,
        home: const DesktopScreen(),
      );
    }

    return MaterialApp.router(
      title: '雲科工具箱',
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      theme: theme,
      routerConfig: appRouter,
    );
  }
}
