import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../providers/providers.dart';

class AppWebViewScreen extends ConsumerStatefulWidget {
  final String url;
  final bool injectCookies;

  const AppWebViewScreen({
    super.key,
    required this.url,
    this.injectCookies = true,
  });

  @override
  ConsumerState<AppWebViewScreen> createState() => _AppWebViewScreenState();
}

class _AppWebViewScreenState extends ConsumerState<AppWebViewScreen> {
  InAppWebViewController? _controller;
  int _progress = 0;
  bool _isLoading = true;
  bool _hasError = false;

  /// 只做一次「導回目標深層頁」的重導（見 [_maybeReachIntendedPage]）。
  bool _reNavigated = false;

  /// The URL to actually load — the WebView bypasses the Dio
  /// [LanguageInterceptor], so mirror its `lang=` logic here (based on the
  /// app locale) for portal pages, otherwise the page would ignore the
  /// app language and render in the portal's default (Chinese).
  String get _effectiveUrl =>
      _localizedPortalUrl(widget.url, Localizations.localeOf(context));

  /// Injects the app's session cookies into the WebView before loading, then
  /// kicks off the initial page load. Cookies are set via the global
  /// [CookieManager] so this must complete before the first request is made,
  /// otherwise the portal page would render logged-out.
  Future<void> _loadInitial(InAppWebViewController controller) async {
    if (widget.injectCookies) {
      await _injectCookies(controller);
    }
    await controller.loadUrl(
      urlRequest: URLRequest(url: WebUri(_effectiveUrl)),
    );
  }

  /// Appends `lang=en` / `lang=zh-TW` to WebNewCAS/eStudent portal pages on
  /// webapp.yuntech.edu.tw so the in-app browser honours the app language.
  /// Non-portal or already-tagged URLs are returned unchanged. Mirrors
  /// `LanguageInterceptor` in `api_client.dart`.
  String _localizedPortalUrl(String url, Locale locale) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final path = uri.path.toLowerCase();
    final isPortal =
        uri.host == 'webapp.yuntech.edu.tw' &&
        (path.contains('/webnewcas/') || path.contains('/estudent/'));
    if (!isPortal || url.toLowerCase().contains('lang=')) return url;

    final langValue = locale.languageCode.toLowerCase() == 'en'
        ? 'en'
        : 'zh-TW';
    if (url.contains('?')) {
      final last = url[url.length - 1];
      return (last == '?' || last == '&')
          ? '${url}lang=$langValue'
          : '$url&lang=$langValue';
    }
    return '$url?lang=$langValue';
  }

  /// 判斷某路徑是否為子系統首頁。涵蓋 ASP.NET WebForms 的 `default.aspx`
  /// （如 WebASXASG）與 ASP.NET MVC 的 `Home/Index`（如 AsxServ）兩種形式。
  bool _isAppHome(String path) =>
      path.endsWith('/default.aspx') || path.endsWith('/home/index');

  /// 有些雲科子系統（WebASXASG / AsxServ…）是各自獨立的 ASP.NET App：第一次
  /// 直接開深層頁時，因該 App 的 session 尚未建立，會先走 SSO 交握、最後停在
  /// 該 App 的首頁（WebForms 的 `default.aspx` 或 MVC 的 `Home/Index`）而非
  /// 目標頁。此時 App session 已建立，再導一次目標網址即可正確落在深層頁。
  /// 只做一次，避免無限重導。
  void _maybeReachIntendedPage(
    InAppWebViewController controller,
    WebUri? current,
  ) {
    if (_reNavigated || current == null) return;
    final target = Uri.tryParse(_effectiveUrl);
    if (target == null) return;

    final curPath = current.path.toLowerCase();
    final tgtPath = target.path.toLowerCase();
    final wantedDeepPage = !_isAppHome(tgtPath);
    final bouncedToHome = _isAppHome(curPath);

    if (wantedDeepPage && bouncedToHome && curPath != tgtPath) {
      _reNavigated = true;
      controller.loadUrl(urlRequest: URLRequest(url: WebUri(_effectiveUrl)));
    }
  }

  Future<void> _injectCookies(InAppWebViewController controller) async {
    try {
      final auth = ref.read(authProvider);
      final uri = Uri.parse(widget.url);
      final cookies = await auth.api.getCookiesForUri(uri);

      final cookieManager = CookieManager.instance();
      for (final cookie in cookies) {
        await cookieManager.setCookie(
          url: WebUri.uri(uri),
          name: cookie.name,
          value: cookie.value,
          domain: cookie.domain,
          path: cookie.path ?? '/',
          isSecure: cookie.secure,
          isHttpOnly: cookie.httpOnly,
          expiresDate: cookie.expires?.millisecondsSinceEpoch,
          // Needed so cookies land in the shared store on older iOS (< 11).
          webViewController: controller,
        );
      }
    } catch (e) {
      if (kDebugMode) print("Failed to inject cookies to webview: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final controller = _controller;
        if (controller != null && await controller.canGoBack()) {
          await controller.goBack();
        } else {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final controller = _controller;
              if (controller != null && await controller.canGoBack()) {
                await controller.goBack();
              } else {
                if (!context.mounted) return;
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller?.reload(),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                final currentUrl = (await _controller?.getUrl())?.toString();
                if (currentUrl == null || currentUrl.isEmpty) return;

                if (value == 'open_in_browser') {
                  final uri = Uri.parse(currentUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                } else if (value == 'copy_link') {
                  await Clipboard.setData(ClipboardData(text: currentUrl));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context).webViewLinkCopied,
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'open_in_browser',
                  child: Row(
                    children: [
                      const Icon(Icons.open_in_new, size: 20),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context).webViewOpenInBrowser),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'copy_link',
                  child: Row(
                    children: [
                      const Icon(Icons.copy, size: 20),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context).webViewCopyLink),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
          bottom: _isLoading && _progress < 100
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2.0),
                  child: LinearProgressIndicator(
                    value: _progress / 100.0,
                    minHeight: 2.0,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                )
              : null,
        ),
        body: Stack(
          children: [
            if (!_hasError)
              InAppWebView(
                initialSettings: InAppWebViewSettings(javaScriptEnabled: true),
                onWebViewCreated: (controller) {
                  _controller = controller;
                  _loadInitial(controller);
                },
                onProgressChanged: (controller, progress) {
                  if (mounted) {
                    setState(() {
                      _progress = progress;
                    });
                  }
                },
                onLoadStart: (controller, url) {
                  if (mounted) {
                    setState(() {
                      _isLoading = true;
                      _hasError = false;
                    });
                  }
                },
                onLoadStop: (controller, url) {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                  _maybeReachIntendedPage(controller, url);
                },
                onReceivedError: (controller, request, error) {
                  debugPrint(
                    "WebView Error: type=${error.type}, description=${error.description}, url=${request.url}, isForMainFrame=${request.isForMainFrame}",
                  );
                  // Ignore aborted loads (e.g. redirects / user navigation).
                  if (error.type == WebResourceErrorType.CANCELLED) return;
                  if (error.description.contains("net::ERR_ABORTED")) return;

                  // Only trigger error screen if the error is for the main page frame
                  if (request.isForMainFrame ?? true) {
                    if (mounted) {
                      setState(() {
                        _hasError = true;
                        _isLoading = false;
                      });
                    }
                  }
                },
              ),
            if (_hasError)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).webViewLoadFailed,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _isLoading = true;
                        });
                        final controller = _controller;
                        if (controller != null) {
                          controller.loadUrl(
                            urlRequest: URLRequest(url: WebUri(_effectiveUrl)),
                          );
                        }
                      },
                      child: Text(AppLocalizations.of(context).webViewRefresh),
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
