import 'package:flutter/material.dart';
import '../../services/browser_manager.dart';
import '../../core/design_system/responsive_layout.dart';
import '../../core/design_system/animated_pressable.dart';

class TabGridScreen extends StatefulWidget {
  final BrowserManager browserManager;

  const TabGridScreen({Key? key, required this.browserManager}) : super(key: key);

  @override
  State<TabGridScreen> createState() => _TabGridScreenState();
}

class _TabGridScreenState extends State<TabGridScreen> {
  late bool _showingIncognito;

  @override
  void initState() {
    super.initState();
    _showingIncognito = widget.browserManager.isIncognito;
  }

  @override
  Widget build(BuildContext context) {
    final manager = widget.browserManager;
    final tabs = _showingIncognito ? manager.incognitoTabs : manager.normalTabs;
    final activeIndex = _showingIncognito ? manager.incognitoTabIndex : manager.normalTabIndex;
    final isDark = _showingIncognito;

    return Theme(
      data: isDark ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          elevation: 1,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModeTab(
                icon: Icons.tab,
                label: '${manager.normalTabs.length}',
                isActive: !_showingIncognito,
                onTap: () => setState(() => _showingIncognito = false),
              ),
              const SizedBox(width: 8),
              _buildModeTab(
                icon: Icons.security,
                label: '${manager.incognitoTabs.length}',
                isActive: _showingIncognito,
                onTap: () => setState(() => _showingIncognito = true),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'New Tab',
              onPressed: () {
                manager.openNewTab('https://www.google.com', incognito: _showingIncognito);
                Navigator.pop(context);
              },
            ),
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'close_all') {
                  manager.closeAllTabs(incognito: _showingIncognito);
                  setState(() {});
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'close_all',
                  child: Text(_showingIncognito ? 'Close all incognito tabs' : 'Close all tabs'),
                ),
              ],
            ),
          ],
        ),
        body: tabs.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _showingIncognito ? Icons.security : Icons.tab_unselected,
                      size: 72,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _showingIncognito ? 'No open incognito tabs' : 'No open tabs',
                      style: TextStyle(
                        fontSize: 18,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        manager.openNewTab('https://www.google.com', incognito: _showingIncognito);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.add),
                      label: Text(_showingIncognito ? 'New Incognito Tab' : 'New Tab'),
                    ),
                  ],
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: ResponsiveLayout.getTabGridColumns(context),
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: tabs.length,
                itemBuilder: (context, index) {
                  final tab = tabs[index];
                  final isSelected = index == activeIndex;

                  return AnimatedPressable(
                    scaleFactor: 0.94,
                    onTap: () {
                      manager.switchToTab(index, incognito: _showingIncognito);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? Colors.blueAccent : Colors.transparent,
                          width: isSelected ? 2.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Tab Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF383838) : Colors.grey[200],
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _showingIncognito ? Icons.security : Icons.public,
                                  size: 16,
                                  color: Colors.blueAccent,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    tab.title.isNotEmpty ? tab.title : 'New Tab',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    manager.closeTab(index, incognito: _showingIncognito);
                                    setState(() {});
                                  },
                                  child: const Icon(Icons.close, size: 18),
                                ),
                              ],
                            ),
                          ),
                          // Tab Thumbnail Preview Simulation
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF202020) : Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _showingIncognito ? Icons.security : Icons.language,
                                    size: 36,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      tab.url,
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        bottomNavigationBar: BottomAppBar(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: tabs.isEmpty
                    ? null
                    : () {
                        manager.closeAllTabs(incognito: _showingIncognito);
                        setState(() {});
                      },
                icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                label: const Text('Close All'),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, size: 36, color: Colors.blueAccent),
                onPressed: () {
                  manager.openNewTab('https://www.google.com', incognito: _showingIncognito);
                  Navigator.pop(context);
                },
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.blueAccent.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.blueAccent : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.blueAccent : Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.blueAccent : Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
