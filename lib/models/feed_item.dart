import 'package:cloud_firestore/cloud_firestore.dart';

class NewsFeedItem {
  final String id;
  final String title;
  final String description;
  final String source;
  final String url;
  final String? imageUrl;
  final String category;
  final DateTime publishedAt;
  final int readTimeMinutes;

  const NewsFeedItem({
    required this.id,
    required this.title,
    required this.description,
    required this.source,
    required this.url,
    this.imageUrl,
    required this.category,
    required this.publishedAt,
    this.readTimeMinutes = 3,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(publishedAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${publishedAt.month}/${publishedAt.day}/${publishedAt.year}';
  }

  factory NewsFeedItem.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedDate;
    final pubAtRaw = map['publishedAt'];
    if (pubAtRaw is Timestamp) {
      parsedDate = pubAtRaw.toDate();
    } else if (pubAtRaw is String) {
      parsedDate = DateTime.tryParse(pubAtRaw) ?? DateTime.now();
    } else if (pubAtRaw is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(pubAtRaw);
    } else {
      parsedDate = DateTime.now();
    }

    return NewsFeedItem(
      id: id,
      title: map['title'] as String? ?? 'Untitled Story',
      description: map['description'] as String? ?? '',
      source: map['source'] as String? ?? 'Web News',
      url: map['url'] as String? ?? 'https://news.google.com',
      imageUrl: map['imageUrl'] as String?,
      category: map['category'] as String? ?? 'General',
      publishedAt: parsedDate,
      readTimeMinutes: (map['readTimeMinutes'] as num?)?.toInt() ?? 3,
    );
  }

  factory NewsFeedItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NewsFeedItem.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'source': source,
      'url': url,
      'imageUrl': imageUrl,
      'category': category,
      'publishedAt': Timestamp.fromDate(publishedAt),
      'readTimeMinutes': readTimeMinutes,
    };
  }
}
