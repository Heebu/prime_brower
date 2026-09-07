import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'adblock_filter_service.dart';

class BlockedRequestItem {
  final String url;
  final String domain;
  final String category;
  final DateTime timestamp;

  BlockedRequestItem({
    required this.url,
    required this.domain,
    required this.category,
    required this.timestamp,
  });

  String get shortUrl {
    if (url.length > 50) {
      return '${url.substring(0, 47)}...';
    }
    return url;
  }
}

class ShieldsService with ChangeNotifier {
  final AdBlockFilterService filterService;

  bool _shieldsEnabled = true;
  int _cosmeticBlockedCount = 0;
  int _networkBlockedCount = 0;

  final List<BlockedRequestItem> _blockedRequests = [];

  ShieldsService({AdBlockFilterService? filterService})
      : filterService = filterService ?? AdBlockFilterService();

  bool get shieldsEnabled => _shieldsEnabled;
  int get blockedElementsCount => _cosmeticBlockedCount + _networkBlockedCount;
  int get cosmeticBlockedCount => _cosmeticBlockedCount;
  int get networkBlockedCount => _networkBlockedCount;
  List<BlockedRequestItem> get blockedRequests => List.unmodifiable(_blockedRequests);

  double get estimatedDataSavedMb => blockedElementsCount * 0.165;
  double get estimatedTimeSavedSec => blockedElementsCount * 0.45;

  void toggleShields() {
    _shieldsEnabled = !_shieldsEnabled;
    notifyListeners();
  }

  bool isSiteWhitelisted(String urlOrDomain) {
    return filterService.isWhitelisted(urlOrDomain);
  }

  void toggleSiteExemption(String urlOrDomain) {
    if (isSiteWhitelisted(urlOrDomain)) {
      filterService.removeWhitelistDomain(urlOrDomain);
    } else {
      filterService.whitelistDomain(urlOrDomain);
    }
    notifyListeners();
  }

  /// Network navigation decision filter used by WebTab NavigationDelegate
  bool shouldAllowNavigation(String url) {
    if (!_shieldsEnabled) return true;

    if (filterService.isAdOrTracker(url)) {
      recordBlockedRequest(url);
      return false; // Prevent network navigation to ad / tracker
    }
    return true; // Allow legitimate navigation
  }

  void recordBlockedRequest(String url) {
    String domain = '';
    try {
      domain = Uri.parse(url).host;
    } catch (_) {}

    String category = 'Ad Network';
    final lower = url.toLowerCase();
    if (lower.contains('analytics') || lower.contains('telemetry') || lower.contains('stats') || lower.contains('tracker')) {
      category = 'Tracker / Telemetry';
    } else if (lower.contains('facebook') || lower.contains('twitter') || lower.contains('tiktok')) {
      category = 'Social Tracker';
    }

    _networkBlockedCount++;
    _blockedRequests.insert(
      0,
      BlockedRequestItem(
        url: url,
        domain: domain.isNotEmpty ? domain : url,
        category: category,
        timestamp: DateTime.now(),
      ),
    );

    if (_blockedRequests.length > 100) {
      _blockedRequests.removeLast();
    }

    notifyListeners();
  }

  /// Injects cosmetic CSS stylesheet rules and sub-resource interception hooks
  Future<void> applyShields(WebViewController controller) async {
    if (!_shieldsEnabled) return;

    try {
      const shieldScript = '''
        (function() {
          // 1. Cosmetic Element Blocking & Collapse
          var adSelectors = [
            '.adsbygoogle',
            '[id^="google_ads_"]',
            '[id^="div-gpt-ad"]',
            'iframe[src*="doubleclick"]',
            'iframe[src*="googlesyndication"]',
            'iframe[src*="amazon-adsystem"]',
            '.ad-banner',
            '.ad_banner',
            '.advertisement',
            '[aria-label="advertisement"]',
            '.taboola',
            '.outbrain',
            '#advert',
            '.sponsor-post',
            '.sponsored-content',
            '[data-ad-slot]',
            '.ad-container',
            '#ad-unit'
          ];
          
          var count = 0;
          for (var i = 0; i < adSelectors.length; i++) {
            var elements = document.querySelectorAll(adSelectors[i]);
            count += elements.length;
          }

          var style = document.getElementById('prime-shields-style');
          if (!style) {
            style = document.createElement('style');
            style.id = 'prime-shields-style';
            style.innerHTML = adSelectors.join(', ') + ' { display: none !important; visibility: hidden !important; height: 0 !important; max-height: 0 !important; }';
            document.head.appendChild(style);
          }

          // 2. Client-side Fetch / XHR Sub-resource Request Interceptor
          if (!window.__primeShieldsInjected) {
            window.__primeShieldsInjected = true;
            var blockedDomains = [
              'doubleclick.net', 'googlesyndication.com', 'googleadservices.com',
              'adnxs.com', 'criteo.com', 'taboola.com', 'outbrain.com', 'scorecardresearch.com'
            ];

            var origFetch = window.fetch;
            window.fetch = function(input, init) {
              var url = (typeof input === 'string') ? input : (input ? input.url : '');
              if (url) {
                for (var j = 0; j < blockedDomains.length; j++) {
                  if (url.indexOf(blockedDomains[j]) !== -1) {
                    return Promise.reject(new Error('Blocked by Prime Shields'));
                  }
                }
              }
              return origFetch.apply(this, arguments);
            };

            var origOpen = XMLHttpRequest.prototype.open;
            XMLHttpRequest.prototype.open = function(method, url) {
              if (url) {
                for (var k = 0; k < blockedDomains.length; k++) {
                  if (url.indexOf(blockedDomains[k]) !== -1) {
                    this.abort();
                    return;
                  }
                }
              }
              return origOpen.apply(this, arguments);
            };
          }

          return count;
        })();
      ''';

      final result = await controller.runJavaScriptReturningResult(shieldScript);
      final count = int.tryParse(result.toString()) ?? 0;
      if (count > 0) {
        _cosmeticBlockedCount += count;
        notifyListeners();
      }
    } catch (_) {}
  }
}
