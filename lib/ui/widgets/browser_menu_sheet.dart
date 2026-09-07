import 'package:flutter/material.dart';
import '../../services/browser_manager.dart';
import '../../services/devtools_service.dart';
import '../../services/shields_service.dart';
import '../devtools/source_viewer_screen.dart';
import '../devtools/js_console_dialog.dart';
import '../productivity/reader_mode_screen.dart';
import '../productivity/bookmarks_screen.dart';

class BrowserMenuSheet extends StatelessWidget {
  final BrowserManager browserManager;
  final ShieldsService shieldsService;
  final VoidCallback onOpenCopilot;
  final VoidCallback onFindInPage;
  final VoidCallback onOpenSync;
  final VoidCallback onOpenDownloads;
  final VoidCallback? onOpenShieldsDetails;

  const BrowserMenuSheet({
    super.key,
    required this.browserManager,
    required this.shieldsService,
    required this.onOpenCopilot,
    required this.onFindInPage,
    required this.onOpenSync,
    required this.onOpenDownloads,
    this.onOpenShieldsDetails,
  });

  @override
  Widget build(BuildContext context) {
    final currentTab = browserManager.currentTab;
    final isBookmarked = currentTab != null && browserManager.isBookmarked(currentTab.url);
    final isIncognito = browserManager.isIncognito;

    return Material(
      color: isIncognito ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top quick action buttons (Chrome / Edge style)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Back',
                      onPressed: currentTab == null || currentTab.isNewTabPage
                          ? null
                          : () async {
                              final nav = Navigator.of(context);
                              if (await currentTab.canGoBack()) await currentTab.goBack();
                              if (context.mounted) nav.pop();
                            },
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      tooltip: 'Forward',
                      onPressed: currentTab == null || currentTab.isNewTabPage
                          ? null
                          : () async {
                              final nav = Navigator.of(context);
                              if (await currentTab.canGoForward()) await currentTab.goForward();
                              if (context.mounted) nav.pop();
                            },
                    ),
                    IconButton(
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                        color: isBookmarked ? Colors.amber : null,
                      ),
                      tooltip: isBookmarked ? 'Bookmarked' : 'Add Bookmark',
                      onPressed: currentTab == null || currentTab.isNewTabPage
                          ? null
                          : () {
                              final messenger = ScaffoldMessenger.of(context);
                              Navigator.pop(context);
                              if (!isBookmarked) {
                                browserManager.addBookmark(currentTab.title, currentTab.url);
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Added to Bookmarks')),
                                );
                              }
                            },
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Reload',
                      onPressed: currentTab == null || currentTab.isNewTabPage
                          ? null
                          : () {
                              currentTab.reload();
                              Navigator.pop(context);
                            },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Prime Cloud Sync Account tile
              ListTile(
                leading: Icon(
                  browserManager.authService?.isAuthenticated == true
                      ? Icons.cloud_done
                      : Icons.cloud_outlined,
                  color: browserManager.authService?.isAuthenticated == true
                      ? Colors.green
                      : Colors.blueAccent,
                ),
                title: const Text('Prime Cloud Sync'),
                subtitle: Text(
                  browserManager.authService?.isAuthenticated == true
                      ? 'Signed in as ${browserManager.authService?.userDisplayName}'
                      : 'Sign in to sync tabs & bookmarks',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  onOpenSync();
                },
              ),
              const Divider(height: 1),

              // Shields Status tile (Brave style)
              ListTile(
                leading: const Icon(Icons.shield, color: Colors.deepOrangeAccent),
                title: const Text('Prime Shields (Brave)'),
                subtitle: Text(
                  shieldsService.shieldsEnabled
                      ? 'Active • ${shieldsService.blockedElementsCount} trackers & ads blocked'
                      : 'Disabled',
                ),
                trailing: Switch(
                  value: shieldsService.shieldsEnabled,
                  activeColor: Colors.deepOrangeAccent,
                  onChanged: (_) {
                    shieldsService.toggleShields();
                    if (currentTab != null && !currentTab.isNewTabPage && shieldsService.shieldsEnabled) {
                      shieldsService.applyShields(currentTab.controller);
                    }
                  },
                ),
                onTap: onOpenShieldsDetails != null
                    ? () {
                        Navigator.pop(context);
                        onOpenShieldsDetails!();
                      }
                    : null,
              ),

              // Edge Copilot AI Assistant
              ListTile(
                leading: const Icon(Icons.auto_awesome, color: Colors.purple),
                title: const Text('Edge Copilot AI'),
                subtitle: const Text('Summarize page, ask questions, explain simply'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  onOpenCopilot();
                },
              ),
              const Divider(height: 1),

              // Find in Page
              ListTile(
                leading: const Icon(Icons.search, color: Colors.blueGrey),
                title: const Text('Find in Page'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  onFindInPage();
                },
              ),

              // Developer Tools (Inspect Element / Eruda)
              ListTile(
                leading: const Icon(Icons.developer_mode, color: Colors.blueAccent),
                title: const Text('Inspect Element (Mobile DevTools)'),
                subtitle: const Text('DOM tree, CSS editor, Network & Console logs'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);
                  if (currentTab == null || currentTab.isNewTabPage) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Inspect Element is available on web pages.')),
                    );
                    return;
                  }
                  final success = await DevToolsService.injectEruda(currentTab.controller);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Eruda Mobile DevTools launched! Look for the gear icon on screen.'
                            : 'Could not inject DevTools into this page.',
                      ),
                    ),
                  );
                },
              ),

              // View Page Source
              ListTile(
                leading: const Icon(Icons.code, color: Colors.teal),
                title: const Text('View Page Source'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(context);
                  Navigator.pop(context);
                  if (currentTab == null || currentTab.isNewTabPage) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Page source is available on web pages.')),
                    );
                    return;
                  }
                  final html = await DevToolsService.getPageSource(currentTab.controller);
                  nav.push(
                    MaterialPageRoute(
                      builder: (_) => SourceViewerScreen(html: html, url: currentTab.url),
                    ),
                  );
                },
              ),

              // Run JavaScript Console
              ListTile(
                leading: const Icon(Icons.terminal, color: Colors.purple),
                title: const Text('JavaScript Console'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);
                  if (currentTab == null || currentTab.isNewTabPage) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('JavaScript Console is available on web pages.')),
                    );
                    return;
                  }
                  showDialog(
                    context: context,
                    builder: (_) => JsConsoleDialog(controller: currentTab.controller),
                  );
                },
              ),

              const Divider(height: 1),

              // Edge Productivity: Reader Mode
              ListTile(
                leading: const Icon(Icons.article_outlined, color: Colors.indigo),
                title: const Text('Immersive Reader Mode (Edge)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(context);
                  Navigator.pop(context);
                  if (currentTab == null || currentTab.isNewTabPage) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Reader Mode is available on web articles.')),
                    );
                    return;
                  }
                  final article = await DevToolsService.extractArticleContent(currentTab.controller);
                  nav.push(
                    MaterialPageRoute(
                      builder: (_) => ReaderModeScreen(
                        title: article['title'] ?? currentTab.title,
                        content: article['content'] ?? '',
                        url: currentTab.url,
                      ),
                    ),
                  );
                },
              ),

              // Bookmarks & Collections
              ListTile(
                leading: const Icon(Icons.collections_bookmark, color: Colors.amber),
                title: const Text('Bookmarks & Collections'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  final nav = Navigator.of(context);
                  Navigator.pop(context);
                  nav.push(
                    MaterialPageRoute(
                      builder: (_) => BookmarksScreen(browserManager: browserManager),
                    ),
                  );
                },
              ),

              // Downloads Manager
              ListTile(
                leading: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.download_rounded, color: Colors.blueAccent),
                    if (browserManager.downloadService.activeDownloadsCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                          child: Text(
                            '${browserManager.downloadService.activeDownloadsCount}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                title: const Text('Downloads'),
                subtitle: browserManager.downloadService.activeDownloadsCount > 0
                    ? Text('${browserManager.downloadService.activeDownloadsCount} downloading...')
                    : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  onOpenDownloads();
                },
              ),

              // Incognito Tab Action
              ListTile(
                leading: const Icon(Icons.security, color: Colors.black87),
                title: const Text('New Incognito Tab'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  browserManager.openNewTab('prime://newtab', incognito: true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
