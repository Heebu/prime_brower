import 'package:flutter/material.dart';
import '../../models/browser_banner.dart';

class BrowserBannerWidget extends StatelessWidget {
  final BrowserBanner banner;
  final VoidCallback onDismiss;

  const BrowserBannerWidget({
    super.key,
    required this.banner,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? Color.alphaBlend(banner.accentColor.withValues(alpha: 0.15), const Color(0xFF1E293B))
        : Color.alphaBlend(banner.accentColor.withValues(alpha: 0.08), Colors.white);

    final borderColor = banner.accentColor.withValues(alpha: isDark ? 0.4 : 0.3);

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: banner.accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Icon, Title, Dismiss Button
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: banner.accentColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      banner.icon,
                      color: banner.accentColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          banner.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          banner.message,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white70 : Colors.black54,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (banner.isDismissible)
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      color: isDark ? Colors.white54 : Colors.black38,
                      tooltip: 'Dismiss banner',
                      onPressed: () {
                        banner.onDismiss?.call();
                        onDismiss();
                      },
                    ),
                ],
              ),
            ),

            // Actions row (if actions are provided)
            if (banner.primaryActionLabel != null || banner.secondaryActionLabel != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (banner.secondaryActionLabel != null) ...[
                      TextButton(
                        onPressed: () {
                          banner.onSecondaryAction?.call();
                          onDismiss();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? Colors.white70 : Colors.black54,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: const Size(40, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          banner.secondaryActionLabel!,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (banner.primaryActionLabel != null)
                      ElevatedButton(
                        onPressed: () {
                          banner.onPrimaryAction?.call();
                          onDismiss();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: banner.accentColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: const Size(50, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          banner.primaryActionLabel!,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
}
