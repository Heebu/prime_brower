import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/browser_manager.dart';
import '../../models/web_tab.dart';
import '../../core/design_system/responsive_layout.dart';
import '../../core/design_system/animated_pressable.dart';

enum TabFilter { all, pinned, domain }

class TabGridScreen extends StatefulWidget {
  final BrowserManager browserManager;

  const TabGridScreen({super.key, required this.browserManager});

  @override
  State<TabGridScreen> createState() => _TabGridScreenState();
}

class _TabGridScreenState extends State<TabGridScreen> {
  late bool _showingIncognito;
  TabFilter _selectedFilter = TabFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _showingIncognito = widget.browserManager.isIncognito;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.browserManager,
      builder: (context, _) {
        final manager = widget.browserManager;
        final allTabs = _showingIncognito ? manager.incognitoTabs : manager.normalTabs;
        final activeIndex = _showingIncognito ? manager.incognitoTabIndex : manager.normalTabIndex;
        final isDark = _showingIncognito;
        final pinnedCount = allTabs.where((t) => t.isPinned).length;

        // Filter and search logic
        final List<MapEntry<int, WebTab>> filteredEntries = [];
        for (int i = 0; i < allTabs.length; i++) {
          final tab = allTabs[i];
          if (_selectedFilter == TabFilter.pinned && !tab.isPinned) {
            continue;
          }
          if (_searchQuery.isNotEmpty) {
            final matches = tab.title.toLowerCase().contains(_searchQuery) ||
                tab.url.toLowerCase().contains(_searchQuery) ||
                tab.domain.toLowerCase().contains(_searchQuery);
            if (!matches) continue;
          }
          filteredEntries.add(MapEntry(i, tab));
        }

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
                    manager.openNewTab('prime://newtab', incognito: _showingIncognito);
                    Navigator.pop(context);
                  },
                ),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'close_all') {
                      manager.closeAllTabs(incognito: _showingIncognito);
                      setState(() {});
                    } else if (val == 'sleep_all') {
                      manager.freezeAllInactiveTabs(incognito: _showingIncognito);
                    }
                  },
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(
                      value: 'sleep_all',
                      child: Row(
                        children: [
                          Icon(Icons.ac_unit_rounded, size: 16, color: Colors.cyan),
                          SizedBox(width: 8),
                          Text('Sleep all inactive tabs'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'close_all',
                      child: Text('Close all tabs'),
                    ),
                  ],
                ),
              ],
            ),
            body: allTabs.isEmpty
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
                            manager.openNewTab('prime://newtab', incognito: _showingIncognito);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.add),
                          label: Text(_showingIncognito ? 'New Incognito Tab' : 'New Tab'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Tab Search Field
                      Container(
                        margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.grey[300]!,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'Search tabs...',
                            hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.grey[500]),
                            prefixIcon: Icon(Icons.search, size: 18, color: isDark ? Colors.white38 : Colors.grey[500]),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),

                      // Filter & Organization Segmented Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        child: Row(
                          children: [
                            _buildFilterChip(
                              label: 'All (${allTabs.length})',
                              icon: Icons.grid_view_rounded,
                              isSelected: _selectedFilter == TabFilter.all,
                              isDark: isDark,
                              onTap: () => setState(() => _selectedFilter = TabFilter.all),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              label: 'Pinned ($pinnedCount)',
                              icon: Icons.push_pin_rounded,
                              isSelected: _selectedFilter == TabFilter.pinned,
                              isDark: isDark,
                              onTap: () => setState(() => _selectedFilter = TabFilter.pinned),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              label: 'By Domain',
                              icon: Icons.folder_copy_rounded,
                              isSelected: _selectedFilter == TabFilter.domain,
                              isDark: isDark,
                              onTap: () => setState(() => _selectedFilter = TabFilter.domain),
                            ),
                          ],
                        ),
                      ),

                      // Memory Saver Banner
                      if (allTabs.length > 1)
                        Container(
                          margin: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF38BDF8).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.ac_unit_rounded, size: 15, color: Color(0xFF0284C7)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  manager.frozenTabsCount > 0
                                      ? 'Memory Saver: ${manager.frozenTabsCount} sleeping • ${manager.totalMemorySavedMb} MB saved'
                                      : 'Memory Saver Active • Tap to freeze inactive',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : const Color(0xFF0369A1),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  manager.freezeAllInactiveTabs(incognito: _showingIncognito);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Put inactive tabs to sleep! Saved ~${manager.totalMemorySavedMb} MB RAM'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Sleep',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Grid or Domain Groups Body
                      Expanded(
                        child: _selectedFilter == TabFilter.domain
                            ? _buildDomainGroupedView(
                                context: context,
                                allTabs: allTabs,
                                activeIndex: activeIndex,
                                isDark: isDark,
                                manager: manager,
                              )
                            : (filteredEntries.isEmpty
                                ? Center(
                                    child: Text(
                                      'No matching tabs found',
                                      style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600]),
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
                                    itemCount: filteredEntries.length,
                                    itemBuilder: (context, index) {
                                      final entry = filteredEntries[index];
                                      final originalIndex = entry.key;
                                      final tab = entry.value;
                                      final isSelected = originalIndex == activeIndex;
                                      final canReorder = _selectedFilter == TabFilter.all && _searchQuery.isEmpty;

                                      return _buildReorderableTabItem(
                                        context: context,
                                        tab: tab,
                                        originalIndex: originalIndex,
                                        isSelected: isSelected,
                                        isDark: isDark,
                                        manager: manager,
                                        canReorder: canReorder,
                                      );
                                    },
                                  )),
                      ),
                    ],
                  ),
            bottomNavigationBar: BottomAppBar(
              color: isDark ? const Color(0xFF121212) : Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: allTabs.isEmpty
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
                      manager.openNewTab('prime://newtab', incognito: _showingIncognito);
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
      },
    );
  }

  Widget _buildDomainGroupedView({
    required BuildContext context,
    required List<WebTab> allTabs,
    required int activeIndex,
    required bool isDark,
    required BrowserManager manager,
  }) {
    final domainGroups = <String, List<MapEntry<int, WebTab>>>{};
    for (int i = 0; i < allTabs.length; i++) {
      final tab = allTabs[i];
      if (_searchQuery.isNotEmpty) {
        final matches = tab.title.toLowerCase().contains(_searchQuery) ||
            tab.url.toLowerCase().contains(_searchQuery) ||
            tab.domain.toLowerCase().contains(_searchQuery);
        if (!matches) continue;
      }
      domainGroups.putIfAbsent(tab.domain, () => []).add(MapEntry(i, tab));
    }

    if (domainGroups.isEmpty) {
      return Center(
        child: Text(
          'No matching tabs found',
          style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600]),
        ),
      );
    }

    final groupList = domainGroups.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: groupList.length,
      itemBuilder: (ctx, gIndex) {
        final group = groupList[gIndex];
        final domainName = group.key;
        final tabsInGroup = group.value;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252525) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey[300]!,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.public, size: 18, color: isDark ? Colors.cyanAccent : Colors.blueAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      domainName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${tabsInGroup.length} ${tabsInGroup.length == 1 ? 'tab' : 'tabs'}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: ResponsiveLayout.getTabGridColumns(context),
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: tabsInGroup.length,
                itemBuilder: (context, idx) {
                  final entry = tabsInGroup[idx];
                  return _wrapWithDismissible(
                    context: context,
                    tab: entry.value,
                    originalIndex: entry.key,
                    manager: manager,
                    child: _buildTabCard(
                      context: context,
                      tab: entry.value,
                      originalIndex: entry.key,
                      isSelected: entry.key == activeIndex,
                      isDark: isDark,
                      manager: manager,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDismissBackground({required bool isStart}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: isStart ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
          SizedBox(height: 4),
          Text(
            'Close',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _wrapWithDismissible({
    required BuildContext context,
    required WebTab tab,
    required int originalIndex,
    required BrowserManager manager,
    required Widget child,
  }) {
    return Dismissible(
      key: ValueKey('tab_dismiss_${tab.id}'),
      direction: DismissDirection.horizontal,
      background: _buildDismissBackground(isStart: true),
      secondaryBackground: _buildDismissBackground(isStart: false),
      confirmDismiss: (direction) async {
        if (tab.isPinned) {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('This tab is pinned! Unpin it first to close.'),
              action: SnackBarAction(
                label: 'Unpin',
                onPressed: () {
                  manager.togglePinTab(originalIndex, incognito: _showingIncognito);
                },
              ),
              duration: const Duration(seconds: 2),
            ),
          );
          return false;
        }
        return true;
      },
      onDismissed: (direction) {
        HapticFeedback.mediumImpact();
        manager.closeTabById(tab.id, incognito: _showingIncognito);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Closed "${tab.title.isNotEmpty ? tab.title : 'Tab'}"'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                manager.openNewTab(tab.url, incognito: _showingIncognito);
              },
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildReorderableTabItem({
    required BuildContext context,
    required WebTab tab,
    required int originalIndex,
    required bool isSelected,
    required bool isDark,
    required BrowserManager manager,
    required bool canReorder,
  }) {
    final card = _buildTabCard(
      context: context,
      tab: tab,
      originalIndex: originalIndex,
      isSelected: isSelected,
      isDark: isDark,
      manager: manager,
    );

    final itemWidget = canReorder
        ? DragTarget<int>(
            onWillAcceptWithDetails: (details) => details.data != originalIndex,
            onAcceptWithDetails: (details) {
              manager.reorderTab(details.data, originalIndex, incognito: _showingIncognito);
              HapticFeedback.mediumImpact();
            },
            builder: (context, candidateData, rejectedData) {
              final isHovered = candidateData.isNotEmpty;
              return LongPressDraggable<int>(
                data: originalIndex,
                feedback: Material(
                  elevation: 10,
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 170,
                    height: 220,
                    child: Opacity(
                      opacity: 0.9,
                      child: card,
                    ),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.25,
                  child: card,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  transform: isHovered ? Matrix4.diagonal3Values(1.05, 1.05, 1.0) : Matrix4.identity(),
                  child: card,
                ),
              );
            },
          )
        : card;

    return _wrapWithDismissible(
      context: context,
      tab: tab,
      originalIndex: originalIndex,
      manager: manager,
      child: itemWidget,
    );
  }

  Widget _buildTabCard({
    required BuildContext context,
    required WebTab tab,
    required int originalIndex,
    required bool isSelected,
    required bool isDark,
    required BrowserManager manager,
  }) {
    final isFrozen = tab.isFrozen;
    final isPinned = tab.isPinned;

    return AnimatedPressable(
      scaleFactor: 0.95,
      onTap: () {
        manager.switchToTab(originalIndex, incognito: _showingIncognito);
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.blueAccent
                : (isPinned
                    ? Colors.amber.withOpacity(0.8)
                    : (isFrozen ? Colors.cyan.withOpacity(0.6) : Colors.transparent)),
            width: isSelected ? 2.5 : (isPinned || isFrozen ? 1.5 : 1),
          ),
          boxShadow: [
            BoxShadow(
              color: isPinned ? Colors.amber.withOpacity(0.12) : Colors.black.withOpacity(0.08),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF383838) : Colors.grey[200],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Icon(
                    isFrozen
                        ? Icons.ac_unit_rounded
                        : (_showingIncognito ? Icons.security : Icons.public),
                    size: 15,
                    color: isFrozen ? Colors.cyan : Colors.blueAccent,
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
                  // Pin toggle
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      manager.togglePinTab(originalIndex, incognito: _showingIncognito);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        size: 16,
                        color: isPinned ? Colors.amber : (isDark ? Colors.white38 : Colors.grey[500]),
                      ),
                    ),
                  ),
                  // Close button
                  GestureDetector(
                    onTap: () {
                      manager.closeTab(originalIndex, incognito: _showingIncognito);
                      setState(() {});
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.close, size: 16),
                    ),
                  ),
                ],
              ),
            ),

            // Tab Thumbnail Preview Simulation
            Expanded(
              child: Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isFrozen
                          ? (isDark ? const Color(0xFF0F2333) : const Color(0xFFE0F2FE))
                          : (isDark ? const Color(0xFF202020) : Colors.grey[50]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isFrozen
                              ? Icons.bedtime_rounded
                              : (_showingIncognito ? Icons.security : Icons.language),
                          size: 34,
                          color: isFrozen ? Colors.cyan : Colors.grey[400],
                        ),
                        const SizedBox(height: 6),
                        if (isFrozen)
                          const Text(
                            'Sleeping to save RAM',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.cyan,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          child: Text(
                            tab.isNewTabPage ? 'Prime Start Dashboard' : tab.url,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: isFrozen ? Colors.cyan[700] : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Pinned Badge on preview
                  if (isPinned)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.push_pin, size: 10, color: Colors.black87),
                            SizedBox(width: 2),
                            Text(
                              'PINNED',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // RAM Saved badge on preview
                  if (isFrozen)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.cyan.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.cyan.withOpacity(0.5)),
                        ),
                        child: const Text(
                          '42 MB SAVED',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.cyan),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent
              : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : (isDark ? Colors.white12 : Colors.grey[300]!),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
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
