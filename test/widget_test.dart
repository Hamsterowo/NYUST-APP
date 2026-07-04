// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yun_tool/main.dart';

void main() {
  testWidgets('App boot smoke test', (WidgetTester tester) async {
    // Stage 5：DI 改用 Riverpod，App 以 ProviderScope 包裹。
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Verify that the app builds and mounts elements without throwing errors.
    expect(find.byType(MyApp), findsOneWidget);
  });
}
