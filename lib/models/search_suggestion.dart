class SearchSuggestion {
  final String id;
  final String query;
  final String category;
  final String? targetUrl;
  final int popularity;

  const SearchSuggestion({
    required this.id,
    required this.query,
    this.category = 'Trending',
    this.targetUrl,
    this.popularity = 0,
  });

  factory SearchSuggestion.fromMap(String id, Map<String, dynamic> map) {
    return SearchSuggestion(
      id: id,
      query: (map['query'] as String? ?? map['text'] as String? ?? '').trim(),
      category: map['category'] as String? ?? 'Trending',
      targetUrl: map['targetUrl'] as String?,
      popularity: (map['popularity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'query': query,
      'category': category,
      if (targetUrl != null) 'targetUrl': targetUrl,
      'popularity': popularity,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchSuggestion &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
