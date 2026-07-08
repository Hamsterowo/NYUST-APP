import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/top_snack_bar.dart';
import 'login_form.dart';
import '../utils/pwa_interop.dart';
import '../utils/settings_utils.dart';
import 'privacy_policy_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:workmanager/workmanager.dart';
import '../services/background_service.dart';
import '../services/grade_notification_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _versionStr = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  void _toggleGradeNotification(bool enabled) async {
    final result = await ref
        .read(gradeNotificationEnabledProvider.notifier)
        .setEnabled(enabled);
    if (!mounted) return;
    switch (result) {
      case GradeNotificationResult.permissionDenied:
        showTopSnackBar(
          context,
          AppLocalizations.of(context).notificationPermissionDenied,
          type: SnackBarType.warning,
        );
      case GradeNotificationResult.enabled:
        showTopSnackBar(
          context,
          AppLocalizations.of(context).settingsGradeNotificationSub,
          type: SnackBarType.success,
        );
      case GradeNotificationResult.disabled:
        break;
    }
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

  void _showReportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppLocalizations.of(sheetContext).reportChannelTitle,
                    style: Theme.of(sheetContext).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: Text(AppLocalizations.of(sheetContext).reportViaEmail),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _sendReportEmail();
                },
              ),
              ListTile(
                leading: const Icon(Icons.forum_outlined),
                title: Text(AppLocalizations.of(sheetContext).reportViaDiscord),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openDiscord();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendReportEmail() async {
    final l10n = AppLocalizations.of(context);
    final platform = kIsWeb ? 'Web' : defaultTargetPlatform.name;
    final version = _versionStr.isNotEmpty ? _versionStr : '-';
    final uri = Uri.parse(
      'mailto:support@hamster.tw'
      '?subject=${Uri.encodeComponent(l10n.reportEmailSubject)}'
      '&body=${Uri.encodeComponent(l10n.reportEmailBody(version, platform))}',
    );
    if (!await launchUrl(uri) && mounted) {
      showTopSnackBar(
        context,
        l10n.reportLaunchError,
        type: SnackBarType.warning,
      );
    }
  }

  Future<void> _openDiscord() async {
    final uri = Uri.parse('https://discord.gg/jdaKepXgP2');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      showTopSnackBar(
        context,
        AppLocalizations.of(context).reportLaunchError,
        type: SnackBarType.warning,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final gradeNotifEnabled = ref.watch(gradeNotificationEnabledProvider);

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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundColor:
                                          colorScheme.primaryContainer,
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            user?["user"]?["name"] ??
                                                user?["user"]?["姓名"] ??
                                                "Student",
                                            style: textTheme.headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            user?["user"]?["系(所)別"] ??
                                                user?["user"]?["department"] ??
                                                "Unknown",
                                            style: textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.7),
                                                ),
                                          ),
                                          const SizedBox(height: 16),
                                          _buildInfoRow(
                                            Icons.badge_outlined,
                                            user?["user"]?["學號"] ??
                                                "ID Unknown",
                                          ),
                                          const SizedBox(height: 8),
                                          _buildInfoRow(
                                            Icons.school_outlined,
                                            user?["user"]?["班級"] ??
                                                "No Class Info",
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                ..._buildExtraInfoSection(user?["user"]),
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
                          child: ListTileTheme(
                            data: const ListTileThemeData(
                              visualDensity: VisualDensity(vertical: -2),
                              minVerticalPadding: 4,
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: Icon(
                                    Icons.privacy_tip_outlined,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  title: Text(
                                    AppLocalizations.of(
                                      context,
                                    ).appPrivacyPolicy,
                                  ),
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
                                            const PrivacyPolicyScreen(),
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
                                    AppLocalizations.of(
                                      context,
                                    ).languageSetting,
                                  ),
                                  trailing: Icon(
                                    Icons.chevron_right,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  onTap: () =>
                                      SettingsUtils.openLanguageSettings(),
                                ),
                                if (!kIsWeb) ...[
                                  const Divider(height: 1, indent: 56),
                                  ListTile(
                                    leading: Icon(
                                      Icons.notifications_active_outlined,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    title: Text(
                                      AppLocalizations.of(
                                        context,
                                      ).settingsGradeNotification,
                                    ),
                                    trailing: Transform.scale(
                                      scale: 0.8, // 縮小 20%
                                      alignment: Alignment.centerRight, // 靠右對齊
                                      child: Switch.adaptive(
                                        value: gradeNotifEnabled,
                                        onChanged: _toggleGradeNotification,
                                      ),
                                    ),
                                    onTap: () => _toggleGradeNotification(
                                      !gradeNotifEnabled,
                                    ),
                                  ),
                                ],
                                if (kDebugMode && !kIsWeb) ...[
                                  const Divider(height: 1, indent: 56),
                                  ListTile(
                                    leading: const Icon(
                                      Icons.bug_report_outlined,
                                      color: Colors.orange,
                                    ),
                                    title: const Text('【開發者】立即觸發一次背景檢查'),
                                    subtitle: const Text(
                                      '點擊後將會立刻在背景啟動一次排程任務進行測試',
                                    ),
                                    trailing: const Icon(Icons.play_arrow),
                                    onTap: () async {
                                      await Workmanager().registerOneOffTask(
                                        "manual_oneoff_${DateTime.now().millisecondsSinceEpoch}",
                                        checkGradesTask,
                                      );
                                      if (!context.mounted) return;
                                      showTopSnackBar(
                                        context,
                                        '已註冊立即執行的背景任務，請查看通知！',
                                        type: SnackBarType.info,
                                      );
                                    },
                                  ),
                                ],
                                const Divider(height: 1, indent: 56),
                                ListTile(
                                  leading: Icon(
                                    Icons.bug_report_outlined,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  title: Text(
                                    AppLocalizations.of(context).reportIssue,
                                  ),
                                  trailing: Icon(
                                    Icons.chevron_right,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  onTap: () => _showReportOptions(context),
                                ),
                                const Divider(height: 1, indent: 56),
                                ListTile(
                                  leading: Icon(
                                    Icons.logout,
                                    color: colorScheme.error,
                                  ),
                                  title: Text(
                                    AppLocalizations.of(context).logout,
                                    style: TextStyle(color: colorScheme.error),
                                  ),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                  ),
                                  onTap: () => auth.logout(),
                                ),
                              ],
                            ),
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
        Text(text, style: const TextStyle(fontSize: 14, color: Colors.white)),
      ],
    );
  }

  List<Widget> _buildExtraInfoSection(Map<String, dynamic>? userInfo) {
    if (userInfo == null) return [];

    final List<Map<String, String>> extraFields = [];
    final fieldsToCheck = {
      '輔系/雙主修': Icons.account_tree_outlined,
      '學程': Icons.collections_bookmark_outlined,
      '教育學程': Icons.menu_book_outlined,
    };

    fieldsToCheck.forEach((field, icon) {
      final value = userInfo[field]?.toString().trim() ?? '';
      if (value.isNotEmpty &&
          value != '無' &&
          value != 'None' &&
          value != 'null') {
        extraFields.add({'label': field, 'value': value});
      }
    });

    if (extraFields.isEmpty) return [];

    return [
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Divider(color: Colors.white24, height: 1),
      ),
      Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: extraFields.map((field) {
          final label = field['label']!;
          final value = field['value']!;

          String displayLabel = label;
          IconData icon;
          if (label == '輔系/雙主修') {
            icon = Icons.account_tree_outlined;
            displayLabel = AppLocalizations.of(context).profileMinorDoubleMajor;
          } else if (label == '學程') {
            icon = Icons.collections_bookmark_outlined;
            displayLabel = AppLocalizations.of(context).profileProgram;
          } else {
            icon = Icons.menu_book_outlined;
            displayLabel = AppLocalizations.of(context).profileTeacherEducation;
          }

          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: Colors.amber[200]),
                const SizedBox(width: 8),
                Text(
                  '$displayLabel: $value',
                  style: const TextStyle(color: Colors.white, fontSize: 12.0),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ];
  }
}
