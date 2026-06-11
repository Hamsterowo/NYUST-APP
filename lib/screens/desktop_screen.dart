import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class DesktopScreen extends StatelessWidget {
  const DesktopScreen({super.key});

  void _continueToApp(BuildContext context) {
    final auth = context.read<AuthProvider>();

    if (!auth.isInitialized) {

      void listener() {
        if (auth.isInitialized) {
          auth.removeListener(listener);
          _navigateByAuthState(context, auth);
        }
      }

      auth.addListener(listener);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    } else {
      _navigateByAuthState(context, auth);
    }
  }

  void _navigateByAuthState(BuildContext context, AuthProvider auth) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            auth.isLoggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.desktop_windows_outlined,
                  size: 120,
                  color: Colors.teal,
                ),
                const SizedBox(height: 32),
                Text(
                  'NYUST+ 是為行動裝置設計的工具',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  '您目前正在使用電腦版網頁\n\n'
                  '建議您使用行動裝置以獲得更好的使用體驗\n'
                  '或點擊下方按鈕繼續使用',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    height: 1.6,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                FilledButton.icon(
                  onPressed: () => _continueToApp(context),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('繼續前往'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 20,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
