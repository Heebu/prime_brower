import 'package:flutter/material.dart';

class SpeedDialItem {
  final String id;
  final String title;
  final String url;
  final IconData iconData;
  final Color color;
  final bool isCustom;

  const SpeedDialItem({
    required this.id,
    required this.title,
    required this.url,
    required this.iconData,
    required this.color,
    this.isCustom = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'isCustom': isCustom,
    };
  }

  static List<SpeedDialItem> get defaultShortcuts => [
        const SpeedDialItem(
          id: 'google',
          title: 'Google',
          url: 'https://www.google.com',
          iconData: Icons.search_rounded,
          color: Color(0xFF4285F4),
        ),
        const SpeedDialItem(
          id: 'youtube',
          title: 'YouTube',
          url: 'https://www.youtube.com',
          iconData: Icons.play_arrow_rounded,
          color: Color(0xFFFF0000),
        ),
        const SpeedDialItem(
          id: 'github',
          title: 'GitHub',
          url: 'https://www.github.com',
          iconData: Icons.code_rounded,
          color: Color(0xFF24292E),
        ),
        const SpeedDialItem(
          id: 'twitter',
          title: 'X (Twitter)',
          url: 'https://x.com',
          iconData: Icons.alternate_email_rounded,
          color: Color(0xFF1DA1F2),
        ),
        const SpeedDialItem(
          id: 'reddit',
          title: 'Reddit',
          url: 'https://www.reddit.com',
          iconData: Icons.forum_rounded,
          color: Color(0xFFFF4500),
        ),
        const SpeedDialItem(
          id: 'wikipedia',
          title: 'Wikipedia',
          url: 'https://www.wikipedia.org',
          iconData: Icons.menu_book_rounded,
          color: Color(0xFF555555),
        ),
        const SpeedDialItem(
          id: 'amazon',
          title: 'Amazon',
          url: 'https://www.amazon.com',
          iconData: Icons.shopping_cart_rounded,
          color: Color(0xFFFF9900),
        ),
        const SpeedDialItem(
          id: 'copilot',
          title: 'AI Copilot',
          url: 'https://gemini.google.com',
          iconData: Icons.auto_awesome_rounded,
          color: Color(0xFF8B5CF6),
        ),
      ];
}
