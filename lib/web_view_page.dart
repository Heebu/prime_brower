import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'models/web_tab.dart';
import 'services/browser_manager.dart';
import 'services/shields_service.dart';
import 'ui/new_tab/new_tab_dashboard.dart';
import 'core/design_system/pull_to_refresh_wrapper.dart';

class WebViewPage extends StatelessWidget {
  final WebTab tab;
  final BrowserManager browserManager;
  final ShieldsService shieldsService;

  const WebViewPage({
    Key? key,
    required this.tab,
    required this.browserManager,
    required this.shieldsService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (tab.isNewTabPage) {
      return PullToRefreshWrapper(
        isIncognito: browserManager.isIncognito,
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 400));
          tab.reload();
        },
        child: NewTabDashboard(
          browserManager: browserManager,
          shieldsService: shieldsService,
          onNavigate: (url) => tab.loadUrl(url),
        ),
      );
    }

    return PullToRefreshWrapper(
      isIncognito: browserManager.isIncognito,
      onRefresh: () async {
        tab.reload();
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: Stack(
        children: [
          WebViewWidget(controller: tab.controller),
          if (tab.isLoading && tab.progress < 100)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: tab.progress / 100.0,
                minHeight: 3,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  browserManager.isIncognito ? Colors.deepPurpleAccent : Colors.blueAccent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}