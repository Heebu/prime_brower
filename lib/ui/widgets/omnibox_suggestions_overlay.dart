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

    // 1. Filtered Backend Suggestions from Firestore
    final backendSuggestions = browserManager.backendSuggestions.where((s) {
      if (cleanQuery.isEmpty) return true;
      return s.query.toLowerCase().contains(cleanQuery) ||
          s.category.toLowerCase().contains(cleanQuery);
    }).take(cleanQuery.isEmpty ? 5 : 4).toList();

    // 2. Filtered Search History (Firestore backed)
    final searchHistory = browserManager.searchHistory.where((q) {
      if (cleanQuery.isEmpty) return true;
      return q.toLowerCase().contains(cleanQuery);
    }).take(4).toList();

    // 3. Filtered Bookmarks
    final matchingBookmarks = browserManager.bookmarks.where((b) {
      if (cleanQuery.isEmpty) return false;
      return b.title.toLowerCase().contains(cleanQuery) || b.url.toLowerCase().contains(cleanQuery);
    }).take(3).toList();

    // 4. Filtered Browsing History (Firestore backed)
    final matchingBrowsing = browserManager.browsingHistory.where((h) {
      final url = h['url']?.toLowerCase() ?? '';
      final title = h['title']?.toLowerCase() ?? '';
      if (cleanQuery.isEmpty) return true;
      return url.contains(cleanQuery) || title.contains(cleanQuery);
    }).take(cleanQuery.isEmpty ? 4 : 3).toList();

    final isDark = isIncognito || Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF09090B) : Colors.white,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Search Query Direct Action (when user is typing)
          if (cleanQuery.isNotEmpty) ...[
            _buildSuggestionTile(
              icon: Icons.search_rounded,
              iconColor: const Color(0xFF10B981),
              title: query.trim(),
              subtitle: 'Search web for "$query"',
              isDark: isDark,
              onTap: () => onSelect(query.trim()),
              onQuickFill: () => onQuickFill(query.trim()),
            ),
            const Divider(height: 1),
          ],

          // Priority 1 (Typing): Suggested Searches from Backend Firestore
          if (cleanQuery.isNotEmpty && backendSuggestions.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'SUGGESTED SEARCHES',
              isDark: isDark,
              trailingBadge: 'Cloud',
              icon: Icons.auto_awesome_rounded,
            ),
            ...backendSuggestions.map((s) {
              final hasUrl = s.targetUrl != null && s.targetUrl!.isNotEmpty;
              return _buildSuggestionTile(
                icon: hasUrl ? Icons.language_rounded : Icons.trending_up_rounded,
                iconColor: const Color(0xFF10B981),
                title: s.query,
                subtitle: hasUrl ? s.targetUrl : 'Topic in ${s.category}',
                badge: s.category,
                isDark: isDark,
                onTap: () => onSelect(hasUrl ? s.targetUrl! : s.query),
                onQuickFill: () => onQuickFill(s.query),
              );
            }),
            const Divider(height: 12),
          ],

          // Priority 2: Recent Searches (backed by Firestore)
          if (searchHistory.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'RECENT SEARCHES',
              isDark: isDark,
              actionLabel: cleanQuery.isEmpty ? 'Clear All' : null,
              onAction: () => browserManager.clearSearchHistory(),
            ),
            ...searchHistory.map((item) {
              return _buildSuggestionTile(
                icon: Icons.history_rounded,
                iconColor: isDark ? Colors.white54 : Colors.grey[600]!,
                title: item,
                isDark: isDark,
                onTap: () => onSelect(item),
                onQuickFill: () => onQuickFill(item),
                onDelete: () => browserManager.removeSearchHistory(item),
              );
            }),
            const Divider(height: 12),
          ],

          // Priority 3 (Default/Empty): Trending & Suggestions from Backend Firestore
          if (cleanQuery.isEmpty && backendSuggestions.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'TRENDING & SUGGESTED SEARCHES',
              isDark: isDark,
              trailingBadge: 'Cloud',
              icon: Icons.auto_awesome_rounded,
            ),
            ...backendSuggestions.map((s) {
              final hasUrl = s.targetUrl != null && s.targetUrl!.isNotEmpty;
              return _buildSuggestionTile(
                icon: hasUrl ? Icons.language_rounded : Icons.trending_up_rounded,
                iconColor: const Color(0xFF10B981),
                title: s.query,
                subtitle: hasUrl ? s.targetUrl : 'Category: ${s.category}',
                badge: s.category,
                isDark: isDark,
                onTap: () => onSelect(hasUrl ? s.targetUrl! : s.query),
                onQuickFill: () => onQuickFill(s.query),
              );
            }),
            const Divider(height: 12),
          ],

          // Priority 4: Matching Bookmarks & Collections
          if (matchingBookmarks.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'BOOKMARKS & COLLECTIONS',
              isDark: isDark,
            ),
            ...matchingBookmarks.map((b) {
              return _buildSuggestionTile(
                icon: b.isCollection ? Icons.collections_bookmark_rounded : Icons.star_rounded,
                iconColor: const Color(0xFF10B981),
                title: b.title,
                subtitle: b.url,
                isDark: isDark,
                onTap: () => onSelect(b.url),
                onQuickFill: () => onQuickFill(b.url),
              );
            }),
            const Divider(height: 12),
          ],

          // Priority 5: Browsing History & Visited Pages (backed by Firestore)
          if (matchingBrowsing.isNotEmpty) ...[
            _buildSectionHeader(
              title: cleanQuery.isEmpty ? 'FREQUENT & RECENT SITES' : 'MATCHING WEB PAGES',
              isDark: isDark,
              actionLabel: cleanQuery.isEmpty ? 'Clear All' : null,
              onAction: () => browserManager.clearBrowsingHistory(),
            ),
            ...matchingBrowsing.map((h) {
              final title = h['title'] ?? 'Web Page';
              final url = h['url'] ?? '';
              return _buildSuggestionTile(
                icon: Icons.public_rounded,
                iconColor: const Color(0xFF10B981),
                title: title,
                subtitle: url,
                isDark: isDark,
                onTap: () => onSelect(url),
                onQuickFill: () => onQuickFill(url),
                onDelete: () => browserManager.removeBrowsingHistory(url),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required bool isDark,
    String? actionLabel,
    VoidCallback? onAction,
    String? trailingBadge,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: const Color(0xFF10B981)),
                const SizedBox(width: 6),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: isDark ? Colors.white54 : Colors.grey[600],
                ),
              ),
            ],
          ),
          if (trailingBadge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                trailingBadge,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            )
          else if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    String? badge,
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
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ],
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

