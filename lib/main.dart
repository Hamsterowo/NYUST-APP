import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'providers/navigation_provider.dart';
import 'screens/home_screen.dart';
import 'screens/grades_screen.dart';
import 'screens/graduation_screen.dart';

void main() {
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
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NYUST+',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        fontFamily: 'JFOpenHuninn',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/home',
      routes: {
        // '/login': (context) => LoginScreen(), // Removed, now embedded
        '/home': (context) => HomeScreen(),
        '/grades': (context) => GradesScreen(),
        '/graduation': (context) =>
            GraduationContent(), // Changed to Content widget
      },
    );
  }
}
