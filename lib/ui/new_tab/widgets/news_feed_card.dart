import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/feed_item.dart';
import '../../../core/design_system/animated_pressable.dart';

class NewsFeedCard extends StatelessWidget {
  final NewsFeedItem item;
  final bool isDark;
  final void Function(String url) onTap;

  const NewsFeedCard({
    super.key,
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'tech':
        return const Color(0xFF0284C7);
      case 'business':
        return const Color(0xFFD97706);
      case 'science':
        return const Color(0xFF9333EA);
      case 'sports':
        return const Color(0xFF059669);
      case 'world':
        return const Color(0xFF4F46E5);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'tech':
        return Icons.memory_rounded;
      case 'business':
        return Icons.trending_up_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'sports':
        return Icons.sports_soccer_rounded;
      case 'world':
        return Icons.public_rounded;
      default:
        return Icons.article_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _getCategoryColor(item.category);

    return AnimatedPressable(
      scaleFactor: 0.98,
      onTap: () => onTap(item.url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Source, Category Badge, Time, Share
            Row(
              children: [
                // Category Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getCategoryIcon(item.category), size: 12, color: catColor),
                      const SizedBox(width: 4),
                      Text(
                        item.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: catColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Source Name
                Expanded(
                  child: Text(
                    '${item.source} • ${item.timeAgo}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : Colors.grey[600],
                    ),
                  ),
                ),

                // Share Button
                IconButton(
                  icon: Icon(
                    Icons.share_outlined,
                    size: 16,
                    color: isDark ? Colors.white54 : Colors.grey[500],
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Share Article',
                  onPressed: () {
                    try {
                      Share.share('${item.title}\n${item.url}');
                    } catch (_) {}
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Main Body: Headline + Thumbnail Accent
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          item.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: isDark ? Colors.white60 : Colors.grey[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Thumbnail Illustration / Graphic Accent
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        catColor.withValues(alpha: 0.8),
                        catColor.withValues(alpha: 0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      _getCategoryIcon(item.category),
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Footer: Read Time & Action Hint
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 12,
                      color: isDark ? Colors.white38 : Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.readTimeMinutes} min read',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Read story',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: catColor,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, size: 12, color: catColor),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
