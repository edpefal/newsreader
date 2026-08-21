part of 'inbox_cubit.dart';

sealed class InboxState extends Equatable {
  const InboxState();
}

final class InboxLoading extends InboxState {
  final bool isSyncing;

  const InboxLoading({this.isSyncing = false});

  @override
  List<Object?> get props => [isSyncing];
}

final class InboxLoaded extends InboxState {
  final List<Article> articles;
  final bool hasSources;
  final String? readArticleId;
  final bool isSyncingInBackground;
  final String searchQuery;

  const InboxLoaded(
    this.articles, {
    required this.hasSources,
    this.readArticleId,
    this.isSyncingInBackground = false,
    this.searchQuery = '',
  });

  List<Article> get visibleArticles => searchQuery.isEmpty
      ? articles
      : articles.where((a) => articleMatchesQuery(a, searchQuery)).toList();

  @override
  List<Object?> get props => [
    articles,
    hasSources,
    readArticleId,
    isSyncingInBackground,
    searchQuery,
  ];
}
