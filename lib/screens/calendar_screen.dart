import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../utils/top_snack_bar.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final colorScheme = Theme.of(context).colorScheme;

    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text('行事曆')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: colorScheme.outline),
              SizedBox(height: 16),
              Text(
                '登入使用所有功能',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () {
                  context.read<NavigationProvider>().setIndex(
                    3,
                  ); // Switch to Profile
                  showTopSnackBar(context, '請在此登入以查看行事曆');
                },
                child: Text('前往登入'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('行事曆')),
      body: Center(child: Text('行事曆功能尚未開放', style: TextStyle(fontSize: 20))),
    );
  }
}
