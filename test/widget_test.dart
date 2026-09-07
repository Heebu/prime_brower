import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prime_brower/main.dart';
import 'package:prime_brower/models/download_item.dart';
import 'package:prime_brower/models/speed_dial_item.dart';
import 'package:prime_brower/models/web_tab.dart';
import 'package:prime_brower/services/adblock_filter_service.dart';
import 'package:prime_brower/services/browser_manager.dart';
import 'package:prime_brower/services/download_service.dart';
import 'package:prime_brower/services/shields_service.dart';
import 'package:prime_brower/ui/downloads/downloads_screen.dart';
import 'package:prime_brower/ui/shields/shields_details_sheet.dart';

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
}
