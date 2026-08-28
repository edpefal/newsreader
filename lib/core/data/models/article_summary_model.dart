import 'package:hive_ce/hive.dart';

import 'package:newsreader/core/ai/mention_enricher.dart';
import 'package:newsreader/core/domain/entities/article_summary.dart';

part 'article_summary_model.g.dart';

@HiveType(typeId: 3)
class ArticleSummaryModel extends HiveObject {
  @HiveField(0)
  String articleId;

  @HiveField(1)
  String summary;

  @HiveField(2)
  List<Map<dynamic, dynamic>> mentions;

  @HiveField(3)
  DateTime createdAt;

  ArticleSummaryModel({
    required this.articleId,
    required this.summary,
    required this.mentions,
    required this.createdAt,
  });

  static List<Map<dynamic, dynamic>> _mentionsToMaps(
    List<EnrichedMention> mentions,
  ) =>
      mentions
          .map((m) => {
                'type': m.type.wireValue,
                'name': m.name,
                'imageUrl': m.imageUrl,
                'link': m.link,
              })
          .toList();

  static List<EnrichedMention> _mentionsFromMaps(
    List<Map<dynamic, dynamic>> maps,
  ) =>
      maps
          .map((m) => (
                type: MentionTypeWireFormat.fromWireValue(m['type'] as String),
                name: m['name'] as String,
                imageUrl: m['imageUrl'] as String?,
                link: m['link'] as String?,
              ))
          .toList();

  factory ArticleSummaryModel.fromEntity(ArticleSummary entity) =>
      ArticleSummaryModel(
        articleId: entity.articleId,
        summary: entity.summary,
        mentions: _mentionsToMaps(entity.mentions),
        createdAt: entity.createdAt,
      );

  ArticleSummary toEntity() => ArticleSummary(
        articleId: articleId,
        summary: summary,
        mentions: _mentionsFromMaps(mentions),
        createdAt: createdAt,
      );
}
