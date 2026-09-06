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

  const BrowserMenuSheet({
    Key? key,
    required this.browserManager,
    required this.shieldsService,
    required this.onOpenCopilot,
    required this.onFindInPage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentTab = browserManager.currentTab;
    final isBookmarked = currentTab != null && browserManager.isBookmarked(currentTab.url);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                      onPressed: currentTab == null
                          ? null
                          : () async {
                              if (await currentTab.canGoBack()) await currentTab.goBack();
                              Navigator.pop(context);
                            },
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      tooltip: 'Forward',
                      onPressed: currentTab == null
                          ? null
                          : () async {
                              if (await currentTab.canGoForward()) await currentTab.goForward();
                              Navigator.pop(context);
                            },
                    ),
                    IconButton(
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                        color: isBookmarked ? Colors.amber : null,
                      ),
                      tooltip: isBookmarked ? 'Bookmarked' : 'Add Bookmark',
                      onPressed: currentTab == null
                          ? null
                          : () {
                              if (!isBookmarked) {
                                browserManager.addBookmark(currentTab.title, currentTab.url);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Added to Bookmarks')),
                                );
                              }
                              Navigator.pop(context);
                            },
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Reload',
                      onPressed: currentTab == null
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
                    if (currentTab != null && shieldsService.shieldsEnabled) {
                      shieldsService.applyShields(currentTab.controller);
                    }
                  },
                ),
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
                  Navigator.pop(context);
                  if (currentTab != null) {
                    final success = await DevToolsService.injectEruda(currentTab.controller);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                            ? 'Eruda Mobile DevTools launched! Look for the gear icon on screen.'
                            : 'Could not inject DevTools into this page.',
                        ),
                      ),
                    );
                  }
                },
              ),

              // View Page Source
              ListTile(
                leading: const Icon(Icons.code, color: Colors.teal),
                title: const Text('View Page Source'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(context);
                  if (currentTab != null) {
                    final html = await DevToolsService.getPageSource(currentTab.controller);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SourceViewerScreen(html: html, url: currentTab.url),
                      ),
                    );
                  }
                },
              ),

              // Run JavaScript Console
              ListTile(
                leading: const Icon(Icons.terminal, color: Colors.purple),
                title: const Text('JavaScript Console'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  if (currentTab != null) {
                    showDialog(
                      context: context,
                      builder: (_) => JsConsoleDialog(controller: currentTab.controller),
                    );
                  }
                },
              ),

              const Divider(height: 1),

              // Edge Productivity: Reader Mode
              ListTile(
                leading: const Icon(Icons.article_outlined, color: Colors.indigo),
                title: const Text('Immersive Reader Mode (Edge)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(context);
                  if (currentTab != null) {
                    final article = await DevToolsService.extractArticleContent(currentTab.controller);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReaderModeScreen(
                          title: article['title'] ?? currentTab.title,
                          content: article['content'] ?? '',
                          url: currentTab.url,
                        ),
                      ),
                    );
                  }
                },
              ),

              // Bookmarks & Collections
              ListTile(
                leading: const Icon(Icons.collections_bookmark, color: Colors.amber),
                title: const Text('Bookmarks & Collections'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookmarksScreen(browserManager: browserManager),
                    ),
                  );
                },
              ),

              // Incognito Tab Action
              ListTile(
                leading: const Icon(Icons.security, color: Colors.black87),
                title: const Text('New Incognito Tab'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  browserManager.openNewTab('https://www.google.com', incognito: true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
