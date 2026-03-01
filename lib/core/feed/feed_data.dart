class FeedData {
  final String title;
  final String? author;
  final String? iconUrl;
  final List<FeedItem> items;

  const FeedData({
    required this.title,
    this.author,
    this.iconUrl,
    required this.items,
  });
}

class FeedItem {
  final String? guid;
  final String title;
  final String? author;
  final DateTime? publishedAt;
  final String? contentHtml;
  final String? excerpt;
  final String? link;

  const FeedItem({
    this.guid,
    required this.title,
    this.author,
    this.publishedAt,
    this.contentHtml,
    this.excerpt,
    this.link,
  });
}
