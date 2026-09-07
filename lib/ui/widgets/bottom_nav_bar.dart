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

    final isDark = isIncognito || Theme.of(context).brightness == Brightness.dark;

    return BottomAppBar(
      color: isDark ? const Color(0xFF09090B) : Colors.white,
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
              color: isDark ? Colors.white70 : Colors.black87,
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
              color: isDark ? Colors.white70 : Colors.black87,
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
              color: isDark ? Colors.white70 : Colors.black87,
              onPressed: () => browserManager.navigateCurrentTab('prime://newtab'),
            ),
            // Tab Switcher with live badge
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.layers_outlined, size: 24),
                  tooltip: 'Tabs',
                  color: isDark ? Colors.white70 : Colors.black87,
                  onPressed: onOpenTabs,
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
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
              color: isDark ? Colors.white70 : Colors.black87,
              onPressed: onOpenMenu,
            ),
          ],
        ),
      ),
    );
  }
}
