import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebTab {
  final String id;
  String url;
  String title;
  final bool isIncognito;
  bool isLoading;
  int progress;
  bool devToolsInjected;

  WebViewController? _controller;
  final void Function(WebViewController controller)? onPageFinishedCallback;

  // Callbacks for notifying state listeners
  final void Function(String url)? onUrlChanged;
  final void Function(String title)? onTitleChanged;
  final void Function(bool isLoading)? onLoadingChanged;
  final void Function(int progress)? onProgressChanged;

  WebTab({
    required this.id,
    required this.url,
    this.title = 'New Tab',
    this.isIncognito = false,
    this.isLoading = false,
    this.progress = 0,
    this.devToolsInjected = false,
    this.onUrlChanged,
    this.onTitleChanged,
    this.onLoadingChanged,
    this.onProgressChanged,
    this.onPageFinishedCallback,
  }) {
    if (url.isNotEmpty && url != 'prime://newtab') {
      final initialUri = Uri.tryParse(url);
      if (initialUri != null) {
        controller.loadRequest(initialUri);
      }
    }
  }

  bool get isNewTabPage => url.isEmpty || url == 'prime://newtab' || url == 'about:blank';

  WebViewController get controller {
    if (_controller == null) {
      _initController();
    }
    return _controller!;
  }

  void _initController() {
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int p) {
              progress = p;
              onProgressChanged?.call(p);
            },
            onPageStarted: (String currentUrl) {
              url = currentUrl;
              isLoading = true;
              onUrlChanged?.call(currentUrl);
              onLoadingChanged?.call(true);
            },
            onPageFinished: (String currentUrl) async {
              url = currentUrl;
              isLoading = false;
              try {
                final pageTitle = await _controller?.getTitle();
                if (pageTitle != null && pageTitle.isNotEmpty) {
                  title = pageTitle;
                  onTitleChanged?.call(title);
                }
              } catch (_) {}
              onUrlChanged?.call(currentUrl);
              onLoadingChanged?.call(false);
              if (_controller != null) {
                onPageFinishedCallback?.call(_controller!);
              }
            },
            onWebResourceError: (WebResourceError error) {
              isLoading = false;
              onLoadingChanged?.call(false);
            },
          ),
        );
    } catch (e) {
      debugPrint('WebView controller init notice: $e');
    }
  }

  void loadUrl(String newUrl) {
    url = newUrl;
    if (newUrl == 'prime://newtab') {
      title = 'New Tab';
      isLoading = false;
      progress = 0;
      onUrlChanged?.call(newUrl);
      onTitleChanged?.call(title);
      onLoadingChanged?.call(false);
      return;
    }
    final uri = Uri.tryParse(newUrl);
    if (uri != null) {
      controller.loadRequest(uri);
    }
  }

  void reload() {
    _controller?.reload();
  }

  Future<bool> canGoBack() async => (await _controller?.canGoBack()) ?? false;
  Future<bool> canGoForward() async => (await _controller?.canGoForward()) ?? false;
  Future<void> goBack() async => await _controller?.goBack();
  Future<void> goForward() async => await _controller?.goForward();
}
