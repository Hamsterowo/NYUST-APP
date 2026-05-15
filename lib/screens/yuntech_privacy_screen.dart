import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class YuntechPrivacyScreen extends StatefulWidget {
  final bool showAgreementButtons;

  const YuntechPrivacyScreen({
    super.key,
    this.showAgreementButtons = false,
  });

  @override
  State<YuntechPrivacyScreen> createState() => _YuntechPrivacyScreenState();
}

class _YuntechPrivacyScreenState extends State<YuntechPrivacyScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final api = context.read<AuthProvider>().api;
      final res = await api.getPrivacyPolicy();
      if (mounted) {
        if (res['status'] == 'success') {
          setState(() {
            _data = res['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = res['message'] ?? '取得失敗';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '單一入口網隱私權政策',
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
                          Navigator.pop(context, false);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('返回'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '發生錯誤: $_error',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.error),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _error = null;
                        });
                        _fetchData();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('重試'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: ((_data?['blocks'] as List?)?.length ?? 0) + 1,
              itemBuilder: (context, index) {
                if (index == (_data?['blocks'] as List?)?.length) {
                  return const SizedBox(height: 32);
                }
                final block = _data!['blocks'][index];
                final String type = block['type'];
                final String text = block['text'];

                if (type == 'header') {
                  return Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 8),
                    child: Text(
                      text,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  );
                } else if (type == 'list_item') {
                  return Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 8, top: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            text,
                            style: textTheme.bodyMedium?.copyWith(
                              height: 1.6,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12, top: 4),
                    child: Text(
                      text,
                      style: textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  );
                }
              },
            ),
    );
  }
}
