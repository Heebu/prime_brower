import 'dart:async';
import 'package:flutter/material.dart';
import '../models/web_tab.dart';
import '../models/bookmark.dart';
import 'shields_service.dart';
import 'firebase_auth_service.dart';
import 'firebase_sync_service.dart';

import 'download_service.dart';

class BrowserManager with ChangeNotifier {
  final ShieldsService shieldsService;
  final DownloadService downloadService;
  final FirebaseAuthService? authService;
  final FirebaseSyncService? syncService;

  final List<WebTab> _normalTabs = [];
  final List<WebTab> _incognitoTabs = [];
  int _normalTabIndex = 0;
  int _incognitoTabIndex = 0;
  bool _isIncognito = false;

  final List<Bookmark> _bookmarks = [];
  StreamSubscription<List<Bookmark>>? _bookmarksSubscription;

  BrowserManager({
    required this.shieldsService,
    DownloadService? downloadService,
    this.authService,
    this.syncService,
  }) : downloadService = downloadService ?? DownloadService() {
    // Open default initial normal tab on start dashboard
    openNewTab('prime://newtab', incognito: false);
    _initCloudSync();
  }

  void _initCloudSync() {
    authService?.addListener(() {
      final user = authService?.currentUser;
      _bookmarksSubscription?.cancel();
      if (user != null && syncService != null) {
        _bookmarksSubscription = syncService!.streamBookmarks(user.uid).listen((cloudBookmarks) {
          _bookmarks.clear();
          _bookmarks.addAll(cloudBookmarks);
          notifyListeners();
        });
        syncOpenTabsToCloud();
      }
    });
  }

  // Memory Saver (Chrome / Brave Tab Hibernation)
  bool _memorySaverEnabled = true;
  bool get memorySaverEnabled => _memorySaverEnabled;
  int get frozenTabsCount => currentTabs.where((t) => t.isFrozen).length;
  int get totalMemorySavedMb => currentTabs.where((t) => t.isFrozen).fold<int>(0, (sum, t) => sum + t.estimatedMemorySavedMb);

  void toggleMemorySaver() {
    _memorySaverEnabled = !_memorySaverEnabled;
    if (!_memorySaverEnabled) {
      // Thaw all tabs
      for (final t in _normalTabs) {
        t.thaw();
      }
      for (final t in _incognitoTabs) {
        t.thaw();
      }
    }
    notifyListeners();
  }

  void freezeAllInactiveTabs({bool? incognito}) {
    final targetIncognito = incognito ?? _isIncognito;
    final targetList = targetIncognito ? _incognitoTabs : _normalTabs;
    final activeIdx = targetIncognito ? _incognitoTabIndex : _normalTabIndex;

    for (int i = 0; i < targetList.length; i++) {
      if (i != activeIdx && !targetList[i].isNewTabPage) {
        targetList[i].freeze();
      }
    }
    notifyListeners();
  }

  // Getters
  bool get isIncognito => _isIncognito;
  List<WebTab> get normalTabs => List.unmodifiable(_normalTabs);
  List<WebTab> get incognitoTabs => List.unmodifiable(_incognitoTabs);
  int get normalTabIndex => _normalTabIndex;
  int get incognitoTabIndex => _incognitoTabIndex;
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
    if (trimmed.isEmpty || trimmed == 'prime://newtab') return 'prime://newtab';

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
      onFrozenChanged: (_) => notifyListeners(),
      onNavigationRequestFilter: (url) => shieldsService.shouldAllowNavigation(url),
      onPageFinishedCallback: (controller) {
        shieldsService.applyShields(controller);
      },
    );

    final targetList = targetIncognito ? _incognitoTabs : _normalTabs;

    // If Memory Saver is enabled, hibernate older background tabs
    if (_memorySaverEnabled && targetList.length >= 2) {
      for (final oldTab in targetList) {
        if (!oldTab.isNewTabPage) {
          oldTab.freeze();
        }
      }
    }

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

      // Wake up the selected tab if it was hibernating
      final selected = targetList[index];
      if (selected.isFrozen) {
        selected.thaw();
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
    final bookmark = Bookmark(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.isNotEmpty ? title : url,
      url: url,
      createdAt: DateTime.now(),
      isCollection: isCollection,
      collectionName: collectionName,
    );

    _bookmarks.insert(0, bookmark);
    notifyListeners();

    final user = authService?.currentUser;
    if (user != null && syncService != null) {
      syncService!.uploadBookmark(user.uid, bookmark);
    }
  }

  void removeBookmark(String id) {
    _bookmarks.removeWhere((item) => item.id == id);
    notifyListeners();

    final user = authService?.currentUser;
    if (user != null && syncService != null) {
      syncService!.deleteBookmark(user.uid, id);
    }
  }

  void syncOpenTabsToCloud([String deviceName = 'Mobile Device']) {
    final user = authService?.currentUser;
    if (user != null && syncService != null) {
      final tabData = _normalTabs.map((t) => {
        'title': t.title.isNotEmpty ? t.title : 'New Tab',
        'url': t.url,
      }).toList();
      syncService!.syncOpenTabs(user.uid, deviceName, tabData);
    }
  }

  bool isBookmarked(String url) {
    return _bookmarks.any((item) => item.url == url);
  }
}
