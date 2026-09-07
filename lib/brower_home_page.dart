import 'package:flutter/material.dart';
import 'models/web_tab.dart';
import 'services/browser_manager.dart';
import 'services/shields_service.dart';
import 'services/ai_copilot_service.dart';
import 'services/devtools_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/firebase_sync_service.dart';
import 'services/theme_service.dart';
import 'web_view_page.dart';
import 'ui/widgets/omnibox_app_bar.dart';
import 'ui/widgets/omnibox_suggestions_overlay.dart';
import 'ui/widgets/browser_menu_sheet.dart';
import 'ui/tabs/tab_grid_screen.dart';
import 'ui/copilot/copilot_sheet.dart';
import 'ui/productivity/find_in_page_bar.dart';
import 'ui/sync/cloud_sync_sheet.dart';
import 'ui/downloads/downloads_screen.dart';
import 'ui/shields/shields_details_sheet.dart';
import 'core/design_system/responsive_layout.dart';

class BrowserHomePage extends StatefulWidget {
  const BrowserHomePage({Key? key}) : super(key: key);

  @override
  State<BrowserHomePage> createState() => _BrowserHomePageState();
}

class _BrowserHomePageState extends State<BrowserHomePage> {
  late final ShieldsService _shieldsService;
  late final FirebaseAuthService _authService;
  late final FirebaseSyncService _syncService;
  late final BrowserManager _browserManager;
  late final AiCopilotService _copilotService;
  bool _isFindInPageActive = false;

  late final TextEditingController _omniboxController;
  late final FocusNode _omniboxFocusNode;
  bool _isOmniboxFocused = false;
  String _omniboxQuery = '';

  @override
  void initState() {
    super.initState();
    _shieldsService = ShieldsService();
    _authService = FirebaseAuthService();
    _syncService = FirebaseSyncService();
    _browserManager = BrowserManager(
      shieldsService: _shieldsService,
      authService: _authService,
      syncService: _syncService,
      onDownloadStarted: (url) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Download started in background'),
              action: SnackBarAction(label: 'View', onPressed: _openDownloads),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
    );
    _copilotService = AiCopilotService();

    final tab = _browserManager.currentTab;
    final isNewTab = tab == null || tab.url == 'prime://newtab';
    _omniboxController = TextEditingController(text: isNewTab ? '' : tab.url);
    _omniboxFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _omniboxController.dispose();
    _omniboxFocusNode.dispose();
    super.dispose();
  }

  void _openTabGrid() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TabGridScreen(browserManager: _browserManager),
      ),
    );
  }

  void _openCopilot() async {
    final currentTab = _browserManager.currentTab;
    if (currentTab == null) return;

    String content = '';
    if (!currentTab.isNewTabPage) {
      try {
        final article = await DevToolsService.extractArticleContent(currentTab.controller);
        content = article['content'] ?? '';
      } catch (_) {}
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CopilotSheet(
        copilotService: _copilotService,
        pageTitle: currentTab.isNewTabPage ? 'Prime Start' : currentTab.title,
        pageContent: content,
      ),
    );
  }

  void _openFindInPage() {
    final currentTab = _browserManager.currentTab;
    if (currentTab == null || currentTab.isNewTabPage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Find in Page is available on web pages.')),
      );
      return;
    }
    setState(() => _isFindInPageActive = true);
  }

  void _openSyncSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CloudSyncSheet(
        authService: _authService,
        syncService: _syncService,
        browserManager: _browserManager,
      ),
    );
  }

  void _openDownloads() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DownloadsScreen(downloadService: _browserManager.downloadService),
      ),
    );
  }

  void _openShieldsDetails() {
    final currentTab = _browserManager.currentTab;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShieldsDetailsSheet(
        shieldsService: _shieldsService,
        currentUrl: currentTab?.url ?? '',
        onReload: () => currentTab?.reload(),
      ),
    );
  }

  void _openMenuSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BrowserMenuSheet(
        browserManager: _browserManager,
        shieldsService: _shieldsService,
        onOpenCopilot: _openCopilot,
        onFindInPage: _openFindInPage,
        onOpenSync: _openSyncSheet,
        onOpenDownloads: _openDownloads,
        onOpenShieldsDetails: _openShieldsDetails,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _browserManager,
      builder: (context, _) {
        final currentTab = _browserManager.currentTab;
        final tabs = _browserManager.currentTabs;
        final isIncognito = _browserManager.isIncognito;
        final isDark = isIncognito || ThemeService.instance.isDarkMode(context);

        return PopScope(
          canPop: !_isOmniboxFocused && !_isFindInPageActive,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_isOmniboxFocused) {
              _omniboxFocusNode.unfocus();
              return;
            }
            if (_isFindInPageActive) {
              setState(() => _isFindInPageActive = false);
              return;
            }
          },
          child: Scaffold(
            backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
            appBar: OmniboxAppBar(
              key: ValueKey('omnibox_${currentTab?.id}_$isIncognito'),
              browserManager: _browserManager,
              shieldsService: _shieldsService,
              controller: _omniboxController,
              focusNode: _omniboxFocusNode,
              onOpenTabs: _openTabGrid,
              onFocusChanged: (focused) {
                setState(() {
                  _isOmniboxFocused = focused;
                  if (!focused) {
                    final tab = _browserManager.currentTab;
                    final isNewTab = tab == null || tab.url == 'prime://newtab';
                    _omniboxController.text = isNewTab ? '' : tab.url;
                  }
                });
              },
              onQueryChanged: (query) {
                setState(() {
                  _omniboxQuery = query;
                });
              },
              onOpenMenu: _openMenuSheet,
              onOpenCopilot: _openCopilot,
              onFindInPage: _openFindInPage,
              onOpenSync: _openSyncSheet,
              onOpenShieldsDetails: _openShieldsDetails,
            ),
            body: Stack(
              children: [
                Column(
                  children: [
                    // In-Page Search Overlay
                    if (_isFindInPageActive && currentTab != null)
                      FindInPageBar(
                        controller: currentTab.controller,
                        onClose: () => setState(() => _isFindInPageActive = false),
                      ),

                    // Page Loading Progress Bar
                    if (currentTab != null && currentTab.isLoading && currentTab.progress < 100)
                      LinearProgressIndicator(
                        value: currentTab.progress / 100.0,
                        minHeight: 2.5,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isIncognito ? Colors.deepPurpleAccent : Colors.blueAccent,
                        ),
                      ),

                    // Web View Stack or Empty State
                    Expanded(
                      child: tabs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isIncognito ? Icons.security : Icons.tab_unselected,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    isIncognito ? 'No open incognito tabs' : 'No open tabs',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: isIncognito ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => _browserManager.openNewTab('prime://newtab'),
                                    icon: const Icon(Icons.add),
                                    label: Text(isIncognito ? 'Open Incognito Tab' : 'Open New Tab'),
                                  ),
                                ],
                              ),
                            )
                          : IndexedStack(
                              index: _browserManager.currentTabIndex,
                              children: tabs.map((tab) {
                                return WebViewPage(
                                  key: ValueKey(tab.id),
                                  tab: tab,
                                  browserManager: _browserManager,
                                  shieldsService: _shieldsService,
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),

                // Omnibox Suggestions Overlay
                if (_isOmniboxFocused)
                  Positioned.fill(
                    child: OmniboxSuggestionsOverlay(
                      browserManager: _browserManager,
                      query: _omniboxQuery,
                      onSelect: (urlOrQuery) {
                        _omniboxFocusNode.unfocus();
                        _browserManager.navigateCurrentTab(urlOrQuery);
                      },
                      onQuickFill: (text) {
                        _omniboxController.text = text;
                        _omniboxController.selection = TextSelection.collapsed(offset: text.length);
                        setState(() {
                          _omniboxQuery = text;
                        });
                      },
                      onDismiss: () {
                        _omniboxFocusNode.unfocus();
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}