import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ShieldsService with ChangeNotifier {
  bool _shieldsEnabled = true;
  int _blockedElementsCount = 0;

  bool get shieldsEnabled => _shieldsEnabled;
  int get blockedElementsCount => _blockedElementsCount;

  void toggleShields() {
    _shieldsEnabled = !_shieldsEnabled;
    notifyListeners();
  }

  /// Injects cosmetic CSS stylesheet rules into the loaded webpage to collapse ad units and trackers
  Future<void> applyShields(WebViewController controller) async {
    if (!_shieldsEnabled) return;

    try {
      const shieldCss = '''
        (function() {
          var adSelectors = [
            '.adsbygoogle',
            '[id^="google_ads_"]',
            '[id^="div-gpt-ad"]',
            'iframe[src*="doubleclick"]',
            'iframe[src*="googlesyndication"]',
            '.ad-banner',
            '.ad_banner',
            '.advertisement',
            '[aria-label="advertisement"]',
            '.taboola',
            '.outbrain',
            '#advert',
            '.sponsor-post'
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
            style.innerHTML = adSelectors.join(', ') + ' { display: none !important; visibility: hidden !important; height: 0 !important; }';
            document.head.appendChild(style);
          }

          return count;
        })();
      ''';

      final result = await controller.runJavaScriptReturningResult(shieldCss);
      final count = int.tryParse(result.toString()) ?? 0;
      if (count > 0) {
        _blockedElementsCount += count;
        notifyListeners();
      }
    } catch (_) {}
  }
}
