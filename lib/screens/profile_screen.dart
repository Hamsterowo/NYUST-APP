import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/top_snack_bar.dart';
import 'login_form.dart';
import '../utils/pwa_interop.dart';
import 'yuntech_privacy_screen.dart';
import 'terms_of_service_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showInstallPrompt(BuildContext context) {
    if (kIsWeb) {
      final result = showPwaInstallPrompt();
      if (result != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('目前無法安裝：您可能已安裝，或瀏覽器不支援此功能'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showReportDialog(BuildContext context) {
    showTopSnackBar(context, '此功能尚未完成');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (!auth.isInitialized) {
      return const Scaffold(
        appBar: CustomAppBar(title: '設定'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.isLoggedIn) {
      return const Scaffold(
        appBar: CustomAppBar(title: '設定'),
        body: Center(child: LoginForm()),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: '設定'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        // User info card
                        Card(
                          elevation: 0,
                          color: colorScheme.surfaceContainerHighest,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Text(
                                  user?["user"]?["name"] ?? "Student",
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  user?["user"]?["department"] ?? "Unknown",
                                  style: textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // About / Legal card
                        Card(
                          elevation: 0,
                          color: colorScheme.surfaceContainerHighest,
                          child: Column(
                            children: [
                              ListTile(
                                leading: Icon(
                                  Icons.privacy_tip_outlined,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                title: const Text('YunTech 單一入口隱私權政策'),
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const YuntechPrivacyScreen(),
                                    ),
                                  );
                                },
                              ),
                              const Divider(height: 1, indent: 56),
                              ListTile(
                                leading: Icon(
                                  Icons.description_outlined,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                title: const Text('NYUST+ 使用者條款'),
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const TermsOfServiceScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Action buttons + Logout at bottom
                    Padding(
                      padding: const EdgeInsets.only(top: 32.0),
                      child: Column(
                        children: [
                          // Install App button (web only)
                          if (kIsWeb) ...[
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () => _showInstallPrompt(context),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.grey.shade200,
                                  foregroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.install_mobile_outlined,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text('安裝 APP'),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          // Report button
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => _showReportDialog(context),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.grey.shade200,
                                foregroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.bug_report_outlined, size: 20),
                                  SizedBox(width: 8),
                                  Text('回報問題'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Logout button
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => auth.logout(),
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.error,
                                foregroundColor: colorScheme.onError,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.logout, size: 20),
                                  SizedBox(width: 8),
                                  Text('登出'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
