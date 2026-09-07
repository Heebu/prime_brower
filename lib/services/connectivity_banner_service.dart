import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/browser_banner.dart';

class ConnectivityBannerService with ChangeNotifier {
  static final ConnectivityBannerService instance = ConnectivityBannerService._internal();
  ConnectivityBannerService._internal() {
    _init();
  }

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final Map<String, List<BrowserBanner>> _tabBanners = {};
  final Map<String, Timer> _slowNetworkTimers = {};

  // Known phishing / deceptive URL patterns & suspicious keywords
  static final List<RegExp> _suspiciousPatterns = [
    RegExp(r'(paypa[l1]|apple[1i]d|app[l1]e|g0+gle|micr0soft|bankofamerica|wellsfargo|chase|netflix|coinbase|binance)[-_].*(verify|login|update|secure|unlock)', caseSensitive: false),
    RegExp(r'paypa[l1]', caseSensitive: false),
    RegExp(r'login.*verify.*account', caseSensitive: false),
    RegExp(r'crypto.*wallet.*connect.*private.*key', caseSensitive: false),
    RegExp(r'\.(phishing|scam|malware|free-crypto|airdrop-claim)\b', caseSensitive: false),
    RegExp(r'free-(iphone|robux|nitro|giftcard|crypto)\.', caseSensitive: false),
  ];

  void _init() {
    try {
      final connectivity = Connectivity();
      connectivity.checkConnectivity().then((results) {
        _updateOnlineState(results);
      }).catchError((dynamic err) {
        debugPrint('Connectivity check bypassed in test/headless: $err');
      });

      _connectivitySubscription = connectivity.onConnectivityChanged.listen(
        (results) {
          _updateOnlineState(results);
        },
        onError: (dynamic err) {
          debugPrint('Connectivity stream error: $err');
        },
      );
    } catch (e) {
      debugPrint('Connectivity init notice: $e');
    }
  }

  void _updateOnlineState(List<ConnectivityResult> results) {
    final hasConnection = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    if (_isOnline != hasConnection) {
      _isOnline = hasConnection;
      notifyListeners();
    }
  }

  void setOnlineForTesting(bool online) {
    _isOnline = online;
    notifyListeners();
  }

  // --- Banner Registry Methods ---

  List<BrowserBanner> getBannersForTab(String tabId) {
    return List.unmodifiable(_tabBanners[tabId] ?? []);
  }

  void addBanner(String tabId, BrowserBanner banner) {
    final list = _tabBanners.putIfAbsent(tabId, () => []);
    // Avoid duplicate banner types for the same tab
    list.removeWhere((b) => b.type == banner.type);
    list.insert(0, banner);
    notifyListeners();
  }

  void removeBanner(String tabId, String bannerId) {
    final list = _tabBanners[tabId];
    if (list != null) {
      list.removeWhere((b) => b.id == bannerId);
      if (list.isEmpty) {
        _tabBanners.remove(tabId);
      }
      notifyListeners();
    }
  }

  void clearBanners(String tabId) {
    _slowNetworkTimers[tabId]?.cancel();
    _slowNetworkTimers.remove(tabId);
    if (_tabBanners.remove(tabId) != null) {
      notifyListeners();
    }
  }

  // --- Banner Dispatchers ---

  void showNoNetworkBanner(
    String tabId, {
    required VoidCallback onRetry,
    required VoidCallback onPlayGame,
    VoidCallback? onDismiss,
  }) {
    addBanner(
      tabId,
      BrowserBanner.noNetwork(
        onRetry: onRetry,
        onPlayGame: onPlayGame,
        onDismiss: onDismiss,
      ),
    );
  }

  void showSlowNetworkBanner(
    String tabId, {
    required VoidCallback onReloadLite,
    VoidCallback? onDismiss,
  }) {
    addBanner(
      tabId,
      BrowserBanner.slowNetwork(
        onReloadLite: onReloadLite,
        onDismiss: onDismiss,
      ),
    );
  }

  void startSlowNetworkTimer(
    String tabId, {
    required VoidCallback onReloadLite,
    Duration duration = const Duration(seconds: 6),
  }) {
    _slowNetworkTimers[tabId]?.cancel();
    _slowNetworkTimers[tabId] = Timer(duration, () {
      showSlowNetworkBanner(tabId, onReloadLite: onReloadLite);
    });
  }

  void cancelSlowNetworkTimer(String tabId) {
    _slowNetworkTimers[tabId]?.cancel();
    _slowNetworkTimers.remove(tabId);
  }

  void showPageErrorBanner(
    String tabId, {
    required String errorDescription,
    required VoidCallback onRetry,
    VoidCallback? onDismiss,
  }) {
    addBanner(
      tabId,
      BrowserBanner.pageError(
        errorDescription: errorDescription,
        onRetry: onRetry,
        onDismiss: onDismiss,
      ),
    );
  }

  bool evaluateUrlSecurity(
    String tabId,
    String url, {
    required VoidCallback onBackToSafety,
    VoidCallback? onProceedAnyway,
  }) {
    final lowerUrl = url.toLowerCase();
    String domain = url;
    try {
      final uri = Uri.parse(url);
      domain = uri.host.isNotEmpty ? uri.host : url;
    } catch (_) {}

    for (final pattern in _suspiciousPatterns) {
      if (pattern.hasMatch(lowerUrl)) {
        addBanner(
          tabId,
          BrowserBanner.securityWarning(
            domain: domain,
            onBackToSafety: onBackToSafety,
            onProceedAnyway: onProceedAnyway,
          ),
        );
        return false; // Flagged as suspicious
      }
    }
    return true;
  }

  void checkInsecureHttp(
    String tabId,
    String url, {
    required VoidCallback onUpgradeHttps,
  }) {
    if (url.startsWith('http://') &&
        !url.startsWith('http://localhost') &&
        !url.startsWith('http://127.0.0.1')) {
      addBanner(
        tabId,
        BrowserBanner.insecureHttp(
          onUpgradeHttps: onUpgradeHttps,
        ),
      );
    }
  }

  void requestPermission(
    String tabId, {
    required String domain,
    required PermissionType permission,
    required VoidCallback onAllow,
    required VoidCallback onBlock,
  }) {
    addBanner(
      tabId,
      BrowserBanner.permission(
        domain: domain,
        permission: permission,
        onAllow: onAllow,
        onBlock: onBlock,
      ),
    );
  }

  void showReaderModeSuggestion(
    String tabId, {
    required VoidCallback onOpenReaderMode,
  }) {
    addBanner(
      tabId,
      BrowserBanner.readerModeSuggestion(
        onOpenReaderMode: onOpenReaderMode,
      ),
    );
  }

  void showPopupBlockedBanner(
    String tabId, {
    required String blockedUrl,
    required VoidCallback onAllowOnce,
    VoidCallback? onDismiss,
  }) {
    addBanner(
      tabId,
      BrowserBanner.popupBlocked(
        blockedUrl: blockedUrl,
        onAllowOnce: onAllowOnce,
        onDismiss: onDismiss,
      ),
    );
  }

  // --- Simulation Helpers (For developer testing & user test modal) ---

  void simulateNoNetwork(String tabId, {VoidCallback? onPlayGame, VoidCallback? onRetry}) {
    showNoNetworkBanner(
      tabId,
      onPlayGame: onPlayGame ?? () {},
      onRetry: onRetry ?? () {},
    );
  }

  void simulateSlowNetwork(String tabId, {VoidCallback? onReloadLite}) {
    showSlowNetworkBanner(tabId, onReloadLite: onReloadLite ?? () {});
  }

  void simulatePageError(String tabId, {String? error, VoidCallback? onRetry}) {
    showPageErrorBanner(
      tabId,
      errorDescription: error ?? 'ERR_NAME_NOT_RESOLVED: Server DNS address could not be found.',
      onRetry: onRetry ?? () {},
    );
  }

  void simulateSecurityWarning(String tabId, {String? domain, VoidCallback? onBackToSafety}) {
    addBanner(
      tabId,
      BrowserBanner.securityWarning(
        domain: domain ?? 'paypa1-security-update.com',
        onBackToSafety: onBackToSafety ?? () {},
        onProceedAnyway: () {},
      ),
    );
  }

  void simulateInsecureHttp(String tabId, {VoidCallback? onUpgrade}) {
    addBanner(
      tabId,
      BrowserBanner.insecureHttp(
        onUpgradeHttps: onUpgrade ?? () {},
      ),
    );
  }

  void simulatePermission(String tabId, {PermissionType? type, String? domain}) {
    requestPermission(
      tabId,
      domain: domain ?? 'maps.google.com',
      permission: type ?? PermissionType.location,
      onAllow: () {},
      onBlock: () {},
    );
  }

  void simulateReaderMode(String tabId, {VoidCallback? onOpenReader}) {
    showReaderModeSuggestion(
      tabId,
      onOpenReaderMode: onOpenReader ?? () {},
    );
  }

  void simulatePopupBlocked(String tabId, {String? blockedUrl, VoidCallback? onAllowOnce}) {
    showPopupBlockedBanner(
      tabId,
      blockedUrl: blockedUrl ?? 'https://promo-ad-tracker.net/click?offer=123',
      onAllowOnce: onAllowOnce ?? () {},
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    for (final timer in _slowNetworkTimers.values) {
      timer.cancel();
    }
    _slowNetworkTimers.clear();
    super.dispose();
  }
}
