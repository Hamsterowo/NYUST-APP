import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import '../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../widgets/custom_app_bar.dart';

/// 在學證明：以 App 端點（Bearer token）打 `/api/User/GetYunReport` 取得 PDF 並顯示。
class YunReportScreen extends ConsumerStatefulWidget {
  const YunReportScreen({super.key});

  @override
  ConsumerState<YunReportScreen> createState() => _YunReportScreenState();
}

class _YunReportScreenState extends ConsumerState<YunReportScreen> {
  PdfControllerPinch? _controller;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    Uint8List? bytes;
    try {
      bytes = await ref.read(authProvider).api.appApi.getYunReport();
    } catch (_) {
      bytes = null;
    }
    if (!mounted) return;
    if (bytes == null || bytes.isEmpty) {
      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }
    _controller = PdfControllerPinch(document: PdfDocument.openData(bytes));
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: CustomAppBar(title: l.infoYunReportTitle),
      body: _buildBody(l),
    );
  }

  Widget _buildBody(AppLocalizations l) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_failed || _controller == null) {
      final colorScheme = Theme.of(context).colorScheme;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                l.yunReportUnavailable,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: _load,
                child: Text(l.yunReportRetry),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(child: PdfViewPinch(controller: _controller!)),
        _buildNote(l),
      ],
    );
  }

  Widget _buildNote(AppLocalizations l) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.yunReportNoteDisplay,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.yunReportNotePaper,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
