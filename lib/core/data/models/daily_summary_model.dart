import 'package:hive_ce/hive.dart';

import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/domain/entities/summary_source_block.dart';

part 'daily_summary_model.g.dart';

@HiveType(typeId: 2)
class DailySummaryModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String content;

  @HiveField(3)
  int articleCount;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime? updatedAt;

  @HiveField(6)
  List<Map<dynamic, dynamic>>? sourceBlocks;

  DailySummaryModel({
    required this.id,
    required this.date,
    required this.content,
    required this.articleCount,
    required this.createdAt,
    this.updatedAt,
    this.sourceBlocks,
  });

  static List<Map<dynamic, dynamic>>? _sourceBlocksToMaps(
    List<SummarySourceBlock>? blocks,
  ) {
    if (blocks == null) return null;
    return blocks
        .map((b) => {
              'sourceId': b.sourceId,
              'sourceName': b.sourceName,
              'articleIds': b.articleIds,
            })
        .toList();
  }

  static List<SummarySourceBlock>? _sourceBlocksFromMaps(
    List<Map<dynamic, dynamic>>? maps,
  ) {
    if (maps == null) return null;
    return maps
        .map((m) => SummarySourceBlock(
              sourceId: m['sourceId'] as String,
              sourceName: m['sourceName'] as String,
              articleIds: (m['articleIds'] as List).cast<String>(),
            ))
        .toList();
  }

  factory DailySummaryModel.fromEntity(DailySummary entity) =>
      DailySummaryModel(
        id: entity.id,
        date: entity.date,
        content: entity.content,
        articleCount: entity.articleCount,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
        sourceBlocks: _sourceBlocksToMaps(entity.sourceBlocks),
      );

  DailySummary toEntity() => DailySummary(
        id: id,
        date: date,
        content: content,
        articleCount: articleCount,
        createdAt: createdAt,
        updatedAt: updatedAt,
        sourceBlocks: _sourceBlocksFromMaps(sourceBlocks),
      );
}
