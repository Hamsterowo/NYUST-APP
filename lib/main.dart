import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'providers/navigation_provider.dart';
import 'screens/home_screen.dart';
import 'screens/grades_screen.dart';
import 'screens/graduation_screen.dart';
import 'screens/desktop_screen.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, DataProvider>(
          create: (ctx) => DataProvider(
            ctx.read<AuthProvider>().api,
            ctx.read<AuthProvider>(),
          ),
          update: (ctx, auth, prev) => prev ?? DataProvider(auth.api, auth),
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
    final auth = context.watch<AuthProvider>();

    final isDesktopWeb =
        kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux);

    if (isDesktopWeb) {
      return MaterialApp(
        title: 'NYUST+',
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        fontFamily: 'JFOpenHuninn',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: !auth.isInitialized
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : auth.isLoggedIn
          ? const HomeScreen()
          : const LoginScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/grades': (context) => GradesScreen(),
        '/graduation': (context) => GraduationContent(),
      },
    );
  }
}
