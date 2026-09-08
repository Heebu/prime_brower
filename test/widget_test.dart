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
import 'package:prime_brower/ui/widgets/omnibox_app_bar.dart';
import 'package:prime_brower/ui/widgets/omnibox_suggestions_overlay.dart';
import 'package:prime_brower/core/design_system/pull_to_refresh_wrapper.dart';
import 'package:prime_brower/ui/widgets/browser_menu_sheet.dart';
import 'package:prime_brower/ui/sync/cloud_sync_sheet.dart';
import 'package:prime_brower/services/ai_copilot_service.dart';
import 'package:prime_brower/services/firebase_auth_service.dart';
import 'package:prime_brower/services/firebase_sync_service.dart';
import 'package:prime_brower/services/theme_service.dart';
import 'package:prime_brower/services/feed_ad_service.dart';
import 'package:prime_brower/ui/new_tab/new_tab_dashboard.dart';
import 'package:prime_brower/ui/copilot/copilot_sheet.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:prime_brower/services/notification_service.dart';
import 'package:prime_brower/ui/widgets/notification_settings_sheet.dart';
import 'package:prime_brower/models/browser_banner.dart';
import 'package:prime_brower/services/connectivity_banner_service.dart';
import 'package:prime_brower/ui/widgets/browser_banner_widget.dart';
import 'package:prime_brower/ui/widgets/banner_simulator_sheet.dart';
import 'package:prime_brower/ui/offline/prime_runner_screen.dart';
import 'package:prime_brower/ui/auth/auth_dialog.dart';
import 'package:prime_brower/models/feed_item.dart';
import 'package:prime_brower/models/search_suggestion.dart';

void main() {
  testWidgets('BrowserApp smoke test with New Tab Start Dashboard', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BrowserApp());
    await tester.pump();

    // Verify search/URL input fields are present (Omnibox + New Tab Dashboard search)
    expect(find.byType(TextField), findsAtLeastNWidgets(1));

    // Verify top toolbar navigation buttons are present (home, tabs, more)
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);

    // Verify Pi AI button (in Omnibox pill & speed dial)
    expect(find.text('Pi AI'), findsNWidgets(2));

    // Verify New Tab Start Dashboard elements
    expect(find.text('Prime Browser'), findsOneWidget);
    expect(find.text('Prime Privacy Shields'), findsOneWidget);
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
    expect(shortcuts.any((s) => s.title == 'Pi AI'), true);
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
    expect(find.text('Refresh'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsWidgets);
    expect(find.text('Prime Cloud Sync'), findsOneWidget);
    expect(find.text('Prime Shields'), findsOneWidget);
    expect(find.text('Pi AI'), findsOneWidget);
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

  testWidgets('Pi AI Assistant Sheet smoke test with Pi AI branding', (WidgetTester tester) async {
    final copilotService = AiCopilotService();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CopilotSheet(
            copilotService: copilotService,
            pageTitle: 'Test Article',
            pageContent: 'This is an informative test article about advanced Flutter widgets.',
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify Pi AI branding in header, hint, and prompt chips
    expect(find.text('Pi AI Assistant'), findsOneWidget);
    expect(find.text('Ask Pi AI anything about this page...'), findsOneWidget);
    expect(find.text('📌 3-Bullet Summary'), findsOneWidget);

    // Verify external/legacy names are not present
    expect(find.text('Edge Copilot AI'), findsNothing);
  });

  test('AiCopilotService extractive summary Pi AI branding test', () async {
    final copilotService = AiCopilotService();
    final summary = await copilotService.summarize(
      'Flutter is a cross-platform framework for building native mobile applications. It compiles to machine code directly.',
      title: 'Flutter Overview',
    );
    expect(summary.contains('Pi AI'), true);
    expect(summary.contains('Edge Copilot'), false);
    expect(summary.contains('Gemini'), false);
  });

  testWidgets('Top toolbar actions and clean down panel test', (WidgetTester tester) async {
    await tester.pumpWidget(const BrowserApp());
    await tester.pump();

    // Verify top toolbar has Home icon (replacing Cloud Sync), Tabs, and Menu
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);

    // Verify cloud sync icon is not on the top screen
    expect(find.byIcon(Icons.cloud_outlined), findsNothing);

    // Verify down panel (BottomAppBar) is cleared out
    expect(find.byType(BottomAppBar), findsNothing);
  });

  testWidgets('TabGridScreen slide and swipe to close tab test', (WidgetTester tester) async {
    final shields = ShieldsService();
    final manager = BrowserManager(shieldsService: shields);

    // Open a second and third tab
    manager.openNewTab('https://flutter.dev');
    manager.openNewTab('https://dart.dev');
    expect(manager.normalTabs.length, 3);

    // Pin the first tab
    manager.togglePinTab(0);
    expect(manager.normalTabs[0].isPinned, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TabGridScreen(browserManager: manager),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Dismissible widgets are present for all 3 tabs
    expect(find.byType(Dismissible), findsNWidgets(3));

    // Attempt to swipe the pinned tab (first tab) -> should NOT be closed
    final pinnedDismissible = find.byType(Dismissible).first;
    await tester.drag(pinnedDismissible, const Offset(-500, 0));
    await tester.pumpAndSettle();

    // Verify tab is still present and warning SnackBar was displayed
    expect(manager.normalTabs.length, 3);
    expect(find.text('This tab is pinned! Unpin it first to close.'), findsOneWidget);

    // Swipe right (positive X offset) on unpinned tab to close it
    final unpinnedDismissible = find.byType(Dismissible).at(1);
    await tester.drag(unpinnedDismissible, const Offset(500, 0));
    await tester.pumpAndSettle();

    // Verify one tab was closed
    expect(manager.normalTabs.length, 2);
    expect(find.text('Undo'), findsOneWidget);

    // Tap Undo
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    // Tab should be restored
    expect(manager.normalTabs.length, 3);
  });

  test('ThemeService real-time mode switching test', () {
    final themeService = ThemeService.instance;

    // Switch to dark mode
    themeService.setThemeMode(AppThemeMode.dark);
    expect(themeService.currentMode, AppThemeMode.dark);
    expect(themeService.themeMode, ThemeMode.dark);

    // Switch to light mode
    themeService.setThemeMode(AppThemeMode.light);
    expect(themeService.currentMode, AppThemeMode.light);
    expect(themeService.themeMode, ThemeMode.light);

    // Switch to system mode
    themeService.setThemeMode(AppThemeMode.system);
    expect(themeService.currentMode, AppThemeMode.system);
    expect(themeService.themeMode, ThemeMode.system);
  });

  test('FeedAdService per-tab randomization, category filter, and adverts test', () {
    final service = FeedAdService(userDeviceId: 'test_user_device_123');

    // Fetch feed for Tab A and Tab B
    final feedTabA = service.getFeedForTab(tabId: 'tab_alpha');
    final feedTabB = service.getFeedForTab(tabId: 'tab_beta');

    expect(feedTabA.isNotEmpty, isTrue);
    expect(feedTabB.isNotEmpty, isTrue);

    // Verify both feeds contain news and adverts
    expect(feedTabA.any((e) => e.isNews), isTrue);
    expect(feedTabA.any((e) => e.isAd), isTrue);

    // Verify Tab A and Tab B have differing permutations (differ per tab)
    final idsA = feedTabA.map((e) => e.id).toList();
    final idsB = feedTabB.map((e) => e.id).toList();
    expect(idsA, isNot(equals(idsB)));

    // Test Category Filtering
    final techFeed = service.getFeedForTab(tabId: 'tab_alpha', selectedCategory: 'Tech');
    for (final entry in techFeed) {
      if (entry.isNews) {
        expect(entry.news!.category, 'Tech');
      }
    }
  });

  testWidgets('NewTabDashboard feeds, adverts, and shuffle test', (WidgetTester tester) async {
    final shields = ShieldsService();
    final manager = BrowserManager(shieldsService: shields);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NewTabDashboard(
            browserManager: manager,
            shieldsService: shields,
            onNavigate: (_) {},
            tabId: 'tab_test_1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify section header
    expect(find.text('FEEDS & NEWS UPDATES'), findsOneWidget);

    // Verify category filter chips
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Tech'), findsOneWidget);
    expect(find.text('Business'), findsOneWidget);
    expect(find.text('Science'), findsOneWidget);

    // Verify Shuffle button is present
    expect(find.text('Shuffle'), findsOneWidget);

    // Scroll to Shuffle button and tap it
    await tester.ensureVisible(find.text('Shuffle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shuffle'));
    await tester.pumpAndSettle();

    // Verify SnackBar confirmation
    expect(find.text('Feed re-shuffled with fresh stories & updates!'), findsOneWidget);
  });

  testWidgets('BrowserMenuSheet real-time theme mode selector test', (WidgetTester tester) async {
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
    await tester.pumpAndSettle();

    // Verify Theme Mode section is displayed
    expect(find.text('Theme Mode'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);

    // Tap Dark mode option
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(ThemeService.instance.currentMode, AppThemeMode.dark);

    // Tap Light mode option
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(ThemeService.instance.currentMode, AppThemeMode.light);

    // Tap System mode option
    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    expect(ThemeService.instance.currentMode, AppThemeMode.system);
  });

  test('NotificationService tests: news, advert, download, background page alerts & toggles', () async {
    final service = NotificationService.instance;

    expect(service.newsEnabled, true);
    expect(service.advertsEnabled, true);
    expect(service.downloadsEnabled, true);
    expect(service.backgroundPageLoadsEnabled, true);

    // 1. News Notification
    await service.showNewsNotification(
      title: 'Tech Breakthrough',
      body: 'Quantum computing update',
      url: 'https://news.ycombinator.com',
    );
    expect(service.recentNotifications.isNotEmpty, true);
    final newsAlert = service.recentNotifications.first;
    expect(newsAlert.type, NotificationType.news);
    expect(newsAlert.title, 'Tech Breakthrough');
    expect(newsAlert.url, 'https://news.ycombinator.com');

    // 2. Advert Notification
    await service.showAdvertNotification(
      title: 'Summer Sale',
      body: '30% off everything',
      targetUrl: 'https://store.example.com',
    );
    final adAlert = service.recentNotifications.first;
    expect(adAlert.type, NotificationType.advert);
    expect(adAlert.title, 'Summer Sale');
    expect(adAlert.url, 'https://store.example.com');

    // 3. Download Complete Notification
    await service.showDownloadCompleteNotification(
      fileName: 'report.pdf',
      filePath: '/storage/report.pdf',
      bytes: 2097152,
    );
    final downloadAlert = service.recentNotifications.first;
    expect(downloadAlert.type, NotificationType.download);
    expect(downloadAlert.title, 'Download Complete');
    expect(downloadAlert.filePath, '/storage/report.pdf');

    // 4. Background Page Load Notification
    await service.showBackgroundPageLoadedNotification(
      tabId: 'tab_99',
      title: 'Dart Documentation',
      url: 'https://dart.dev',
    );
    final pageAlert = service.recentNotifications.first;
    expect(pageAlert.type, NotificationType.backgroundPage);
    expect(pageAlert.title, 'Dart Documentation');
    expect(pageAlert.tabId, 'tab_99');

    // Test toggles
    service.toggleNewsNotifications();
    expect(service.newsEnabled, false);
    service.toggleNewsNotifications();
    expect(service.newsEnabled, true);

    service.toggleAdvertNotifications();
    expect(service.advertsEnabled, false);
    service.toggleAdvertNotifications();
    expect(service.advertsEnabled, true);
  });

  test('BrowserManager background page load notification trigger test', () {
    final shields = ShieldsService();
    final manager = BrowserManager(shieldsService: shields);

    expect(manager.isAppInBackground, false);
    manager.setAppInBackground(true);
    expect(manager.isAppInBackground, true);

    // Open tab with web url
    manager.openNewTab('https://flutter.dev');
    final tab = manager.currentTab;
    expect(tab, isNotNull);
    expect(tab!.isNewTabPage, false);

    final beforeCount = NotificationService.instance.recentNotifications.length;

    // Simulate page finish when app is in background
    manager.notifyPageFinished(tab);

    final afterCount = NotificationService.instance.recentNotifications.length;
    expect(afterCount, beforeCount + 1);
    expect(NotificationService.instance.recentNotifications.first.type, NotificationType.backgroundPage);
    expect(NotificationService.instance.recentNotifications.first.url, 'https://flutter.dev');

    // App back in foreground
    manager.setAppInBackground(false);
    expect(manager.isAppInBackground, false);
  });

  testWidgets('NotificationSettingsSheet smoke & interaction test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NotificationSettingsSheet(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('Notifications & Alerts'), findsOneWidget);
    expect(find.text('FCM push alerts & background notifications'), findsOneWidget);

    // Verify Preferences List
    expect(find.text('News & Breaking Stories'), findsOneWidget);
    expect(find.text('Promotions & Adverts'), findsOneWidget);
    expect(find.text('Download Complete Alerts'), findsOneWidget);
    expect(find.text('Background Page Ready Alerts'), findsOneWidget);

    // Verify Test Action Chips
    expect(find.text('Test News Alert'), findsOneWidget);
    expect(find.text('Test Advert Alert'), findsOneWidget);
    expect(find.text('Test Download Alert'), findsOneWidget);
    expect(find.text('Test Background Load'), findsOneWidget);

    // Tap Test News Alert
    await tester.ensureVisible(find.text('Test News Alert'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test News Alert'));
    await tester.pumpAndSettle();
    expect(find.text('Sent News Alert notification'), findsOneWidget);
    expect(NotificationService.instance.recentNotifications.first.type, NotificationType.news);

    // Tap Test Advert Alert
    await tester.ensureVisible(find.text('Test Advert Alert'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test Advert Alert'));
    await tester.pumpAndSettle();
    expect(find.text('Sent Advert Alert notification'), findsOneWidget);
    expect(NotificationService.instance.recentNotifications.first.type, NotificationType.advert);
  });

  testWidgets('BrowserMenuSheet notifications tile navigation test', (WidgetTester tester) async {
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
    await tester.pumpAndSettle();

    // Verify Notifications & Alerts tile is in menu
    expect(find.text('Notifications & Alerts'), findsOneWidget);
    expect(find.text('Adverts, news feeds, downloads & page loads'), findsOneWidget);

    // Scroll to it if needed and tap
    await tester.ensureVisible(find.text('Notifications & Alerts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notifications & Alerts'));
    await tester.pumpAndSettle();

    // Verify NotificationSettingsSheet modal is opened
    expect(find.byType(NotificationSettingsSheet), findsOneWidget);
  });

  test('ConnectivityBannerService unit tests: offline, slow network, page error, scam warning, insecure HTTP, permissions', () {
    final service = ConnectivityBannerService.instance;
    const tabId = 'test_banner_tab';

    service.clearBanners(tabId);
    expect(service.getBannersForTab(tabId).isEmpty, true);

    // 1. No Network Banner
    bool retryCalled = false;
    bool gameCalled = false;
    service.showNoNetworkBanner(
      tabId,
      onRetry: () => retryCalled = true,
      onPlayGame: () => gameCalled = true,
    );
    expect(service.getBannersForTab(tabId).length, 1);
    final noNetBanner = service.getBannersForTab(tabId).first;
    expect(noNetBanner.type, BannerType.noNetwork);
    expect(noNetBanner.title, 'No Internet Connection');
    expect(noNetBanner.primaryActionLabel, 'Play Game');
    expect(noNetBanner.secondaryActionLabel, 'Retry');

    noNetBanner.onPrimaryAction?.call();
    noNetBanner.onSecondaryAction?.call();
    expect(gameCalled, true);
    expect(retryCalled, true);

    // 2. Slow Network Banner
    bool reloadLiteCalled = false;
    service.showSlowNetworkBanner(tabId, onReloadLite: () => reloadLiteCalled = true);
    final slowBanner = service.getBannersForTab(tabId).firstWhere((b) => b.type == BannerType.slowNetwork);
    expect(slowBanner.title, 'Slow Network Connection');
    expect(slowBanner.primaryActionLabel, 'Reload Lite');
    slowBanner.onPrimaryAction?.call();
    expect(reloadLiteCalled, true);

    // 3. Page Error Banner
    service.showPageErrorBanner(
      tabId,
      errorDescription: 'ERR_NAME_NOT_RESOLVED: Server DNS error',
      onRetry: () {},
    );
    final errBanner = service.getBannersForTab(tabId).firstWhere((b) => b.type == BannerType.pageError);
    expect(errBanner.title, 'Page Load Failed');
    expect(errBanner.message, contains('ERR_NAME_NOT_RESOLVED'));

    // 4. Scam / Security Warning
    bool backToSafetyCalled = false;
    final isSafe = service.evaluateUrlSecurity(
      tabId,
      'https://paypa1-security-verify.com/login',
      onBackToSafety: () => backToSafetyCalled = true,
    );
    expect(isSafe, false);
    final scamBanner = service.getBannersForTab(tabId).firstWhere((b) => b.type == BannerType.securityWarning);
    expect(scamBanner.title, 'Deceptive Site / Privacy Risk');
    expect(scamBanner.primaryActionLabel, 'Back to Safety');
    scamBanner.onPrimaryAction?.call();
    expect(backToSafetyCalled, true);

    // 5. Insecure HTTP Warning
    service.checkInsecureHttp(
      tabId,
      'http://insecure-example.org',
      onUpgradeHttps: () {},
    );
    final httpBanner = service.getBannersForTab(tabId).firstWhere((b) => b.type == BannerType.insecureHttp);
    expect(httpBanner.title, 'Not Secure (HTTP)');
    expect(httpBanner.primaryActionLabel, 'Use HTTPS');

    // 6. Permission Request Banner
    bool allowCalled = false;
    bool blockCalled = false;
    service.requestPermission(
      tabId,
      domain: 'maps.google.com',
      permission: PermissionType.location,
      onAllow: () => allowCalled = true,
      onBlock: () => blockCalled = true,
    );
    final permBanner = service.getBannersForTab(tabId).firstWhere((b) => b.type == BannerType.permission);
    expect(permBanner.title, 'Permission Request');
    expect(permBanner.message, contains('Location'));
    permBanner.onPrimaryAction?.call();
    permBanner.onSecondaryAction?.call();
    expect(allowCalled, true);
    expect(blockCalled, true);

    // 7. Clear banners
    service.clearBanners(tabId);
    expect(service.getBannersForTab(tabId).isEmpty, true);
  });

  testWidgets('BrowserBannerWidget smoke and interaction test', (WidgetTester tester) async {
    bool primaryClicked = false;
    bool dismissClicked = false;

    final banner = BrowserBanner(
      id: 'test_banner',
      type: BannerType.slowNetwork,
      title: 'Slow Network Alert',
      message: 'Page is loading slowly. Tap to reload lite version.',
      icon: Icons.speed_rounded,
      accentColor: const Color(0xFFFB923C),
      primaryActionLabel: 'Reload Lite',
      onPrimaryAction: () => primaryClicked = true,
      secondaryActionLabel: 'Wait',
      onDismiss: () => dismissClicked = true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BrowserBannerWidget(
            banner: banner,
            onDismiss: () => dismissClicked = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify UI components
    expect(find.text('Slow Network Alert'), findsOneWidget);
    expect(find.text('Page is loading slowly. Tap to reload lite version.'), findsOneWidget);
    expect(find.text('Reload Lite'), findsOneWidget);
    expect(find.text('Wait'), findsOneWidget);

    // Tap Primary Action
    await tester.tap(find.text('Reload Lite'));
    await tester.pump();
    expect(primaryClicked, true);

    // Tap Dismiss button (close icon)
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(dismissClicked, true);
  });

  testWidgets('PrimeRunnerScreen interactive offline mini-game test', (WidgetTester tester) async {
    bool retryCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: PrimeRunnerScreen(
          isOnline: false,
          onRetryConnection: () => retryCalled = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial game elements
    expect(find.text('PRIME CYBER RUNNER'), findsNWidgets(2)); // HUD & Ready Overlay
    expect(find.text('Offline Mode'), findsOneWidget);
    expect(find.text('SCORE: 0'), findsOneWidget);
    expect(find.text('START RUN'), findsOneWidget);

    // Tap START RUN
    await tester.tap(find.text('START RUN'));
    await tester.pump();

    // Jump by tapping on the game area
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump(const Duration(milliseconds: 100));

    // Tap Reload button on top bar
    await tester.tap(find.text('Reload'));
    await tester.pump();
    expect(retryCalled, true);
  });

  testWidgets('BrowserMenuSheet Banners & Network Alerts navigation test', (WidgetTester tester) async {
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
    await tester.pumpAndSettle();

    // Verify Banners & Network Alerts tile is in menu
    expect(find.text('Banners & Network Alerts'), findsOneWidget);
    expect(find.text('Slow network, offline runner, security & errors'), findsOneWidget);

    // Scroll to it and tap
    await tester.ensureVisible(find.text('Banners & Network Alerts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Banners & Network Alerts'));
    await tester.pumpAndSettle();

    // Verify BannerSimulatorSheet modal is opened
    expect(find.byType(BannerSimulatorSheet), findsOneWidget);
    expect(find.text('Prime Cyber Runner'), findsOneWidget);
    expect(find.text('No Network Banner'), findsOneWidget);
    expect(find.text('Slow Network Banner'), findsOneWidget);
    expect(find.text('Page Error Banner'), findsOneWidget);
    expect(find.text('Scam / Security Warning'), findsOneWidget);

    // Tap No Network Banner chip
    await tester.tap(find.text('No Network Banner'));
    await tester.pumpAndSettle();

    // Verify banner was registered for the active tab
    final banners = ConnectivityBannerService.instance.getBannersForTab(manager.currentTab!.id);
    expect(banners.any((b) => b.type == BannerType.noNetwork), true);
  });

  test('FCM background message handler can be invoked safely', () async {
    const message = RemoteMessage(
      messageId: 'test_fcm_bg_999',
      data: {'type': 'advert', 'title': 'Flash Sale', 'url': 'https://deal.com'},
    );
    // Ensure background handler processes without unhandled exceptions
    await firebaseMessagingBackgroundHandler(message);
    expect(message.messageId, 'test_fcm_bg_999');
  });

  testWidgets('Pop-up Blocked banner registration and interaction test', (WidgetTester tester) async {
    bool allowOnceTriggered = false;
    final banner = BrowserBanner.popupBlocked(
      blockedUrl: 'https://deceptive-popup.com/ad',
      onAllowOnce: () => allowOnceTriggered = true,
    );

    expect(banner.type, BannerType.popupBlocked);
    expect(banner.title, 'Pop-up Window Blocked');
    expect(banner.message.contains('deceptive-popup.com'), true);
    expect(banner.primaryActionLabel, 'Allow Once');
    expect(banner.secondaryActionLabel, 'Dismiss');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BrowserBannerWidget(
            banner: banner,
            onDismiss: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pop-up Window Blocked'), findsOneWidget);
    expect(find.text('Allow Once'), findsOneWidget);

    await tester.tap(find.text('Allow Once'));
    await tester.pump();
    expect(allowOnceTriggered, true);
  });

  test('BrowserManager onNavigationRequestFilter triggers popupBlocked banner', () {
    final shields = ShieldsService();
    final manager = BrowserManager(shieldsService: shields);
    final activeTab = manager.currentTab!;

    // Ad/tracker URL that is blocked by shields
    const blockedAdUrl = 'https://googleads.g.doubleclick.net/pagead/ads';
    final allowed = activeTab.onNavigationRequestFilter?.call(blockedAdUrl);

    expect(allowed, false);
    final banners = ConnectivityBannerService.instance.getBannersForTab(activeTab.id);
    expect(banners.any((b) => b.type == BannerType.popupBlocked), true);
    final popupBanner = banners.firstWhere((b) => b.type == BannerType.popupBlocked);
    expect(popupBanner.message.contains('doubleclick.net'), true);
  });

  testWidgets('PullToRefreshWrapper drag-down gesture triggers reload', (WidgetTester tester) async {
    bool refreshed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PullToRefreshWrapper(
            canRefresh: () => true,
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 50));
              refreshed = true;
            },
            child: ListView(
              children: const [
                SizedBox(height: 200, child: Text('Page Content at Top')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Pull down by 150 pixels from top
    await tester.drag(find.text('Page Content at Top'), const Offset(0, 150));
    await tester.pump();

    // Verify refresh indicator disc is displayed
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

    // Let the refresh complete
    await tester.pumpAndSettle();
    expect(refreshed, true);
  });

  testWidgets('PullToRefreshWrapper does not trigger when canRefresh is false', (WidgetTester tester) async {
    bool refreshed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PullToRefreshWrapper(
            canRefresh: () => false,
            onRefresh: () async {
              refreshed = true;
            },
            child: ListView(
              children: const [
                SizedBox(height: 200, child: Text('Scrolled Down Content')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.text('Scrolled Down Content'), const Offset(0, 150));
    await tester.pumpAndSettle();

    expect(refreshed, false);
  });

  testWidgets('Swipe down from top of app bar moves to all tabs', (WidgetTester tester) async {
    bool tabsOpened = false;
    final shields = ShieldsService();
    final manager = BrowserManager(shieldsService: shields);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: OmniboxAppBar(
            browserManager: manager,
            shieldsService: shields,
            onOpenMenu: () {},
            onOpenCopilot: () {},
            onFindInPage: () {},
            onOpenSync: () {},
            onOpenTabs: () {
              tabsOpened = true;
            },
          ),
          body: const Center(child: Text('Web Browser Body')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Swipe down on the Omnibox / top app bar
    await tester.drag(find.byType(OmniboxAppBar), const Offset(0, 80));
    await tester.pump();

    expect(tabsOpened, true);
  });

  testWidgets('Swipe horizontal across app bar switches adjacent tabs', (WidgetTester tester) async {
    final shields = ShieldsService();
    final manager = BrowserManager(shieldsService: shields);
    manager.openNewTab('https://flutter.dev');
    expect(manager.currentTabIndex, 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: OmniboxAppBar(
            browserManager: manager,
            shieldsService: shields,
            onOpenMenu: () {},
            onOpenCopilot: () {},
            onFindInPage: () {},
            onOpenSync: () {},
            onOpenTabs: () {},
          ),
          body: const Center(child: Text('Body')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Swipe left to right (positive delta) -> previous tab (index 0)
    await tester.drag(find.byType(OmniboxAppBar), const Offset(80, 0));
    await tester.pumpAndSettle();

    expect(manager.currentTabIndex, 0);
  });

  testWidgets('OmniboxAppBar programmatic URL update does not trigger setState during build', (WidgetTester tester) async {
    final shields = ShieldsService();
    final manager = BrowserManager(shieldsService: shields);
    final controller = TextEditingController(text: '');
    final focusNode = FocusNode();
    bool setStateCalledDuringBuild = false;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              appBar: OmniboxAppBar(
                browserManager: manager,
                shieldsService: shields,
                controller: controller,
                focusNode: focusNode,
                onQueryChanged: (query) {
                  // If triggered during build/didUpdateWidget, this will throw or flag
                  setState(() {
                    setStateCalledDuringBuild = true;
                  });
                },
                onOpenMenu: () {},
                onOpenCopilot: () {},
                onFindInPage: () {},
                onOpenSync: () {},
                onOpenTabs: () {},
              ),
              body: const Center(child: Text('Content')),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Now update the tab's URL (similar to page load completing to scholarshipregion.com)
    final currentTab = manager.currentTab;
    expect(currentTab, isNotNull);
    currentTab!.url = 'https://www.scholarshipregion.com/';

    // Trigger rebuild of the parent widget to invoke didUpdateWidget on OmniboxAppBar
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              appBar: OmniboxAppBar(
                browserManager: manager,
                shieldsService: shields,
                controller: controller,
                focusNode: focusNode,
                onQueryChanged: (query) {
                  setState(() {
                    setStateCalledDuringBuild = true;
                  });
                },
                onOpenMenu: () {},
                onOpenCopilot: () {},
                onFindInPage: () {},
                onOpenSync: () {},
                onOpenTabs: () {},
              ),
              body: const Center(child: Text('Content')),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The omnibox controller should reflect the updated URL
    expect(controller.text, 'https://www.scholarshipregion.com/');
    // Crucially, onQueryChanged should NOT have triggered setState during build
    expect(setStateCalledDuringBuild, false);
  });

  test('FirebaseAuthService guest defaults and validation test', () {
    final authService = FirebaseAuthService();
    expect(authService.isAuthenticated, false);
    expect(authService.currentUser, isNull);
    expect(authService.userDisplayName, 'Guest');
    expect(authService.userEmail, 'Not signed in');
    expect(authService.isGoogleUser, false);
    expect(authService.userPhotoUrl, isNull);
  });

  testWidgets('AuthDialog smoke test with Email/Password, Forgot Password, and Google Sign-in', (WidgetTester tester) async {
    final authService = FirebaseAuthService();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => AuthDialog(authService: authService),
                ),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open AuthDialog
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Verify all essential authentication options are present
    expect(find.text('Prime Cloud Sync'), findsOneWidget);
    expect(find.text('Sign In'), findsNWidgets(2)); // Switcher pill and submit button
    expect(find.text('Create Account'), findsOneWidget); // Switcher pill
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('1-Tap Guest Sign-in (Test Mode)'), findsOneWidget);

    // Switch to Create Account mode
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    // Forgot password link should NOT be present in Create Account mode
    expect(find.text('Forgot password?'), findsNothing);
    expect(find.text('Create Account'), findsNWidgets(2)); // Switcher pill and submit button

    // Switch back to Sign In mode
    await tester.tap(find.text('Sign In').first);
    await tester.pumpAndSettle();

    expect(find.text('Forgot password?'), findsOneWidget);
  });

  test('Firebase news item serialization and FeedAdService Firestore data prioritization test', () {
    // 1. Verify NewsFeedItem fromMap & toMap serialization
    final now = DateTime.now();
    final itemMap = {
      'title': 'Breakthrough Quantum Processor Operates at Ambient Temperature',
      'description': 'Researchers unveil room-temperature qubit architecture.',
      'source': 'TechCrunch',
      'url': 'https://techcrunch.com',
      'imageUrl': 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=800',
      'category': 'Tech',
      'readTimeMinutes': 4,
      'publishedAt': now.millisecondsSinceEpoch,
    };

    final parsedItem = NewsFeedItem.fromMap(itemMap, 'news_test_01');
    expect(parsedItem.id, 'news_test_01');
    expect(parsedItem.title, 'Breakthrough Quantum Processor Operates at Ambient Temperature');
    expect(parsedItem.category, 'Tech');
    expect(parsedItem.source, 'TechCrunch');
    expect(parsedItem.readTimeMinutes, 4);

    final serializedMap = parsedItem.toMap();
    expect(serializedMap['title'], parsedItem.title);
    expect(serializedMap['category'], 'Tech');

    // 2. Verify FeedAdService prioritization when Firestore news is available
    final service = FeedAdService(userDeviceId: 'device_firestore_priority_test');
    expect(service.isUsingFirestoreNews, isFalse);

    // Initial feed without Firestore news uses curated fallback defaults
    final defaultFeed = service.getFeedForTab(tabId: 'tab_home');
    expect(defaultFeed.isNotEmpty, isTrue);
    expect(defaultFeed.any((e) => e.isNews), isTrue);

    // Getters verification
    expect(service.firestoreNewsCount, 0);
    expect(service.firestoreNews.isEmpty, isTrue);
  });

  test('SearchSuggestion model serialization and properties test', () {
    final map = {
      'query': 'Flutter 3.44 official documentation',
      'category': 'Development',
      'targetUrl': 'https://docs.flutter.dev',
      'popularity': 99,
    };

    final suggestion = SearchSuggestion.fromMap('sug_flutter_docs', map);
    expect(suggestion.id, 'sug_flutter_docs');
    expect(suggestion.query, 'Flutter 3.44 official documentation');
    expect(suggestion.category, 'Development');
    expect(suggestion.targetUrl, 'https://docs.flutter.dev');
    expect(suggestion.popularity, 99);

    final serialized = suggestion.toMap();
    expect(serialized['query'], suggestion.query);
    expect(serialized['category'], 'Development');
    expect(serialized['targetUrl'], 'https://docs.flutter.dev');
    expect(serialized['popularity'], 99);

    // Equality test
    final identicalSuggestion = SearchSuggestion.fromMap('sug_flutter_docs', map);
    expect(suggestion, equals(identicalSuggestion));
  });

  test('FirebaseSyncService suggestions, search history, and browsing history methods test', () async {
    final syncService = FirebaseSyncService();
    expect(syncService.deviceId.isNotEmpty, isTrue);
    expect(syncService.cachedSuggestions.isEmpty, isTrue);

    // Verify stream fallbacks when Firebase is offline / uninitialized in test
    final suggestionsStream = syncService.streamSearchSuggestions();
    expect(suggestionsStream, isNotNull);

    final searchStream = syncService.streamSearchHistory(uid: 'test_user_123');
    expect(searchStream, isNotNull);

    final browsingStream = syncService.streamBrowsingHistory(uid: 'test_user_123');
    expect(browsingStream, isNotNull);

    // Verify graceful execution of save/delete/clear without throwing
    await syncService.saveSearchHistory(uid: 'test_user_123', query: 'Quantum computing');
    await syncService.deleteSearchHistory(uid: 'test_user_123', query: 'Quantum computing');
    await syncService.clearSearchHistory(uid: 'test_user_123');

    await syncService.saveBrowsingHistory(uid: 'test_user_123', title: 'TechCrunch', url: 'https://techcrunch.com');
    await syncService.deleteBrowsingHistory(uid: 'test_user_123', url: 'https://techcrunch.com');
    await syncService.clearBrowsingHistory(uid: 'test_user_123');
  });

  testWidgets('OmniboxSuggestionsOverlay renders backend suggestions and handles selection', (WidgetTester tester) async {
    final shieldsService = ShieldsService();
    final browserManager = BrowserManager(shieldsService: shieldsService);

    // Populate initial search history and browsing history
    browserManager.addSearchHistory('Flutter animations');
    browserManager.recordBrowsingHistory('GitHub', 'https://github.com');

    String selectedResult = '';
    String quickFilledResult = '';

    // 1. Test empty query (Dashboard focus)
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OmniboxSuggestionsOverlay(
            browserManager: browserManager,
            query: '',
            onSelect: (val) => selectedResult = val,
            onQuickFill: (val) => quickFilledResult = val,
            onDismiss: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Recent Searches and Visited Pages headers
    expect(find.text('RECENT SEARCHES'), findsOneWidget);
    expect(find.text('Flutter animations'), findsOneWidget);
    expect(find.text('Clear All'), findsAtLeastNWidgets(1));

    // Tap quick-fill on recent search
    final quickFillButtons = find.byIcon(Icons.north_west_rounded);
    expect(quickFillButtons, findsAtLeastNWidgets(1));
    await tester.tap(quickFillButtons.first);
    expect(quickFilledResult, 'Flutter animations');

    // Tap on the tile to select
    await tester.tap(find.text('Flutter animations'));
    expect(selectedResult, 'Flutter animations');

    // 2. Test typed query matching web search direct action
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OmniboxSuggestionsOverlay(
            browserManager: browserManager,
            query: 'dart',
            onSelect: (val) => selectedResult = val,
            onQuickFill: (val) => quickFilledResult = val,
            onDismiss: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Search web for "dart"'), findsOneWidget);
    await tester.tap(find.text('Search web for "dart"'));
    expect(selectedResult, 'dart');
  });
}




