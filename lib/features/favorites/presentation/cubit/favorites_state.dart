part of 'favorites_cubit.dart';

sealed class FavoritesState extends Equatable {
  const FavoritesState();
}

final class FavoritesLoading extends FavoritesState {
  const FavoritesLoading();

  @override
  List<Object?> get props => [];
}

final class FavoritesLoaded extends FavoritesState {
  final List<Article> articles;
  final String searchQuery;

  const FavoritesLoaded(this.articles, {this.searchQuery = ''});

  List<Article> get visibleArticles => searchQuery.isEmpty
      ? articles
      : articles.where((a) => articleMatchesQuery(a, searchQuery)).toList();

  @override
  List<Object?> get props => [articles, searchQuery];
}
