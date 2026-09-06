class Bookmark {
  final String id;
  final String title;
  final String url;
  final DateTime createdAt;
  final bool isCollection;
  final String? collectionName;

  Bookmark({
    required this.id,
    required this.title,
    required this.url,
    required this.createdAt,
    this.isCollection = false,
    this.collectionName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'createdAt': createdAt.toIso8601String(),
      'isCollection': isCollection,
      'collectionName': collectionName,
    };
  }

  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'] as String,
      title: map['title'] as String,
      url: map['url'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isCollection: map['isCollection'] as bool? ?? false,
      collectionName: map['collectionName'] as String?,
    );
  }
}
