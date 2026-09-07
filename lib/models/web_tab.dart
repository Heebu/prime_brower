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

  // Memory Hibernation (Chrome / Brave Memory Saver)
  bool isFrozen;
  DateTime lastActiveTime;
  final int estimatedMemorySavedMb;

  // Tab Organization & Pinning
  bool isPinned;
  String? groupTag;

  WebViewController? _controller;
  final void Function(WebViewController controller)? onPageFinishedCallback;
  final bool Function(String url)? onNavigationRequestFilter;
  final void Function(String url)? onDownloadRequested;

  // Callbacks for notifying state listeners
  final void Function(String url)? onUrlChanged;
  final void Function(String title)? onTitleChanged;
  final void Function(bool isLoading)? onLoadingChanged;
  final void Function(int progress)? onProgressChanged;
  final void Function(bool isFrozen)? onFrozenChanged;

  WebTab({
    required this.id,
    required this.url,
    this.title = 'New Tab',
    this.isIncognito = false,
    this.isLoading = false,
    this.progress = 0,
    this.devToolsInjected = false,
    this.isFrozen = false,
    this.isPinned = false,
    this.groupTag,
    DateTime? lastActiveTime,
    this.estimatedMemorySavedMb = 42,
    this.onUrlChanged,
    this.onTitleChanged,
    this.onLoadingChanged,
    this.onProgressChanged,
    this.onFrozenChanged,
    this.onPageFinishedCallback,
    this.onNavigationRequestFilter,
    this.onDownloadRequested,
  }) : lastActiveTime = lastActiveTime ?? DateTime.now() {
    if (url.isNotEmpty && url != 'prime://newtab' && !isFrozen) {
      final initialUri = Uri.tryParse(url);
      if (initialUri != null) {
        try {
          controller.loadRequest(initialUri);
        } catch (_) {}
      }
    }
  }

  bool get isNewTabPage => url.isEmpty || url == 'prime://newtab' || url == 'about:blank';

  String get domain {
    if (isNewTabPage) return 'New Tab';
    try {
      final uri = Uri.parse(url);
      if (uri.host.isNotEmpty) return uri.host.replaceFirst('www.', '');
    } catch (_) {}
    return 'Web';
  }

  WebViewController get controller {
    if (_controller == null) {
      _initController();
    }
    if (_controller == null) {
      throw UnsupportedError('WebViewPlatform is not available in this environment');
    }
    return _controller!;
  }

  void _initController() {
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) {
              if (onNavigationRequestFilter != null) {
                final allowed = onNavigationRequestFilter!(request.url);
                if (!allowed) {
                  return NavigationDecision.prevent;
                }
              }

              // Intercept file downloads to prevent WebView crash
              final isDownloadable = RegExp(
                r'\.(pdf|apk|zip|rar|7z|tar|gz|mp3|wav|mp4|mkv|docx|xlsx|pptx)(\?.*)?$',
                caseSensitive: false,
              ).hasMatch(request.url);

              if (isDownloadable && onDownloadRequested != null) {
                onDownloadRequested!(request.url);
                return NavigationDecision.prevent;
              }

              return NavigationDecision.navigate;
            },
            onProgress: (int p) {
              progress = p;
              onProgressChanged?.call(p);
            },
            onPageStarted: (String currentUrl) {
              url = currentUrl;
              isLoading = true;
              lastActiveTime = DateTime.now();
              onUrlChanged?.call(currentUrl);
              onLoadingChanged?.call(true);
            },
            onPageFinished: (String currentUrl) async {
              url = currentUrl;
              isLoading = false;
              lastActiveTime = DateTime.now();
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

  /// Puts the tab into memory hibernation to release WebView native RAM and background timers
  void freeze() {
    if (isFrozen || isNewTabPage) return;
    isFrozen = true;
    _controller = null;
    isLoading = false;
    onFrozenChanged?.call(true);
    onLoadingChanged?.call(false);
  }

  /// Wakes the tab up from hibernation and restores the page
  void thaw() {
    if (!isFrozen) return;
    isFrozen = false;
    lastActiveTime = DateTime.now();
    onFrozenChanged?.call(false);
    if (url.isNotEmpty && !isNewTabPage) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        try {
          controller.loadRequest(uri);
        } catch (_) {}
      }
    }
  }

  void loadUrl(String newUrl) {
    if (isFrozen) {
      thaw();
    }
    url = newUrl;
    lastActiveTime = DateTime.now();
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
      try {
        controller.loadRequest(uri);
      } catch (_) {}
    }
  }

  void reload() {
    if (isFrozen) {
      thaw();
    } else {
      try {
        _controller?.reload();
      } catch (_) {}
    }
  }

  Future<bool> canGoBack() async => (await _controller?.canGoBack()) ?? false;
  Future<bool> canGoForward() async => (await _controller?.canGoForward()) ?? false;
  Future<void> goBack() async => await _controller?.goBack();
  Future<void> goForward() async => await _controller?.goForward();
}
