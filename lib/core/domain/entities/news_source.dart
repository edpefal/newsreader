import 'package:equatable/equatable.dart';

class NewsSource extends Equatable {
  final String id;
  final String name;
  final String feedUrl;
  final String? author;
  final String? iconUrl;
  final DateTime addedAt;
  final DateTime? lastSyncedAt;
  final bool hasError;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const NewsSource({
    required this.id,
    required this.name,
    required this.feedUrl,
    this.author,
    this.iconUrl,
    required this.addedAt,
    this.lastSyncedAt,
    this.hasError = false,
    this.updatedAt,
    this.deletedAt,
  });

  NewsSource copyWith({
    String? name,
    DateTime? lastSyncedAt,
    bool? hasError,
    String? iconUrl,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return NewsSource(
      id: id,
      name: name ?? this.name,
      feedUrl: feedUrl,
      author: author,
      iconUrl: iconUrl ?? this.iconUrl,
      addedAt: addedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      hasError: hasError ?? this.hasError,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        feedUrl,
        author,
        iconUrl,
        addedAt,
        lastSyncedAt,
        hasError,
        updatedAt,
        deletedAt,
      ];
}
