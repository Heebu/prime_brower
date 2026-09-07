import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'models/web_tab.dart';
import 'services/browser_manager.dart';
import 'services/shields_service.dart';
import 'services/connectivity_banner_service.dart';
import 'ui/new_tab/new_tab_dashboard.dart';
import 'ui/offline/prime_runner_screen.dart';
import 'ui/widgets/browser_banner_widget.dart';
import 'core/design_system/pull_to_refresh_wrapper.dart';

class WebViewPage extends StatelessWidget {
  final WebTab tab;
  final BrowserManager browserManager;
  final ShieldsService shieldsService;

  const WebViewPage({
    super.key,
    required this.tab,
    required this.browserManager,
    required this.shieldsService,
  });

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
          tabId: tab.id,
          browserManager: browserManager,
          shieldsService: shieldsService,
          onNavigate: (url) => tab.loadUrl(url),
        ),
      );
    }

    if (tab.isOffline) {
      return PrimeRunnerScreen(
        isOnline: ConnectivityBannerService.instance.isOnline,
        onRetryConnection: () {
          tab.isOffline = false;
          tab.reload();
        },
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

          // Contextual In-Browser Banners (Slow network, No network, Page error, Security, Permission, etc.)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: ConnectivityBannerService.instance,
              builder: (context, _) {
                final banners = ConnectivityBannerService.instance.getBannersForTab(tab.id);
                if (banners.isEmpty) return const SizedBox.shrink();

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: banners.map((banner) {
                    return BrowserBannerWidget(
                      key: ValueKey(banner.id),
                      banner: banner,
                      onDismiss: () {
                        ConnectivityBannerService.instance.removeBanner(tab.id, banner.id);
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}