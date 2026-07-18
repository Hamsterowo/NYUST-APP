import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/providers.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class DesktopScreen extends ConsumerWidget {
  const DesktopScreen({super.key});

  void _continueToApp(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authProvider);

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
        builder: (_) => auth.isLoggedIn ? const HomeScreen() : LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  AppLocalizations.of(context).desktopNoticeTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context).desktopNoticeBody,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    height: 1.6,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                FilledButton.icon(
                  onPressed: () => _continueToApp(context, ref),
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(AppLocalizations.of(context).desktopContinue),
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
