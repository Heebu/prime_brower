import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppLinkService {
  static final AppLinkService instance = AppLinkService._internal();

  static const MethodChannel _channel = MethodChannel('com.idris.prime_brower/app_links');

  final StreamController<String> _linkStreamController = StreamController<String>.broadcast();
  Stream<String> get onLinkOpened => _linkStreamController.stream;

  bool _initialized = false;

  AppLinkService._internal() {
    _initChannel();
  }

  void _initChannel() {
    if (_initialized) return;
    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onUrlOpened') {
        final url = call.arguments as String?;
        if (url != null && url.isNotEmpty) {
          debugPrint('AppLinkService: Received incoming link: $url');
          _linkStreamController.add(url);
        }
      }
    });
  }

  /// Checks if the app was cold-started from an external browser intent URL.
  Future<String?> getInitialUrl() async {
    try {
      final url = await _channel.invokeMethod<String>('getInitialUrl');
      if (url != null && url.isNotEmpty) {
        debugPrint('AppLinkService: Cold-start initial URL: $url');
        return url;
      }
    } catch (e) {
      debugPrint('AppLinkService: Error getting initial URL: $e');
    }
    return null;
  }

  /// Opens the Android system prompt or settings to set Prime Browser as the default browser.
  Future<bool> openDefaultBrowserSettings() async {
    try {
      final res = await _channel.invokeMethod<bool>('openDefaultBrowserSettings');
      return res ?? false;
    } catch (e) {
      debugPrint('AppLinkService: Error opening default browser settings: $e');
      return false;
    }
  }

  void dispose() {
    _linkStreamController.close();
  }
}
