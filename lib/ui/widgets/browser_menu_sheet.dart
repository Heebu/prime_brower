import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/browser_manager.dart';
import '../../services/devtools_service.dart';
import '../../services/shields_service.dart';
import '../../services/theme_service.dart';
import '../devtools/source_viewer_screen.dart';
import '../devtools/js_console_dialog.dart';
import '../productivity/reader_mode_screen.dart';
import '../productivity/bookmarks_screen.dart';
import 'notification_settings_sheet.dart';
import 'banner_simulator_sheet.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark || browserManager.isIncognito;

    return Material(
      color: isDark ? const Color(0xFF09090B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top quick action buttons
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
                        color: isBookmarked ? const Color(0xFF10B981) : null,
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

              // Refresh Page Action
              ListTile(
                leading: const Icon(Icons.refresh, color: Color(0xFF10B981)),
                title: const Text('Refresh'),
                subtitle: const Text('Reload current web page'),
                onTap: () {
                  Navigator.pop(context);
                  currentTab?.reload();
                },
              ),
              const Divider(height: 1),

              // Theme Mode Selector Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: AnimatedBuilder(
                  animation: ThemeService.instance,
                  builder: (context, _) {
                    final currentMode = ThemeService.instance.currentMode;
                    final isDarkSheet = isDark;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkSheet ? const Color(0xFF18181B) : const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDarkSheet ? Colors.white12 : Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                currentMode == AppThemeMode.dark
                                    ? Icons.dark_mode_rounded
                                    : (currentMode == AppThemeMode.light
                                        ? Icons.light_mode_rounded
                                        : Icons.brightness_auto_rounded),
                                size: 18,
                                color: const Color(0xFF10B981),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Theme Mode',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkSheet ? Colors.white : Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                currentMode == AppThemeMode.dark
                                    ? 'Dark'
                                    : (currentMode == AppThemeMode.light ? 'Light' : 'System Default'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkSheet ? Colors.white54 : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _buildThemeOption(
                                context: context,
                                label: 'Light',
                                icon: Icons.light_mode_outlined,
                                mode: AppThemeMode.light,
                                isSelected: currentMode == AppThemeMode.light,
                                isDark: isDarkSheet,
                              ),
                              const SizedBox(width: 8),
                              _buildThemeOption(
                                context: context,
                                label: 'Dark',
                                icon: Icons.dark_mode_outlined,
                                mode: AppThemeMode.dark,
                                isSelected: currentMode == AppThemeMode.dark,
                                isDark: isDarkSheet,
                              ),
                              const SizedBox(width: 8),
                              _buildThemeOption(
                                context: context,
                                label: 'System',
                                icon: Icons.brightness_auto_outlined,
                                mode: AppThemeMode.system,
                                isSelected: currentMode == AppThemeMode.system,
                                isDark: isDarkSheet,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),

              // Prime Cloud Sync Account tile
              ListTile(
                leading: Icon(
                  browserManager.authService?.isAuthenticated == true
                      ? Icons.cloud_done
                      : Icons.cloud_outlined,
                  color: const Color(0xFF10B981),
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

              // Shields Status tile
              ListTile(
                leading: const Icon(Icons.shield, color: Color(0xFF10B981)),
                title: const Text('Prime Shields'),
                subtitle: Text(
                  shieldsService.shieldsEnabled
                      ? 'Active • ${shieldsService.blockedElementsCount} trackers & ads blocked'
                      : 'Disabled',
                ),
                trailing: Switch(
                  value: shieldsService.shieldsEnabled,
                  activeColor: const Color(0xFF10B981),
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

              // Pi AI Assistant
              ListTile(
                leading: const Icon(Icons.auto_awesome, color: Color(0xFF10B981)),
                title: const Text('Pi AI'),
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
                leading: const Icon(Icons.search, color: Color(0xFF10B981)),
                title: const Text('Find in Page'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  onFindInPage();
                },
              ),

              // Developer Tools (Inspect Element / Eruda)
              ListTile(
                leading: const Icon(Icons.developer_mode, color: Color(0xFF10B981)),
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
                leading: const Icon(Icons.code, color: Color(0xFF10B981)),
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
                leading: const Icon(Icons.terminal, color: Color(0xFF10B981)),
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

              // Productivity: Reader Mode
              ListTile(
                leading: const Icon(Icons.article_outlined, color: Color(0xFF10B981)),
                title: const Text('Immersive Reader Mode'),
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
                leading: const Icon(Icons.collections_bookmark, color: Color(0xFF10B981)),
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
                    const Icon(Icons.download_rounded, color: Color(0xFF10B981)),
                    if (browserManager.downloadService.activeDownloadsCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
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

              // Notifications & Alerts Manager
              ListTile(
                leading: const Icon(Icons.notifications_outlined, color: Color(0xFF10B981)),
                title: const Text('Notifications & Alerts'),
                subtitle: const Text('Adverts, news feeds, downloads & page loads'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const NotificationSettingsSheet(),
                  );
                },
              ),

              // In-Browser Banners & Alerts
              ListTile(
                leading: const Icon(Icons.announcement_outlined, color: Color(0xFF10B981)),
                title: const Text('Banners & Network Alerts'),
                subtitle: const Text('Slow network, offline runner, security & errors'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  final currentTabId = currentTab?.id ?? 'tab_active';
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => BannerSimulatorSheet(
                      activeTabId: currentTabId,
                      onReloadTab: () => currentTab?.reload(),
                    ),
                  );
                },
              ),

              // Incognito Tab Action
              ListTile(
                leading: Icon(Icons.security, color: isDark ? Colors.white70 : const Color(0xFF09090B)),
                title: const Text('New Incognito Tab'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  browserManager.openNewTab('prime://newtab', incognito: true);
                },
              ),
              const SizedBox(height: 12),

              // Prime Browser Branding Footer
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/app_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Prime Browser',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        color: isDark ? Colors.white54 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String label,
    required IconData icon,
    required AppThemeMode mode,
    required bool isSelected,
    required bool isDark,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          ThemeService.instance.setThemeMode(mode);
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF10B981)
                : (isDark ? Colors.white10 : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF10B981)
                  : (isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.2)),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.grey[700]),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.grey[800]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
