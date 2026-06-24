import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/top_snack_bar.dart';
import 'login_form.dart';
import '../utils/pwa_interop.dart';
import '../utils/settings_utils.dart';
import 'terms_of_service_screen.dart';
import 'web_view_screen.dart';

import 'package:package_info_plus/package_info_plus.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _versionStr = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _versionStr = info.version;
      });
    } catch (_) {}
  }

  void _showInstallPrompt(BuildContext context) {
    if (kIsWeb) {
      final result = showPwaInstallPrompt();
      if (result != true) {
        showTopSnackBar(
          context,
          AppLocalizations.of(context).installError,
          type: SnackBarType.warning,
        );
      }
    }
  }

  void _showReportDialog(BuildContext context) {
    showTopSnackBar(
      context,
      AppLocalizations.of(context).featureNotFinished,
      type: SnackBarType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (!auth.isInitialized) {
      return Scaffold(
        appBar: CustomAppBar(title: AppLocalizations.of(context).settingsTitle),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: CustomAppBar(title: AppLocalizations.of(context).settingsTitle),
        body: const Center(child: LoginForm()),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(title: AppLocalizations.of(context).settingsTitle),
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
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            padding: const EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: colorScheme.primaryContainer,
                                  child: Icon(
                                    Icons.person,
                                    size: 40,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        user?["user"]?["name"] ??
                                            user?["user"]?["姓名"] ??
                                            "Student",
                                        style: textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user?["user"]?["系(所)別"] ??
                                            user?["user"]?["department"] ??
                                            "Unknown",
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: Colors.white.withValues(alpha: 0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildInfoRow(
                                        Icons.badge_outlined,
                                        user?["user"]?["學號"] ?? "ID Unknown",
                                      ),
                                      const SizedBox(height: 8),
                                      _buildInfoRow(
                                        Icons.school_outlined,
                                        user?["user"]?["班級"] ?? "No Class Info",
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppLocalizations.of(context).profileDisclaimer,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

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
                                title: Text(
                                  AppLocalizations.of(context).privacyPolicy,
                                ),
                                trailing: Icon(
                                  Icons.open_in_new,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                onTap: () {
                                  final isEnglish =
                                      Localizations.localeOf(
                                        context,
                                      ).languageCode ==
                                      'en';
                                  final url = isEnglish
                                      ? 'https://webapp.yuntech.edu.tw/yuntechsso/Policy/PrivacyPolicy?lang=en'
                                      : 'https://webapp.yuntech.edu.tw/yuntechsso/Policy/PrivacyPolicy?lang=zh-TW';
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AppWebViewScreen(
                                        url: url,
                                        injectCookies: false,
                                      ),
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
                                title: Text(
                                  AppLocalizations.of(context).termsOfService,
                                ),
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: colorScheme.onSurfaceVariant,
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
                              const Divider(height: 1, indent: 56),
                              ListTile(
                                leading: Icon(
                                  Icons.language,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                title: Text(
                                  AppLocalizations.of(context).languageSetting,
                                ),
                                subtitle: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).languageSettingSub,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
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
                                onTap: () =>
                                    SettingsUtils.openLanguageSettings(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top: 32.0),
                      child: Column(
                        children: [
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
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.install_mobile_outlined,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppLocalizations.of(context).installApp,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

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
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.bug_report_outlined,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context).reportIssue,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

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
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.logout, size: 20),
                                  const SizedBox(width: 8),
                                  Text(AppLocalizations.of(context).logout),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_versionStr.isNotEmpty)
                            Text(
                              'v$_versionStr',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.outline,
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 14, color: Colors.white),
        ),
      ],
    );
  }
}
