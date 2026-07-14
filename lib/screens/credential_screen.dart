import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../utils/status_colors.dart';
import '../widgets/app_api_password_dialog.dart';
import '../widgets/custom_app_bar.dart';

/// Settings page that surfaces the state of the app-endpoint credential (the
/// Bearer token from `/Token`): whether a valid token is held, roughly when it
/// expires, a "remember password" toggle, and an explanation of what the
/// credential is for and which features use it.
class CredentialScreen extends ConsumerStatefulWidget {
  const CredentialScreen({super.key});

  @override
  ConsumerState<CredentialScreen> createState() => _CredentialScreenState();
}

class _CredentialScreenState extends ConsumerState<CredentialScreen> {
  bool _remembered = false;
  bool _busy = false;

  /// True after the user turns "remember" off this session: the persisted hash
  /// is deleted immediately, but the in-memory copy is only dropped on the next
  /// app restart — so we warn the user about that.
  bool _clearOnRestart = false;

  @override
  void initState() {
    super.initState();
    _loadRemembered();
  }

  Future<void> _loadRemembered() async {
    final v = await ref.read(authProvider).api.appApi.isPasswordRemembered();
    if (!mounted) return;
    setState(() => _remembered = v);
  }

  Future<void> _onRememberChanged(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    final l = AppLocalizations.of(context);
    final appApi = ref.read(authProvider).api.appApi;
    bool applied;
    if (value) {
      applied = await appApi.setRememberPassword(true);
      if (!applied) {
        // No in-memory credential to persist — ask for the password with a
        // dialog whose copy is about *enabling remember* (not token expiry),
        // and with no confusing extra "remember" checkbox inside.
        if (!mounted) return;
        final ok = await showAppApiPasswordDialog(
          context,
          ref,
          title: l.credentialEnableRememberTitle,
          message: l.credentialEnableRememberMessage,
          showRememberOption: false,
          remember: true,
        );
        applied = ok == true;
        if (applied) {
          // reloginWithPassword(remember: true) already persisted it.
          applied = await appApi.isPasswordRemembered();
        }
      }
    } else {
      applied = await appApi.setRememberPassword(false);
    }
    if (!mounted) return;
    setState(() {
      _remembered = value ? applied : false;
      // Turning it off keeps the in-memory hash until restart → warn the user.
      _clearOnRestart = !value && applied;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final appApi = ref.watch(authProvider).api.appApi;
    final hasToken = appApi.hasToken;
    final expiry = appApi.tokenExpiry;

    return Scaffold(
      appBar: CustomAppBar(title: l.credentialTitle),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Status card
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        hasToken
                            ? Icons.verified_user_rounded
                            : Icons.gpp_bad_rounded,
                        color: hasToken
                            ? StatusColors.success
                            : colorScheme.outline,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l.credentialStatusTitle,
                        style: textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        hasToken
                            ? l.credentialStatusValid
                            : l.credentialStatusNone,
                        style: textTheme.titleMedium?.copyWith(
                          color: hasToken
                              ? StatusColors.success
                              : colorScheme.outline,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (hasToken) ...[
                    const SizedBox(height: 12),
                    Text(
                      _expiryText(l, expiry),
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Remember-password toggle
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest,
            child: SwitchListTile.adaptive(
              value: _remembered,
              onChanged: _busy ? null : _onRememberChanged,
              title: Text(l.loginRememberPassword),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.loginRememberPasswordHint),
                  const SizedBox(height: 4),
                  Text(
                    l.loginRememberPasswordWarning,
                    style: TextStyle(color: colorScheme.error),
                  ),
                ],
              ),
              secondary: Icon(
                Icons.key_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // About / features
          Text(l.credentialFeaturesTitle, style: textTheme.titleSmall),
          const SizedBox(height: 8),
          _bullet(context, l.infoYunReportTitle),
          const SizedBox(height: 20),
          Text(
            l.credentialAbout,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          if (_clearOnRestart) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 18,
                    color: colorScheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.credentialClearOnRestartHint,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onTertiaryContainer,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _expiryText(AppLocalizations l, DateTime? expiry) {
    if (expiry == null) return l.credentialExpiryUnknown;
    final date =
        '${expiry.year}/${expiry.month.toString().padLeft(2, '0')}/'
        '${expiry.day.toString().padLeft(2, '0')}';
    final days = expiry.difference(DateTime.now()).inDays;
    return '${l.credentialExpiryLabel}$date  ·  ${l.credentialDaysRemaining(days)}';
  }

  Widget _bullet(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline_rounded,
          size: 18,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}
