// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nyust_plus/main.dart';
import 'package:nyust_plus/providers/auth_provider.dart';
import 'package:nyust_plus/providers/data_provider.dart';
import 'package:nyust_plus/providers/navigation_provider.dart';
import 'package:nyust_plus/providers/weather_provider.dart';

void main() {
  testWidgets('App boot smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame, wrapping with required providers.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => WeatherProvider()),
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

    // Verify that the app builds and mounts elements without throwing errors.
    expect(find.byType(MyApp), findsOneWidget);
  });
}
