import 'dart:convert';
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

  /// Extracts clean article text, metadata, URL, and any selected text for Reader Mode and AI Copilot
  static Future<Map<String, String>> extractArticleContent(
    WebViewController controller,
  ) async {
    try {
      const extractionScript = '''
        (function() {
          try {
            var title = document.title || '';
            var h1 = document.querySelector('h1');
            if (h1 && h1.innerText && h1.innerText.trim().length > 0) {
              title = h1.innerText.trim();
            }

            var url = window.location.href || '';
            var metaDesc = '';
            var metaElem = document.querySelector('meta[name="description"]') || document.querySelector('meta[property="og:description"]');
            if (metaElem && metaElem.getAttribute('content')) {
              metaDesc = metaElem.getAttribute('content').trim();
            }

            // Selected text on screen (if user highlighted any text)
            var selection = '';
            if (window.getSelection) {
              selection = window.getSelection().toString().trim();
            }

            // Try to find article or main container, falling back to body
            var container = document.querySelector('article') || document.querySelector('main') || document.querySelector('[role="main"]') || document.body;
            if (!container) {
              container = document.body;
            }

            var clone = container.cloneNode(true);

            // Remove clutter elements: scripts, styles, navigations, footers, headers, ads, cookies
            var toRemove = clone.querySelectorAll('script, style, nav, header, footer, noscript, iframe, aside, svg, .ad, .ads, [class*="ad-"], [id*="ad-"], [class*="cookie"], [id*="cookie"]');
            for (var i = 0; i < toRemove.length; i++) {
              if (toRemove[i].parentNode) {
                toRemove[i].parentNode.removeChild(toRemove[i]);
              }
            }

            var text = clone.innerText || clone.textContent || '';
            text = text.replace(/[\\r\\n\\t]+/g, '\\n').replace(/ {2,}/g, ' ').trim();

            if (text.length > 15000) {
              text = text.substring(0, 15000) + '... [truncated]';
            }

            return JSON.stringify({
              title: title,
              url: url,
              metaDescription: metaDesc,
              selection: selection,
              content: text
            });
          } catch (err) {
            return JSON.stringify({
              title: document.title || 'Web Page',
              url: window.location.href || '',
              metaDescription: '',
              selection: '',
              content: (document.body && (document.body.innerText || document.body.textContent) || '').trim()
            });
          }
        })();
      ''';

      final result = await controller.runJavaScriptReturningResult(extractionScript);
      return parseExtractedJson(result.toString());
    } catch (e) {
      return {
        'title': 'Article Reader',
        'url': '',
        'metaDescription': '',
        'selection': '',
        'content': 'Unable to extract article text from this page.',
      };
    }
  }

  /// Helper to safely parse raw extracted JSON string from webview
  static Map<String, String> parseExtractedJson(String raw) {
    var rawJson = raw.trim();
    if (rawJson.startsWith('"') && rawJson.endsWith('"') && rawJson.length > 1) {
      try {
        rawJson = jsonDecode(rawJson) as String;
      } catch (_) {
        rawJson = rawJson.substring(1, rawJson.length - 1)
            .replaceAll(r'\"', '"')
            .replaceAll(r'\n', '\n')
            .replaceAll(r'\r', '\r')
            .replaceAll(r'\t', '\t')
            .replaceAll(r'\/', '/');
      }
    }

    try {
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final title = (decoded['title'] as String?)?.trim();
      final url = (decoded['url'] as String?)?.trim();
      final metaDescription = (decoded['metaDescription'] as String?)?.trim();
      final selection = (decoded['selection'] as String?)?.trim();
      final content = (decoded['content'] as String?)?.trim();

      return {
        'title': (title != null && title.isNotEmpty) ? title : 'Web Page',
        'url': url ?? '',
        'metaDescription': metaDescription ?? '',
        'selection': selection ?? '',
        'content': content ?? '',
      };
    } catch (_) {
      return {
        'title': 'Web Page',
        'url': '',
        'metaDescription': '',
        'selection': '',
        'content': rawJson,
      };
    }
  }
}
