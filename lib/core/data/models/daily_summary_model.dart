import 'package:hive_ce/hive.dart';

import 'package:newsreader/core/domain/entities/daily_summary.dart';

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

  DailySummaryModel({
    required this.id,
    required this.date,
    required this.content,
    required this.articleCount,
    required this.createdAt,
  });

  factory DailySummaryModel.fromEntity(DailySummary entity) =>
      DailySummaryModel(
        id: entity.id,
        date: entity.date,
        content: entity.content,
        articleCount: entity.articleCount,
        createdAt: entity.createdAt,
      );

  DailySummary toEntity() => DailySummary(
        id: id,
        date: date,
        content: content,
        articleCount: articleCount,
        createdAt: createdAt,
      );
}
