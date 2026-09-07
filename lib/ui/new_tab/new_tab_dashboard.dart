import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/speed_dial_item.dart';
import '../../models/bookmark.dart';
import '../../services/browser_manager.dart';
import '../../services/shields_service.dart';
import '../../services/feed_ad_service.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/animated_pressable.dart';
import '../../core/design_system/responsive_layout.dart';
import '../shields/shields_details_sheet.dart';
import 'widgets/news_feed_card.dart';
import 'widgets/ad_card_widget.dart';

class NewTabDashboard extends StatefulWidget {
  final BrowserManager browserManager;
  final ShieldsService shieldsService;
  final void Function(String url) onNavigate;
  final String tabId;

  const NewTabDashboard({
    Key? key,
    required this.browserManager,
    required this.shieldsService,
    required this.onNavigate,
    this.tabId = 'tab_default',
  }) : super(key: key);

  @override
  State<NewTabDashboard> createState() => _NewTabDashboardState();
}

class _NewTabDashboardState extends State<NewTabDashboard> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _selectedEngine = 'Google';
  final Map<String, String> _searchEngines = {
    'Google': 'https://www.google.com/search?q=',
    'DuckDuckGo': 'https://duckduckgo.com/?q=',
    'Private Search': 'https://search.brave.com/search?q=',
    'Bing': 'https://www.bing.com/search?q=',
  };

  late List<SpeedDialItem> _speedDialItems;
  String _selectedCategory = 'All';
  static const List<String> _categories = ['All', 'Tech', 'Business', 'World', 'Science', 'Sports'];

  @override
  void initState() {
    super.initState();
    _speedDialItems = List.from(SpeedDialItem.defaultShortcuts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearchSubmit() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    _searchFocusNode.unfocus();

    // If query is an explicit URL
    if (query.startsWith('http://') || query.startsWith('https://')) {
      widget.onNavigate(query);
      return;
    }

    final hasDomain = RegExp(r'^[a-zA-Z0-9-]+(\.[a-zA-Z]{2,})+').hasMatch(query);
    if (hasDomain && !query.contains(' ')) {
      widget.onNavigate('https://$query');
      return;
    }

    // Use selected search engine
    final baseUrl = _searchEngines[_selectedEngine] ?? 'https://www.google.com/search?q=';
    widget.onNavigate('$baseUrl${Uri.encodeComponent(query)}');
  }

  void _showAddShortcutDialog() {
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Shortcut', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Flutter',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://flutter.dev',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              var url = urlController.text.trim();
              if (title.isNotEmpty && url.isNotEmpty) {
                if (!url.startsWith('http://') && !url.startsWith('https://')) {
                  url = 'https://$url';
                }
                setState(() {
                  _speedDialItems.add(
                    SpeedDialItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: title,
                      url: url,
                      iconData: Icons.language_rounded,
                      color: Colors.blueAccent,
                      isCustom: true,
                    ),
                  );
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.browserManager,
        widget.shieldsService,
        widget.browserManager.feedAdService,
      ]),
      builder: (context, _) {
        final isIncognito = widget.browserManager.isIncognito;
        final isDark = isIncognito || Theme.of(context).brightness == Brightness.dark;
        final blockedCount = widget.shieldsService.blockedElementsCount;
        final dataSavedMb = (blockedCount * 0.165).toStringAsFixed(1);
        final timeSavedSec = (blockedCount * 0.45).toStringAsFixed(1);

        return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Brand Header with Gradient Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: isIncognito
                      ? const LinearGradient(
                          colors: [Color(0xFF4A148C), Color(0xFF1E88E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isIncognito ? Colors.purple : const Color(0xFF6366F1)).withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  isIncognito ? Icons.security_rounded : Icons.explore_rounded,
                  size: 38,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                isIncognito ? 'Incognito Mode' : 'Prime Browser',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isIncognito ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isIncognito
                    ? 'Your browsing activity stays private and won\'t be saved'
                    : 'Fast • Private • AI-Powered',
                style: TextStyle(
                  fontSize: 13,
                  color: isIncognito ? Colors.white54 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 28),

              // Multi-Engine Search Box
              Container(
                decoration: BoxDecoration(
                  color: isIncognito ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isIncognito ? Colors.white12 : Colors.grey.withOpacity(0.2),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isIncognito ? 0.3 : 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    // Search Engine Selector Menu
                    PopupMenuButton<String>(
                      initialValue: _selectedEngine,
                      tooltip: 'Select Search Engine',
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (engine) => setState(() => _selectedEngine = engine),
                      itemBuilder: (ctx) => _searchEngines.keys.map((engine) {
                        return PopupMenuItem(
                          value: engine,
                          child: Row(
                            children: [
                              Icon(
                                engine == 'DuckDuckGo'
                                    ? Icons.shield_rounded
                                    : (engine == 'Private Search' ? Icons.security : Icons.search),
                                size: 18,
                                color: Colors.blueAccent,
                              ),
                              const SizedBox(width: 8),
                              Text(engine, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        );
                      }).toList(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isIncognito ? Colors.white10 : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedEngine,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isIncognito ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: isIncognito ? Colors.white54 : Colors.grey[600],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Search Input
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _handleSearchSubmit(),
                        style: TextStyle(
                          fontSize: 14,
                          color: isIncognito ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search or enter address',
                          hintStyle: TextStyle(
                            color: isIncognito ? Colors.white38 : Colors.grey[400],
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),

                    // Submit Action Button
                    AnimatedPressable(
                      onTap: _handleSearchSubmit,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Prime Shields Privacy Metrics Card (Tappable to view detailed shield logs & whitelist)
              AnimatedPressable(
                scaleFactor: 0.98,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ShieldsDetailsSheet(
                      shieldsService: widget.shieldsService,
                      currentUrl: 'prime://newtab',
                      onReload: () {},
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isIncognito ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.deepOrangeAccent.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepOrangeAccent.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.deepOrangeAccent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.shield_rounded,
                                  color: Colors.deepOrangeAccent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Prime Privacy Shields',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isIncognito ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: widget.shieldsService.shieldsEnabled
                                  ? Colors.green.withOpacity(0.12)
                                  : Colors.grey.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.shieldsService.shieldsEnabled ? 'ACTIVE' : 'OFF',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: widget.shieldsService.shieldsEnabled ? Colors.green : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildShieldStat(
                            label: 'Trackers Blocked',
                            value: '$blockedCount',
                            icon: Icons.block_rounded,
                            color: Colors.deepOrangeAccent,
                            isIncognito: isIncognito,
                          ),
                          _buildShieldStat(
                            label: 'Est. Data Saved',
                            value: '${dataSavedMb}MB',
                            icon: Icons.data_saver_on_rounded,
                            color: Colors.blueAccent,
                            isIncognito: isIncognito,
                          ),
                          _buildShieldStat(
                            label: 'Time Saved',
                            value: '${timeSavedSec}s',
                            icon: Icons.timer_outlined,
                            color: Colors.teal,
                            isIncognito: isIncognito,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Speed Dial Shortcuts Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SPEED DIAL SHORTCUTS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: isIncognito ? Colors.white38 : Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Responsive Speed Dial Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: ResponsiveLayout.isTabletOrLarger(context) ? 6 : 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: _speedDialItems.length + 1,
                itemBuilder: (context, index) {
                  if (index == _speedDialItems.length) {
                    // Add Shortcut Button
                    return AnimatedPressable(
                      onTap: _showAddShortcutDialog,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: isIncognito ? Colors.white10 : Colors.grey[200],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isIncognito ? Colors.white24 : Colors.grey[400]!,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              color: isIncognito ? Colors.white70 : Colors.black54,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Add',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isIncognito ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final item = _speedDialItems[index];
                  return AnimatedPressable(
                    onTap: () => widget.onNavigate(item.url),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: item.color.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            item.iconData,
                            color: item.color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isIncognito ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Recent Bookmarks Carousel
              if (widget.browserManager.bookmarks.isNotEmpty) ...[
                const SizedBox(height: 28),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'RECENT BOOKMARKS & COLLECTIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: isIncognito ? Colors.white38 : Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 72,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.browserManager.bookmarks.length,
                    itemBuilder: (context, index) {
                      final b = widget.browserManager.bookmarks[index];
                      return AnimatedPressable(
                        onTap: () => widget.onNavigate(b.url),
                        child: Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isIncognito ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isIncognito ? Colors.white12 : Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: (b.isCollection ? Colors.purple : Colors.amber).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  b.isCollection ? Icons.collections_bookmark : Icons.bookmark_rounded,
                                  size: 16,
                                  color: b.isCollection ? Colors.purple : Colors.amber,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      b.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isIncognito ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      b.url,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isIncognito ? Colors.white38 : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // Trending Feeds & News Updates Section
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.newspaper_rounded,
                          size: 16,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'FEEDS & NEWS UPDATES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: isDark ? Colors.white70 : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),

                  // Shuffle / Refresh Feed Button
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.browserManager.feedAdService.refreshTabFeed(widget.tabId);
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Feed re-shuffled with fresh stories & updates!'),
                          duration: Duration(milliseconds: 1500),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shuffle_rounded,
                            size: 14,
                            color: isDark ? Colors.white70 : const Color(0xFF4F46E5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Shuffle',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF4F46E5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Category Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedCategory = cat),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF6366F1)
                                : (isDark ? Colors.white10 : Colors.white),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF6366F1)
                                  : (isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.2)),
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.grey[700]),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Feeds & Adverts List
              Builder(
                builder: (context) {
                  final feedEntries = widget.browserManager.feedAdService.getFeedForTab(
                    tabId: widget.tabId,
                    selectedCategory: _selectedCategory,
                  );

                  if (feedEntries.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'No feeds available in this category',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : Colors.grey[600],
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: feedEntries.length,
                    itemBuilder: (context, idx) {
                      final entry = feedEntries[idx];
                      if (entry.isNews) {
                        return NewsFeedCard(
                          item: entry.news!,
                          isDark: isDark,
                          onTap: widget.onNavigate,
                        );
                      } else {
                        return AdCardWidget(
                          ad: entry.ad!,
                          isDark: isDark,
                          onTap: widget.onNavigate,
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  },
);
  }

  Widget _buildShieldStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isIncognito,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isIncognito ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: isIncognito ? Colors.white54 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
