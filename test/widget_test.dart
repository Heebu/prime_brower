import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prime_brower/main.dart';
import 'package:prime_brower/models/download_item.dart';
import 'package:prime_brower/models/speed_dial_item.dart';
import 'package:prime_brower/services/adblock_filter_service.dart';
import 'package:prime_brower/services/browser_manager.dart';
import 'package:prime_brower/services/download_service.dart';
import 'package:prime_brower/services/shields_service.dart';
import 'package:prime_brower/ui/downloads/downloads_screen.dart';
import 'package:prime_brower/ui/shields/shields_details_sheet.dart';
import 'package:prime_brower/ui/tabs/tab_grid_screen.dart';
import 'package:prime_brower/ui/widgets/omnibox_suggestions_overlay.dart';
import 'package:prime_brower/ui/widgets/browser_menu_sheet.dart';
import 'package:prime_brower/ui/sync/cloud_sync_sheet.dart';
import 'package:prime_brower/services/firebase_auth_service.dart';
import 'package:prime_brower/services/firebase_sync_service.dart';

void main() {
  testWidgets('BrowserApp smoke test with New Tab Start Dashboard', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BrowserApp());
    await tester.pump();

    // Verify search/URL input fields are present (Omnibox + New Tab Dashboard search)
    expect(find.byType(TextField), findsAtLeastNWidgets(1));

    // Verify bottom navigation bar buttons are present
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);

    // Verify Copilot AI button and Cloud Sync are present
    expect(find.text('Copilot'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);

    // Verify New Tab Start Dashboard elements
    expect(find.text('Prime Browser'), findsOneWidget);
    expect(find.text('Prime Shields (Brave Privacy)'), findsOneWidget);
    expect(find.text('Google'), findsNWidgets(2)); // in search engine picker & speed dial
    expect(find.text('YouTube'), findsOneWidget);
  });

  testWidgets('DownloadsScreen smoke test', (WidgetTester tester) async {
    final downloadService = DownloadService();

    await tester.pumpWidget(
      MaterialApp(
        home: DownloadsScreen(downloadService: downloadService),
      ),
    );
    await tester.pump();

    // Verify categories tabs
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Media'), findsOneWidget);
    expect(find.text('Archives'), findsOneWidget);

    // Verify initial empty state
    expect(find.text('No downloads yet'), findsOneWidget);
  });

  testWidgets('ShieldsDetailsSheet smoke test', (WidgetTester tester) async {
    final shieldsService = ShieldsService();
    shieldsService.recordBlockedRequest('https://googleadservices.com/pagead/conversion.js');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShieldsDetailsSheet(
            shieldsService: shieldsService,
            currentUrl: 'https://example.com',
            onReload: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Prime Shields'), findsOneWidget);
    expect(find.text('Total Blocked'), findsOneWidget);
    expect(find.text('Network Requests'), findsOneWidget);
    expect(find.text('example.com'), findsOneWidget);
  });

  test('AdBlockFilterService network domain classification test', () {
    final filter = AdBlockFilterService();

    // Blocked ad & tracker domains
    expect(filter.isAdOrTracker('https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js'), true);
    expect(filter.isAdOrTracker('https://securepubads.g.doubleclick.net/gampad/ads'), true);
    expect(filter.isAdOrTracker('https://connect.facebook.net/en_US/fbevents.js'), true);
    expect(filter.isAdOrTracker('https://criteo.com/delivery/ajs.php'), true);
    expect(filter.isAdOrTracker('https://outbrain.com/widget'), true);
    expect(filter.isAdOrTracker('https://taboola.com/scripts/loader.js'), true);

    // Legitimate domains allowed
    expect(filter.isAdOrTracker('https://flutter.dev'), false);
    expect(filter.isAdOrTracker('https://dart.dev/guides'), false);
    expect(filter.isAdOrTracker('https://en.wikipedia.org/wiki/Flutter'), false);

    // Whitelisting functionality
    filter.whitelistDomain('criteo.com');
    expect(filter.isAdOrTracker('https://criteo.com/delivery/ajs.php'), false);
    filter.removeWhitelistDomain('criteo.com');
    expect(filter.isAdOrTracker('https://criteo.com/delivery/ajs.php'), true);
  });

  test('ShieldsService blocking and metrics test', () {
    final shields = ShieldsService();
    expect(shields.shieldsEnabled, true);

    // Test blocking navigation to ad network
    final shouldAllow = shields.shouldAllowNavigation('https://googleads.g.doubleclick.net/pagead');
    expect(shouldAllow, false);
    expect(shields.networkBlockedCount, 1);
    expect(shields.blockedElementsCount, 1);
    expect(shields.estimatedDataSavedMb > 0, true);
    expect(shields.estimatedTimeSavedSec > 0, true);
    expect(shields.blockedRequests.isNotEmpty, true);
    expect(shields.blockedRequests.first.category, 'Ad Network');

    // Legitimate navigation allowed
    expect(shields.shouldAllowNavigation('https://github.com'), true);
  });

  test('WebTab and BrowserManager Memory Saver (Freeze & Thaw) test', () {
    final shields = ShieldsService();
    final manager = BrowserManager(shieldsService: shields);

    // Manager starts with 1 new tab on prime://newtab
    expect(manager.normalTabs.length, 1);
    expect(manager.normalTabs.first.isFrozen, false);

    // Open second and third tabs
    manager.openNewTab('https://flutter.dev');
    manager.openNewTab('https://dart.dev');
    expect(manager.normalTabs.length, 3);

    // Freeze all inactive tabs
    manager.freezeAllInactiveTabs();

    // Inactive tabs should be frozen, active tab remains awake
    final activeTab = manager.currentTab;
    expect(activeTab?.isFrozen, false);
    expect(manager.frozenTabsCount >= 1, true);
    expect(manager.totalMemorySavedMb >= 42, true);

    // Switching to a frozen tab should automatically thaw it
    final frozenIndex = manager.normalTabs.indexWhere((t) => t.isFrozen);
    if (frozenIndex != -1) {
      manager.switchToTab(frozenIndex);
      expect(manager.normalTabs[frozenIndex].isFrozen, false);
    }
  });

  test('DownloadItem unit tests: categories and size formatting', () {
    final docItem = DownloadItem(
      id: '1',
      url: 'https://example.com/document.pdf',
      fileName: 'document.pdf',
      filePath: '/downloads/document.pdf',
      totalBytes: 2097152, // 2 MB
      downloadedBytes: 1048576, // 1 MB
      createdAt: DateTime.now(),
    );

    expect(docItem.fileExtension, 'pdf');
    expect(docItem.fileCategory, 'Documents');
    expect(docItem.progress, 0.5);
    expect(docItem.formattedTotalSize, '2.0 MB');
    expect(docItem.formattedDownloadedSize, '1.0 MB');

    final mediaItem = DownloadItem(
      id: '2',
      url: 'https://example.com/video.mp4',
      fileName: 'video.mp4',
      filePath: '/downloads/video.mp4',
      totalBytes: 52428800,
      createdAt: DateTime.now(),
    );
    expect(mediaItem.fileCategory, 'Media');

    final zipItem = DownloadItem(
      id: '3',
      url: 'https://example.com/archive.zip',
      fileName: 'archive.zip',
      filePath: '/downloads/archive.zip',
      totalBytes: 1024,
      createdAt: DateTime.now(),
    );
    expect(zipItem.fileCategory, 'Archives');
    expect(zipItem.formattedTotalSize, '1.0 KB');
  });

  test('SpeedDialItem default shortcuts test', () {
    final shortcuts = SpeedDialItem.defaultShortcuts;
    expect(shortcuts.isNotEmpty, true);
    expect(shortcuts.any((s) => s.title == 'Google'), true);
    expect(shortcuts.any((s) => s.title == 'YouTube'), true);
    expect(shortcuts.any((s) => s.title == 'GitHub'), true);
  });

  test('BrowserManager tab organization: pinning, reordering, and adjacent switching', () {
    final shields = ShieldsService();
    final manager = BrowserManager(shieldsService: shields);

    // Initial tab
    expect(manager.normalTabs.length, 1);
    expect(manager.normalTabs.first.isPinned, false);

    // Pin initial tab
    manager.togglePinTab(0);
    expect(manager.normalTabs.first.isPinned, true);

    // Unpin
    manager.togglePinTab(0);
    expect(manager.normalTabs.first.isPinned, false);

    // Open two more tabs
    manager.openNewTab('https://flutter.dev');
    manager.openNewTab('https://dart.dev');
    expect(manager.normalTabs.length, 3);

    // Pin first and third tab
    manager.togglePinTab(0);
    manager.togglePinTab(2);
    expect(manager.normalTabs[0].isPinned, true);
    expect(manager.normalTabs[1].isPinned, false);
    expect(manager.normalTabs[2].isPinned, true);

    // Adjacent tab switching
    manager.switchToTab(1);
    expect(manager.currentTabIndex, 1);
    manager.switchToAdjacentTab(1);
    expect(manager.currentTabIndex, 2);
    manager.switchToAdjacentTab(-1);
    expect(manager.currentTabIndex, 1);

    // Reorder tabs: move index 2 to index 0
    final lastTabUrl = manager.normalTabs[2].url;
    manager.reorderTab(2, 0);
    expect(manager.normalTabs[0].url, lastTabUrl);
  });

  test('BrowserManager search history recording and management', () {
    final shields = ShieldsService();
    final manager = BrowserManager(shieldsService: shields);

    // Clear sample entries first to test clean lifecycle
    manager.clearSearchHistory();
    expect(manager.searchHistory.isEmpty, true);

    // Add search history
    manager.addSearchHistory('flutter animations');
    manager.addSearchHistory('flutter gestures');
    expect(manager.searchHistory.length, 2);
    expect(manager.searchHistory.first, 'flutter gestures');

    // Re-adding existing moves it to top
    manager.addSearchHistory('flutter animations');
    expect(manager.searchHistory.first, 'flutter animations');
    expect(manager.searchHistory.length, 2);

    // Remove specific query
    manager.removeSearchHistory('flutter gestures');
    expect(manager.searchHistory.contains('flutter gestures'), false);

    // Clear all
    manager.clearSearchHistory();
    expect(manager.searchHistory.isEmpty, true);
  });

  testWidgets('OmniboxSuggestionsOverlay smoke test', (WidgetTester tester) async {
    final shields = ShieldsService();
    final manager = BrowserManager(shieldsService: shields);
    manager.addSearchHistory('flutter tutorial');

    String selectedValue = '';
    String filledValue = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OmniboxSuggestionsOverlay(
            browserManager: manager,
            query: 'flutt',
            onSelect: (val) => selectedValue = val,
            onQuickFill: (val) => filledValue = val,
            onDismiss: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify search option for typing query
    expect(find.text('flutt'), findsOneWidget);
    expect(find.text('RECENT SEARCHES'), findsOneWidget);
    expect(find.text('flutter tutorial'), findsOneWidget);

    // Tap search option for typing query
    await tester.tap(find.text('flutt'));
    expect(selectedValue, 'flutt');

    // Tap quick-fill arrow on recent search
    final quickFillIcon = find.byIcon(Icons.north_west_rounded);
    expect(quickFillIcon, findsAtLeastNWidgets(1));
    await tester.tap(quickFillIcon.first);
    expect(filledValue, 'flutt');
  });

  testWidgets('TabGridScreen organizations and filters smoke test', (WidgetTester tester) async {
    final shields = ShieldsService();
    final manager = BrowserManager(shieldsService: shields);
    manager.openNewTab('https://flutter.dev');
    manager.togglePinTab(0); // Pin first tab

    await tester.pumpWidget(
      MaterialApp(
        home: TabGridScreen(browserManager: manager),
      ),
    );
    await tester.pump();

    // Verify search tabs input
    expect(find.byType(TextField), findsOneWidget);

    // Verify organization filter chips
    expect(find.text('All (2)'), findsOneWidget);
    expect(find.text('Pinned (1)'), findsOneWidget);
    expect(find.text('By Domain'), findsOneWidget);
    expect(find.text('PINNED'), findsOneWidget);

    // Switch filter to Pinned
    await tester.tap(find.text('Pinned (1)'));
    await tester.pump();

    // Switch filter to By Domain
    await tester.tap(find.text('By Domain'));
    await tester.pump();
  });

  testWidgets('BrowserMenuSheet smoke test with zero ListTile ink assertions', (WidgetTester tester) async {
    final shields = ShieldsService();
    final manager = BrowserManager(shieldsService: shields);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BrowserMenuSheet(
            browserManager: manager,
            shieldsService: shields,
            onOpenCopilot: () {},
            onFindInPage: () {},
            onOpenSync: () {},
            onOpenDownloads: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify key menu items rendered without framework assertions
    expect(find.text('Prime Cloud Sync'), findsOneWidget);
    expect(find.text('Prime Shields (Brave)'), findsOneWidget);
    expect(find.text('Edge Copilot AI'), findsOneWidget);
    expect(find.text('Find in Page'), findsOneWidget);
    expect(find.text('Inspect Element (Mobile DevTools)'), findsOneWidget);
  });

  testWidgets('CloudSyncSheet smoke test with zero ListTile ink assertions', (WidgetTester tester) async {
    final shields = ShieldsService();
    final auth = FirebaseAuthService();
    final sync = FirebaseSyncService();
    final manager = BrowserManager(shieldsService: shields, authService: auth, syncService: sync);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CloudSyncSheet(
            authService: auth,
            syncService: sync,
            browserManager: manager,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Prime Cloud Sync'), findsOneWidget);
    expect(find.text('Sync Options'), findsOneWidget);
    expect(find.text('Bookmarks & Collections'), findsOneWidget);
    expect(find.text('Open Tabs Mirroring'), findsOneWidget);
  });
}

