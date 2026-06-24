import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class AppWebViewScreen extends StatefulWidget {
  final String url;
  final bool injectCookies;

  const AppWebViewScreen({
    super.key,
    required this.url,
    this.injectCookies = true,
  });

  @override
  State<AppWebViewScreen> createState() => _AppWebViewScreenState();
}

class _AppWebViewScreenState extends State<AppWebViewScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _progress = progress;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("WebView Error: code=${error.errorCode}, description=${error.description}, type=${error.errorType}, url=${error.url}, isForMainFrame=${error.isForMainFrame}");
            if (error.description.contains("net::ERR_ABORTED")) return;
            
            // Only trigger error screen if the error is for the main page frame
            if (error.isForMainFrame ?? true) {
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _isLoading = false;
                });
              }
            }
          },
        ),
      );

    _initWebView();
  }

  Future<void> _initWebView() async {
    if (widget.injectCookies) {
      await _injectCookies();
    }
    if (mounted) {
      _controller.loadRequest(Uri.parse(widget.url));
    }
  }

  Future<void> _injectCookies() async {
    try {
      final auth = context.read<AuthProvider>();
      final uri = Uri.parse(widget.url);
      final cookies = await auth.api.getCookiesForUri(uri);

      final cookieManager = WebViewCookieManager();
      for (var cookie in cookies) {
        await cookieManager.setCookie(
          WebViewCookie(
            name: cookie.name,
            value: cookie.value,
            domain: cookie.domain ?? uri.host,
            path: cookie.path ?? '/',
          ),
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
        if (await _controller.canGoBack()) {
          await _controller.goBack();
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
              if (await _controller.canGoBack()) {
                await _controller.goBack();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller.reload(),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                final currentUrl = await _controller.currentUrl();
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
                        content: Text(AppLocalizations.of(context).webViewLinkCopied),
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
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                )
              : null,
        ),
        body: Stack(
          children: [
            if (!_hasError) WebViewWidget(controller: _controller),
            if (_hasError)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.of(context).webViewLoadFailed, style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _isLoading = true;
                        });
                        _controller.reload();
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
