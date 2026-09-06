import 'package:flutter/material.dart';
import '../models/web_tab.dart';
import '../models/bookmark.dart';
import 'shields_service.dart';

class BrowserManager with ChangeNotifier {
  final ShieldsService shieldsService;

  final List<WebTab> _normalTabs = [];
  final List<WebTab> _incognitoTabs = [];
  int _normalTabIndex = 0;
  int _incognitoTabIndex = 0;
  bool _isIncognito = false;

  final List<Bookmark> _bookmarks = [];

  BrowserManager({required this.shieldsService}) {
    // Open default initial normal tab
    openNewTab('https://www.google.com', incognito: false);
  }

  // Getters
  bool get isIncognito => _isIncognito;
  List<WebTab> get normalTabs => List.unmodifiable(_normalTabs);
  List<WebTab> get incognitoTabs => List.unmodifiable(_incognitoTabs);
  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);

  List<WebTab> get currentTabs => _isIncognito ? _incognitoTabs : _normalTabs;
  int get currentTabIndex => _isIncognito ? _incognitoTabIndex : _normalTabIndex;

  WebTab? get currentTab {
    final tabs = currentTabs;
    final index = currentTabIndex;
    if (tabs.isNotEmpty && index >= 0 && index < tabs.length) {
      return tabs[index];
    }
    return null;
  }

  String sanitizeInput(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 'https://www.google.com';

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final hasDomainExtension = RegExp(r'^[a-zA-Z0-9-]+(\.[a-zA-Z]{2,})+').hasMatch(trimmed);
    if (hasDomainExtension && !trimmed.contains(' ')) {
      return 'https://$trimmed';
    }

    // Default to Google search
    return 'https://www.google.com/search?q=${Uri.encodeComponent(trimmed)}';
  }

  void openNewTab(String url, {bool? incognito}) {
    final targetIncognito = incognito ?? _isIncognito;
    final targetUrl = sanitizeInput(url);

    late final WebTab tab;
    tab = WebTab(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      url: targetUrl,
      isIncognito: targetIncognito,
      onUrlChanged: (_) => notifyListeners(),
      onTitleChanged: (_) => notifyListeners(),
      onLoadingChanged: (_) => notifyListeners(),
      onProgressChanged: (_) => notifyListeners(),
      onPageFinishedCallback: (controller) {
        shieldsService.applyShields(controller);
      },
    );

    if (targetIncognito) {
      _incognitoTabs.add(tab);
      _incognitoTabIndex = _incognitoTabs.length - 1;
      _isIncognito = true;
    } else {
      _normalTabs.add(tab);
      _normalTabIndex = _normalTabs.length - 1;
      _isIncognito = false;
    }

    notifyListeners();
  }

  void closeTab(int index, {bool? incognito}) {
    final targetIncognito = incognito ?? _isIncognito;
    final targetList = targetIncognito ? _incognitoTabs : _normalTabs;

    if (index < 0 || index >= targetList.length) return;

    targetList.removeAt(index);

    if (targetIncognito) {
      if (_incognitoTabs.isEmpty) {
        _incognitoTabIndex = 0;
      } else if (_incognitoTabIndex >= _incognitoTabs.length) {
        _incognitoTabIndex = _incognitoTabs.length - 1;
      }
    } else {
      if (_normalTabs.isEmpty) {
        _normalTabIndex = 0;
      } else if (_normalTabIndex >= _normalTabs.length) {
        _normalTabIndex = _normalTabs.length - 1;
      }
    }

    notifyListeners();
  }

  void closeAllTabs({bool? incognito}) {
    final targetIncognito = incognito ?? _isIncognito;
    if (targetIncognito) {
      _incognitoTabs.clear();
      _incognitoTabIndex = 0;
    } else {
      _normalTabs.clear();
      _normalTabIndex = 0;
    }
    notifyListeners();
  }

  void switchToTab(int index, {bool? incognito}) {
    if (incognito != null) {
      _isIncognito = incognito;
    }

    final targetList = _isIncognito ? _incognitoTabs : _normalTabs;
    if (index >= 0 && index < targetList.length) {
      if (_isIncognito) {
        _incognitoTabIndex = index;
      } else {
        _normalTabIndex = index;
      }
      notifyListeners();
    }
  }

  void setIncognitoMode(bool enabled) {
    if (_isIncognito != enabled) {
      _isIncognito = enabled;
      notifyListeners();
    }
  }

  void navigateCurrentTab(String input) {
    final sanitized = sanitizeInput(input);
    final active = currentTab;
    if (active == null) {
      openNewTab(sanitized);
    } else {
      active.loadUrl(sanitized);
      notifyListeners();
    }
  }

  void addBookmark(String title, String url, {bool isCollection = false, String? collectionName}) {
    _bookmarks.insert(
      0,
      Bookmark(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.isNotEmpty ? title : url,
        url: url,
        createdAt: DateTime.now(),
        isCollection: isCollection,
        collectionName: collectionName,
      ),
    );
    notifyListeners();
  }

  void removeBookmark(String id) {
    _bookmarks.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  bool isBookmarked(String url) {
    return _bookmarks.any((item) => item.url == url);
  }
}
