import 'package:hive_ce/hive.dart';

import 'package:newsreader/core/domain/entities/news_source.dart';

part 'news_source_model.g.dart';

@HiveType(typeId: 0)
class NewsSourceModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String feedUrl;

  @HiveField(3)
  String? author;

  @HiveField(4)
  String? iconUrl;

  @HiveField(5)
  DateTime addedAt;

  @HiveField(6)
  DateTime? lastSyncedAt;

  @HiveField(7)
  bool hasError;

  NewsSourceModel({
    required this.id,
    required this.name,
    required this.feedUrl,
    this.author,
    this.iconUrl,
    required this.addedAt,
    this.lastSyncedAt,
    this.hasError = false,
  });

  factory NewsSourceModel.fromEntity(NewsSource entity) => NewsSourceModel(
        id: entity.id,
        name: entity.name,
        feedUrl: entity.feedUrl,
        author: entity.author,
        iconUrl: entity.iconUrl,
        addedAt: entity.addedAt,
        lastSyncedAt: entity.lastSyncedAt,
        hasError: entity.hasError,
      );

  NewsSource toEntity() => NewsSource(
        id: id,
        name: name,
        feedUrl: feedUrl,
        author: author,
        iconUrl: iconUrl,
        addedAt: addedAt,
        lastSyncedAt: lastSyncedAt,
        hasError: hasError,
      );
}
