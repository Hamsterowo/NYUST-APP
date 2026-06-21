import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';

class TermsOfServiceScreen extends StatefulWidget {
  final bool showAgreementButtons;
  final Map<String, dynamic>? initialTerms;

  const TermsOfServiceScreen({
    super.key,
    this.showAgreementButtons = false,
    this.initialTerms,
  });

  static Future<void> showUpdateAlert(BuildContext context) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'TermsUpdate',
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
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
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
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  late Future<Map<String, dynamic>> _termsFuture;
  String _lastUpdated = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialTerms != null) {
      _termsFuture = Future.value(widget.initialTerms!);
      _lastUpdated = widget.initialTerms!['data']?['lastUpdated'] ?? '';
    } else {
      _termsFuture = _fetchTerms();
    }
  }

  Future<Map<String, dynamic>> _fetchTerms() async {
    try {
      final res = await context.read<AuthProvider>().api.getTermsOfService();
      if (res['status'] == 'success') {
        setState(() {
          _lastUpdated = res['data']?['lastUpdated'] ?? '';
        });
      }
      return res;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NYUST+ 使用者條款',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        scrolledUnderElevation: 0,

        automaticallyImplyLeading: !widget.showAgreementButtons,
      ),
      bottomNavigationBar: widget.showAgreementButtons
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {

                          SystemNavigator.pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          side: BorderSide(color: colorScheme.error),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('拒絕並退出程式'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: _lastUpdated.isNotEmpty
                            ? () {
                                Navigator.pop(context, _lastUpdated);
                              }
                            : null,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('同意'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _termsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data?['status'] != 'success') {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    '無法載入使用者條款\n${snapshot.error ?? snapshot.data?['message'] ?? '未知錯誤'}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.error),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () {
                      setState(() {
                        _termsFuture = _fetchTerms();
                      });
                    },
                    child: const Text('重新整理'),
                  ),
                ],
              ),
            );
          }

          final policyData = snapshot.data!['data'];
          final List<dynamic> blocks = policyData['blocks'] ?? [];
          final String lastUpdated = policyData['lastUpdated'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...blocks.map((block) {
                  if (block['type'] == 'header') {
                    return _buildSectionTitle(block['text'], context);
                  } else {
                    return _buildParagraph(block['text'], context);
                  }
                }),
                if (lastUpdated.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      '最後更新日期：$lastUpdated',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text, BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        height: 1.8,
        fontSize: 15,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
