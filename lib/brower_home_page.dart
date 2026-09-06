import 'package:flutter/material.dart';
import 'models/web_tab.dart';
import 'services/browser_manager.dart';
import 'services/shields_service.dart';
import 'services/ai_copilot_service.dart';
import 'services/devtools_service.dart';
import 'web_view_page.dart';
import 'ui/widgets/omnibox_app_bar.dart';
import 'ui/widgets/bottom_nav_bar.dart';
import 'ui/widgets/browser_menu_sheet.dart';
import 'ui/tabs/tab_grid_screen.dart';
import 'ui/copilot/copilot_sheet.dart';
import 'ui/productivity/find_in_page_bar.dart';
import 'core/design_system/responsive_layout.dart';

class BrowserHomePage extends StatefulWidget {
  const BrowserHomePage({Key? key}) : super(key: key);

  @override
  State<BrowserHomePage> createState() => _BrowserHomePageState();
}

class _BrowserHomePageState extends State<BrowserHomePage> {
  late final ShieldsService _shieldsService;
  late final BrowserManager _browserManager;
  late final AiCopilotService _copilotService;
  bool _isFindInPageActive = false;

  @override
  void initState() {
    super.initState();
    _shieldsService = ShieldsService();
    _browserManager = BrowserManager(shieldsService: _shieldsService);
    _copilotService = AiCopilotService();
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

    final article = await DevToolsService.extractArticleContent(currentTab.controller);
    final content = article['content'] ?? '';

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CopilotSheet(
        copilotService: _copilotService,
        pageTitle: currentTab.title,
        pageContent: content,
      ),
    );
  }

  void _openFindInPage() {
    setState(() => _isFindInPageActive = true);
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

        return Scaffold(
          backgroundColor: isIncognito ? const Color(0xFF121212) : Colors.grey[100],
          appBar: OmniboxAppBar(
            key: ValueKey('omnibox_${currentTab?.id}_$isIncognito'),
            browserManager: _browserManager,
            shieldsService: _shieldsService,
            onOpenMenu: _openMenuSheet,
            onOpenCopilot: _openCopilot,
            onFindInPage: _openFindInPage,
          ),
          body: Column(
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
                              onPressed: () => _browserManager.openNewTab('https://www.google.com'),
                              icon: const Icon(Icons.add),
                              label: Text(isIncognito ? 'Open Incognito Tab' : 'Open New Tab'),
                            ),
                          ],
                        ),
                      )
                    : IndexedStack(
                        index: _browserManager.currentTabIndex,
                        children: tabs.map((tab) {
                          return WebViewPage(key: ValueKey(tab.id), tab: tab);
                        }).toList(),
                      ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavBar(
            browserManager: _browserManager,
            onOpenTabs: _openTabGrid,
            onOpenMenu: _openMenuSheet,
          ),
        );
      },
    );
  }
}