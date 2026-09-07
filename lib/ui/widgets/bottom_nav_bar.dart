import 'package:flutter/material.dart';
import '../../services/browser_manager.dart';

class BottomNavBar extends StatelessWidget {
  final BrowserManager browserManager;
  final VoidCallback onOpenTabs;
  final VoidCallback onOpenMenu;

  const BottomNavBar({
    Key? key,
    required this.browserManager,
    required this.onOpenTabs,
    required this.onOpenMenu,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tab = browserManager.currentTab;
    final isIncognito = browserManager.isIncognito;
    final tabsCount = browserManager.currentTabs.length;

    return BottomAppBar(
      color: isIncognito ? const Color(0xFF1A1A1A) : Colors.white,
      elevation: 8,
      child: SizedBox(
        height: 52,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Back
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              tooltip: 'Back',
              color: isIncognito ? Colors.white70 : null,
              onPressed: tab == null
                  ? null
                  : () async {
                      if (await tab.canGoBack()) await tab.goBack();
                    },
            ),
            // Forward
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 20),
              tooltip: 'Forward',
              color: isIncognito ? Colors.white70 : null,
              onPressed: tab == null
                  ? null
                  : () async {
                      if (await tab.canGoForward()) await tab.goForward();
                    },
            ),
            // Home
            IconButton(
              icon: const Icon(Icons.home_outlined, size: 24),
              tooltip: 'Home',
              color: isIncognito ? Colors.white70 : null,
              onPressed: () => browserManager.navigateCurrentTab('prime://newtab'),
            ),
            // Tab Switcher with live badge
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.layers_outlined, size: 24),
                  tooltip: 'Tabs',
                  color: isIncognito ? Colors.white70 : null,
                  onPressed: onOpenTabs,
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isIncognito ? Colors.deepPurpleAccent : Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$tabsCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Overflow Menu (...)
            IconButton(
              icon: const Icon(Icons.more_vert, size: 24),
              tooltip: 'Menu',
              color: isIncognito ? Colors.white70 : null,
              onPressed: onOpenMenu,
            ),
          ],
        ),
      ),
    );
  }
}
