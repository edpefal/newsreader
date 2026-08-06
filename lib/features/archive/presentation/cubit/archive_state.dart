part of 'archive_cubit.dart';

sealed class ArchiveState extends Equatable {
  const ArchiveState();
}

final class ArchiveLoading extends ArchiveState {
  const ArchiveLoading();

  @override
  List<Object?> get props => [];
}

final class ArchiveLoaded extends ArchiveState {
  final List<Article> articles;
  final String searchQuery;

  const ArchiveLoaded(this.articles, {this.searchQuery = ''});

  List<Article> get visibleArticles => searchQuery.isEmpty
      ? articles
      : articles.where((a) => articleMatchesQuery(a, searchQuery)).toList();

  @override
  List<Object?> get props => [articles, searchQuery];
}
