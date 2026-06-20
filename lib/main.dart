import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'providers/navigation_provider.dart';
import 'screens/home_screen.dart';
import 'screens/grades_screen.dart';
import 'screens/graduation_screen.dart';
import 'screens/desktop_screen.dart';
import 'widgets/splash_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        title: 'NYUST+',
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
      title: 'NYUST+',
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
