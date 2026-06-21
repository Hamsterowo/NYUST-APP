import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class TermsOfServiceScreen extends StatefulWidget {
  final bool showAgreementButtons;
  final Map<String, dynamic>? initialTerms;

  const TermsOfServiceScreen({
    super.key,
    this.showAgreementButtons = false,
    this.initialTerms,
  });

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
