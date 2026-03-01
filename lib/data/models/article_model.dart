import 'package:hive_ce/hive.dart';

import '../../domain/entities/article.dart';

part 'article_model.g.dart';

@HiveType(typeId: 1)
class ArticleModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String sourceId;

  @HiveField(2)
  String sourceName;

  @HiveField(3)
  String? sourceIconUrl;

  @HiveField(4)
  String title;

  @HiveField(5)
  String? author;

  @HiveField(6)
  DateTime publishedAt;

  @HiveField(7)
  String? contentHtml;

  @HiveField(8)
  String? excerpt;

  @HiveField(9)
  String articleUrl;

  @HiveField(10)
  bool isRead;

  @HiveField(11)
  bool isFavorite;

  @HiveField(12)
  bool isArchived;

  @HiveField(13)
  DateTime? readAt;

  @HiveField(14)
  DateTime? savedAsFavoriteAt;

  ArticleModel({
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

  factory ArticleModel.fromEntity(Article entity) => ArticleModel(
        id: entity.id,
        sourceId: entity.sourceId,
        sourceName: entity.sourceName,
        sourceIconUrl: entity.sourceIconUrl,
        title: entity.title,
        author: entity.author,
        publishedAt: entity.publishedAt,
        contentHtml: entity.contentHtml,
        excerpt: entity.excerpt,
        articleUrl: entity.articleUrl,
        isRead: entity.isRead,
        isFavorite: entity.isFavorite,
        isArchived: entity.isArchived,
        readAt: entity.readAt,
        savedAsFavoriteAt: entity.savedAsFavoriteAt,
      );

  Article toEntity() => Article(
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
        isRead: isRead,
        isFavorite: isFavorite,
        isArchived: isArchived,
        readAt: readAt,
        savedAsFavoriteAt: savedAsFavoriteAt,
      );
}
