import 'package:flutter/material.dart';
import '../../services/browser_manager.dart';

class OmniboxSuggestionsOverlay extends StatelessWidget {
  final BrowserManager browserManager;
  final String query;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onQuickFill;
  final VoidCallback onDismiss;

  const OmniboxSuggestionsOverlay({
    Key? key,
    required this.browserManager,
    required this.query,
    required this.onSelect,
    required this.onQuickFill,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isIncognito = browserManager.isIncognito;
    final cleanQuery = query.trim().toLowerCase();

    // 1. Filtered Search History
    final searchHistory = browserManager.searchHistory.where((q) {
      if (cleanQuery.isEmpty) return true;
      return q.toLowerCase().contains(cleanQuery);
    }).take(4).toList();

    // 2. Filtered Bookmarks
    final matchingBookmarks = browserManager.bookmarks.where((b) {
      if (cleanQuery.isEmpty) return false;
      return b.title.toLowerCase().contains(cleanQuery) || b.url.toLowerCase().contains(cleanQuery);
    }).take(3).toList();

    // 3. Filtered Browsing History
    final matchingBrowsing = browserManager.browsingHistory.where((h) {
      final url = h['url']?.toLowerCase() ?? '';
      final title = h['title']?.toLowerCase() ?? '';
      if (cleanQuery.isEmpty) return true;
      return url.contains(cleanQuery) || title.contains(cleanQuery);
    }).take(cleanQuery.isEmpty ? 4 : 3).toList();

    return Material(
      color: isIncognito ? const Color(0xFF181818) : Colors.white,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // Search Query Action (when user is typing)
            if (cleanQuery.isNotEmpty) ...[
              _buildSuggestionTile(
                icon: Icons.search_rounded,
                iconColor: Colors.blueAccent,
                title: query.trim(),
                subtitle: 'Search web for "$query"',
                isDark: isIncognito,
                onTap: () => onSelect(query.trim()),
                onQuickFill: () => onQuickFill(query.trim()),
              ),
              const Divider(height: 1),
            ],

            // Priority 1: Recent Searches
            if (searchHistory.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RECENT SEARCHES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: isIncognito ? Colors.white54 : Colors.grey[600],
                      ),
                    ),
                    if (cleanQuery.isEmpty)
                      GestureDetector(
                        onTap: () => browserManager.clearSearchHistory(),
                        child: Text(
                          'Clear All',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isIncognito ? Colors.purpleAccent : Colors.blueAccent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              ...searchHistory.map((item) {
                return _buildSuggestionTile(
                  icon: Icons.history_rounded,
                  iconColor: isIncognito ? Colors.white54 : Colors.grey[600]!,
                  title: item,
                  isDark: isIncognito,
                  onTap: () => onSelect(item),
                  onQuickFill: () => onQuickFill(item),
                  onDelete: () => browserManager.removeSearchHistory(item),
                );
              }),
              const Divider(height: 12),
            ],

            // Priority 2: Matching Bookmarks & Collections
            if (matchingBookmarks.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'BOOKMARKS & COLLECTIONS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: isIncognito ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ),
              ...matchingBookmarks.map((b) {
                return _buildSuggestionTile(
                  icon: b.isCollection ? Icons.collections_bookmark_rounded : Icons.star_rounded,
                  iconColor: b.isCollection ? Colors.purpleAccent : Colors.amber,
                  title: b.title,
                  subtitle: b.url,
                  isDark: isIncognito,
                  onTap: () => onSelect(b.url),
                  onQuickFill: () => onQuickFill(b.url),
                );
              }),
              const Divider(height: 12),
            ],

            // Priority 3: Browsing History & Visited Pages
            if (matchingBrowsing.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  cleanQuery.isEmpty ? 'FREQUENT & RECENT SITES' : 'MATCHING WEB PAGES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: isIncognito ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ),
              ...matchingBrowsing.map((h) {
                final title = h['title'] ?? 'Web Page';
                final url = h['url'] ?? '';
                return _buildSuggestionTile(
                  icon: Icons.public_rounded,
                  iconColor: Colors.teal,
                  title: title,
                  subtitle: url,
                  isDark: isIncognito,
                  onTap: () => onSelect(url),
                  onQuickFill: () => onQuickFill(url),
                );
              }),
            ],
          ],
        ),
      );
    }

  Widget _buildSuggestionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool isDark,
    required VoidCallback onTap,
    required VoidCallback onQuickFill,
    VoidCallback? onDelete,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.grey[500],
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 16),
              color: isDark ? Colors.white38 : Colors.grey[400],
              tooltip: 'Remove from history',
              onPressed: onDelete,
            ),
          IconButton(
            icon: const Icon(Icons.north_west_rounded, size: 16),
            color: isDark ? Colors.white54 : Colors.grey[500],
            tooltip: 'Insert into address bar',
            onPressed: onQuickFill,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
