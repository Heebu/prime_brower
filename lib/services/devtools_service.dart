import 'package:webview_flutter/webview_flutter.dart';

class DevToolsService {
  /// Injects the Eruda Mobile DevTools console into the given WebView
  static Future<bool> injectEruda(WebViewController controller) async {
    try {
      const erudaScript = '''
        (function () {
          if (window.eruda) {
            window.eruda.show();
            return true;
          }
          var script = document.createElement('script');
          script.src = 'https://cdn.jsdelivr.net/npm/eruda';
          script.onload = function () {
            if (window.eruda) {
              window.eruda.init();
              window.eruda.show();
            }
          };
          document.body.appendChild(script);
          return true;
        })();
      ''';
      await controller.runJavaScript(erudaScript);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Extracts the full raw HTML of the current web page
  static Future<String> getPageSource(WebViewController controller) async {
    try {
      final result = await controller.runJavaScriptReturningResult(
        'document.documentElement.outerHTML;',
      );
      // In webview_flutter, result may be formatted as a JSON string
      var html = result.toString();
      if (html.startsWith('"') && html.endsWith('"') && html.length > 1) {
        // Unescape standard JSON string encoding
        html = html
            .substring(1, html.length - 1)
            .replaceAll(r'\"', '"')
            .replaceAll(r'\n', '\n')
            .replaceAll(r'\t', '\t')
            .replaceAll(r'\/', '/');
      }
      return html;
    } catch (e) {
      return '<!-- Error fetching source code: $e -->';
    }
  }

  /// Runs custom JavaScript and returns the output as a String
  static Future<String> executeJavaScript(
    WebViewController controller,
    String script,
  ) async {
    try {
      final result = await controller.runJavaScriptReturningResult(script);
      return result.toString();
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Extracts clean article text and metadata for Reader Mode
  static Future<Map<String, String>> extractArticleContent(
    WebViewController controller,
  ) async {
    try {
      const extractionScript = '''
        (function() {
          var title = document.title || '';
          var h1 = document.querySelector('h1');
          if (h1 && h1.innerText) title = h1.innerText.trim();

          // Try to find article or main container
          var articleElem = document.querySelector('article') || document.querySelector('main') || document.querySelector('[role="main"]') || document.body;
          
          // Clone to prevent modifying the live page
          var clone = articleElem.cloneNode(true);
          
          // Remove scripts, styles, forms, iframes, ads
          var toRemove = clone.querySelectorAll('script, style, nav, header, footer, noscript, iframe, aside, .ads, [class*="ad-"]');
          for (var i = 0; i < toRemove.length; i++) {
            toRemove[i].parentNode.removeChild(toRemove[i]);
          }

          var text = clone.innerText || clone.textContent || '';
          return JSON.stringify({
            title: title,
            content: text.trim()
          });
        })();
      ''';

      final result = await controller.runJavaScriptReturningResult(extractionScript);
      var rawJson = result.toString();
      if (rawJson.startsWith('"') && rawJson.endsWith('"')) {
        rawJson = rawJson.substring(1, rawJson.length - 1)
            .replaceAll(r'\"', '"')
            .replaceAll(r'\n', '\n')
            .replaceAll(r'\/', '/');
      }

      // Simple JSON parser fallback
      return {
        'title': 'Reader Mode',
        'content': rawJson,
      };
    } catch (e) {
      return {
        'title': 'Article Reader',
        'content': 'Unable to extract article text from this page.',
      };
    }
  }
}
