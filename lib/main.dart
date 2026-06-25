import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:workmanager/workmanager.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'providers/navigation_provider.dart';
import 'screens/home_screen.dart';
import 'screens/grades_screen.dart';
import 'screens/graduation_screen.dart';
import 'screens/desktop_screen.dart';
import 'widgets/splash_wrapper.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';

final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    // 初始化本地通知服務
    final notificationService = NotificationService();
    NotificationService.navigatorKey = globalNavigatorKey;
    await notificationService.init();

    // 初始化背景排程 Workmanager
    await Workmanager().initialize(
      callbackDispatcher,
    );
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, DataProvider>(
          create: (ctx) => DataProvider(
            Provider.of<AuthProvider>(ctx, listen: false).api,
            Provider.of<AuthProvider>(ctx, listen: false),
          ),
          update: (ctx, auth, prev) => prev!,
        ),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: const MyApp(),
    ),
  );
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

    const supportedLocales = [
      Locale('zh'),
      Locale('en'),
    ];

    if (isDesktopWeb) {
      return MaterialApp(
        title: '雲科工具箱',
        localizationsDelegates: localizationsDelegates,
        supportedLocales: supportedLocales,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
          fontFamily: 'JFOpenHuninn',
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const DesktopScreen(),
      );
    }

    return MaterialApp(
      title: '雲科工具箱',
      navigatorKey: globalNavigatorKey,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        fontFamily: 'JFOpenHuninn',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashWrapper(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/grades': (context) => GradesScreen(),
        '/graduation': (context) => GraduationContent(),
      },
    );
  }
}
