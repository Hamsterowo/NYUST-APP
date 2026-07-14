import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import '../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../services/app_api/app_api_service.dart';
import '../utils/network_error.dart';
import '../widgets/app_api_password_dialog.dart';
import '../widgets/custom_app_bar.dart';

/// 載入失敗的種類,對應不同的使用者訊息。
enum _FailureKind {
  /// 503:本學期尚未完成註冊,學校不核發在學證明。
  notRegistered,

  /// 連不上在學證明服務(離線/逾時)。
  offline,

  /// 其他錯誤(伺服器異常、PDF 解析失敗等)。
  generic,
}

/// 在學證明：以 App 端點（Bearer token）打 `/api/User/GetYunReport` 取得 PDF 並顯示。
class YunReportScreen extends ConsumerStatefulWidget {
  const YunReportScreen({super.key});

  @override
  ConsumerState<YunReportScreen> createState() => _YunReportScreenState();
}

class _YunReportScreenState extends ConsumerState<YunReportScreen> {
  /// 每頁預先算好的點陣圖（PNG bytes），以固定頁寬顯示、不提供縮放。
  List<Uint8List>? _pageImages;
  bool _loading = true;
  bool _failed = false;
  _FailureKind _failureKind = _FailureKind.generic;
  bool _needsAuth = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
      _failureKind = _FailureKind.generic;
      _needsAuth = false;
    });
    Uint8List? bytes;
    try {
      bytes = await ref.read(authProvider).api.appApi.getYunReport();
    } on AppApiAuthRequiredException {
      // Token expired and no saved credential — prompt for the password.
      if (!mounted) return;
      final ok = await showAppApiPasswordDialog(context, ref);
      if (!mounted) return;
      if (ok == true) {
        return _load(); // retry with the fresh token
      }
      setState(() {
        _loading = false;
        _needsAuth = true;
      });
      return;
    } on AppApiNotRegisteredException {
      // 503:未完成本學期註冊 — 顯示明確原因,而非籠統失敗。
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
        _failureKind = _FailureKind.notRegistered;
      });
      return;
    } catch (e) {
      // 離線/連不上與其他錯誤分開,顯示對應訊息。
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
        _failureKind = isNetworkError(e)
            ? _FailureKind.offline
            : _FailureKind.generic;
      });
      return;
    }
    if (!mounted) return;
    if (bytes == null || bytes.isEmpty) {
      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }
    List<Uint8List> pages;
    try {
      pages = await _renderPages(bytes);
    } catch (_) {
      pages = const [];
    }
    if (!mounted) return;
    if (pages.isEmpty) {
      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }
    setState(() {
      _pageImages = pages;
      _loading = false;
    });
  }

  /// 把 PDF 每頁算成點陣圖。以固定目標寬度算圖，之後 UI 再依螢幕寬縮放，
  /// 確保「符合頁寬」且不需要縮放手勢。
  Future<List<Uint8List>> _renderPages(Uint8List bytes) async {
    const targetWidth = 1600.0;
    final document = await PdfDocument.openData(bytes);
    final images = <Uint8List>[];
    try {
      for (var i = 1; i <= document.pagesCount; i++) {
        final page = await document.getPage(i);
        try {
          final scale = targetWidth / page.width;
          final image = await page.render(
            width: page.width * scale,
            height: page.height * scale,
            format: PdfPageImageFormat.png,
            backgroundColor: '#FFFFFF',
          );
          if (image != null) images.add(image.bytes);
        } finally {
          await page.close();
        }
      }
    } finally {
      await document.close();
    }
    return images;
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
    if (_needsAuth) {
      final colorScheme = Theme.of(context).colorScheme;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 56,
                color: colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                l.appAuthRequiredMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: _load, child: Text(l.appAuthUnlock)),
            ],
          ),
        ),
      );
    }
    if (_failed || _pageImages == null || _pageImages!.isEmpty) {
      final colorScheme = Theme.of(context).colorScheme;
      // 依失敗種類顯示明確原因:未註冊 / 連不上服務 / 其他錯誤。
      final String failureText = switch (_failureKind) {
        _FailureKind.notRegistered => l.yunReportNotRegistered,
        _FailureKind.offline => l.serviceUnavailable(l.serviceYunReport),
        _FailureKind.generic => l.yunReportUnavailable,
      };
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _failureKind == _FailureKind.notRegistered
                    ? Icons.info_outline_rounded
                    : Icons.error_outline_rounded,
                size: 56,
                color: colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                failureText,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: ColoredBox(
            color: colorScheme.surfaceContainerHighest,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final image in _pageImages!)
                    Image.memory(
                      image,
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      gaplessPlayback: true,
                    ),
                ],
              ),
            ),
          ),
        ),
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
