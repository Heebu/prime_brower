import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prime_brower/main.dart';
import 'package:prime_brower/models/download_item.dart';
import 'package:prime_brower/models/speed_dial_item.dart';
import 'package:prime_brower/services/download_service.dart';
import 'package:prime_brower/ui/downloads/downloads_screen.dart';

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
