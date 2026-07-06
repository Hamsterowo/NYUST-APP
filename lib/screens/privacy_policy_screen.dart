import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/privacy_policy.dart';
import '../l10n/app_localizations.dart';

/// 本地隱私權政策頁面：渲染打包進 assets 的 `PRIVACY.*.md`（無需連網）。
///
/// 當 [showAgreementButtons] 為 true 時作為首次啟動的同意閘門：底部顯示
/// 「拒絕並退出」「同意」，同意後回傳目前政策的版本鍵（[PrivacyPolicy.version]）。
class PrivacyPolicyScreen extends StatefulWidget {
  final bool showAgreementButtons;

  const PrivacyPolicyScreen({super.key, this.showAgreementButtons = false});

  /// 政策更新時、於重新同意前顯示的提示彈窗。
  static Future<void> showUpdateAlert(BuildContext context) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'PrivacyPolicyUpdate',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: Duration.zero,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Center(
          child: PopScope(
            canPop: false,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                insetPadding: const EdgeInsets.symmetric(horizontal: 28),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2.0,
                              ),
                            ),
                            child: Icon(
                              Icons.notifications_rounded,
                              size: 28,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context).termsUpdateTitle,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppLocalizations.of(context).termsUpdateAlert,
                        textAlign: TextAlign.start,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(dialogContext),
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: Text(
                                AppLocalizations.of(context).continueLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  late Future<PrivacyPolicy> _policyFuture;
  PrivacyPolicy? _policy;
  String? _loadedLang;

  /// 連結片段的手勢辨識器；每次 build 重建，於 dispose 一併釋放。
  final List<TapGestureRecognizer> _linkRecognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _linkRecognizers) {
      r.dispose();
    }
    _linkRecognizers.clear();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// 依目前語系回傳 GitHub 上對應語言的政策頁網址。
  String _githubPolicyUrl(BuildContext context) {
    final file = Localizations.localeOf(context).languageCode == 'en'
        ? 'PRIVACY.en.md'
        : 'PRIVACY.zh-TW.md';
    return 'https://github.com/Hamsterowo/NYUST-APP/blob/main/$file';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Localizations.localeOf(context).languageCode;
    if (_loadedLang != lang) {
      _loadedLang = lang;
      _policy = null;
      _policyFuture = loadPrivacyPolicy(lang)
        ..then((p) {
          if (mounted) setState(() => _policy = p);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 上一幀的連結辨識器已不再被引用，於重建時釋放後重新建立。
    _disposeRecognizers();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).appPrivacyPolicy,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: !widget.showAgreementButtons,
      ),
      bottomNavigationBar: widget.showAgreementButtons
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () => _openUrl(_githubPolicyUrl(context)),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(
                        AppLocalizations.of(context).viewPolicyOnGithub,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => SystemNavigator.pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.error,
                              side: BorderSide(color: colorScheme.error),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              AppLocalizations.of(context).termsRejectAndExit,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton(
                            onPressed: _policy == null
                                ? null
                                : () =>
                                      Navigator.pop(context, _policy!.version),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              AppLocalizations.of(context).termsAgree,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: FutureBuilder<PrivacyPolicy>(
        future: _policyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: colorScheme.error,
              ),
            );
          }

          final policy = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final block in policy.blocks) _buildBlock(block, context),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    AppLocalizations.of(
                      context,
                    ).termsLastUpdated(policy.lastUpdated),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBlock(PolicyBlock block, BuildContext context) {
    switch (block.type) {
      case PolicyBlockType.header:
        return Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12),
          child: Text(
            block.spans.map((s) => s.text).join(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      case PolicyBlockType.subheader:
        return Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            block.spans.map((s) => s.text).join(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        );
      case PolicyBlockType.bullet:
        return Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ', style: _paragraphStyle(context)),
              Expanded(child: _buildRichText(block.spans, context)),
            ],
          ),
        );
      case PolicyBlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildRichText(block.spans, context),
        );
    }
  }

  TextStyle? _paragraphStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
      height: 1.8,
      fontSize: 15,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  Widget _buildRichText(List<PolicySpan> spans, BuildContext context) {
    final linkColor = Theme.of(context).colorScheme.primary;
    return Text.rich(
      TextSpan(
        style: _paragraphStyle(context),
        children: [
          for (final span in spans)
            if (span.url != null)
              TextSpan(
                text: span.text,
                style: TextStyle(
                  color: linkColor,
                  decoration: TextDecoration.underline,
                  decorationColor: linkColor,
                ),
                recognizer: _recognizerFor(span.url!),
              )
            else
              TextSpan(
                text: span.text,
                style: span.bold
                    ? const TextStyle(fontWeight: FontWeight.w700)
                    : null,
              ),
        ],
      ),
    );
  }

  TapGestureRecognizer _recognizerFor(String url) {
    final recognizer = TapGestureRecognizer()..onTap = () => _openUrl(url);
    _linkRecognizers.add(recognizer);
    return recognizer;
  }
}
