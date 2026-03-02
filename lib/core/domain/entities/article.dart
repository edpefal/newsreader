import 'package:equatable/equatable.dart';

class Article extends Equatable {
  final String id;
  final String sourceId;
  final String sourceName;
  final String? sourceIconUrl;
  final String title;
  final String? author;
  final DateTime publishedAt;
  final String? contentHtml;
  final String? excerpt;
  final String articleUrl;
  final bool isRead;
  final bool isFavorite;
  final bool isArchived;
  final DateTime? readAt;
  final DateTime? savedAsFavoriteAt;

  const Article({
    required this.id,
    required this.sourceId,
    required this.sourceName,
    this.sourceIconUrl,
    required this.title,
    this.author,
    required this.publishedAt,
    this.contentHtml,
    this.excerpt,
    required this.articleUrl,
    this.isRead = false,
    this.isFavorite = false,
    this.isArchived = false,
    this.readAt,
    this.savedAsFavoriteAt,
  });

  Article copyWith({
    bool? isRead,
    bool? isFavorite,
    bool? isArchived,
    DateTime? readAt,
    DateTime? savedAsFavoriteAt,
  }) {
    return Article(
      id: id,
      sourceId: sourceId,
      sourceName: sourceName,
      sourceIconUrl: sourceIconUrl,
      title: title,
      author: author,
      publishedAt: publishedAt,
      contentHtml: contentHtml,
      excerpt: excerpt,
      articleUrl: articleUrl,
      isRead: isRead ?? this.isRead,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      readAt: readAt ?? this.readAt,
      savedAsFavoriteAt: savedAsFavoriteAt ?? this.savedAsFavoriteAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sourceId,
        sourceName,
        sourceIconUrl,
        title,
        author,
        publishedAt,
        contentHtml,
        excerpt,
        articleUrl,
        isRead,
        isFavorite,
        isArchived,
        readAt,
        savedAsFavoriteAt,
      ];
}
