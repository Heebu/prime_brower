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
  late final WebViewController controller;

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
    void Function(WebViewController controller)? onPageFinishedCallback,
  }) {
    controller = WebViewController()
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
              final pageTitle = await controller.getTitle();
              if (pageTitle != null && pageTitle.isNotEmpty) {
                title = pageTitle;
                onTitleChanged?.call(title);
              }
            } catch (_) {}
            onUrlChanged?.call(currentUrl);
            onLoadingChanged?.call(false);
            onPageFinishedCallback?.call(controller);
          },
          onWebResourceError: (WebResourceError error) {
            isLoading = false;
            onLoadingChanged?.call(false);
          },
        ),
      );

    if (url.isNotEmpty) {
      final initialUri = Uri.tryParse(url);
      if (initialUri != null) {
        controller.loadRequest(initialUri);
      }
    }
  }

  void loadUrl(String newUrl) {
    url = newUrl;
    final uri = Uri.tryParse(newUrl);
    if (uri != null) {
      controller.loadRequest(uri);
    }
  }

  void reload() {
    controller.reload();
  }

  Future<bool> canGoBack() => controller.canGoBack();
  Future<bool> canGoForward() => controller.canGoForward();
  Future<void> goBack() => controller.goBack();
  Future<void> goForward() => controller.goForward();
}
