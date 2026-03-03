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

  const FavoritesLoaded(this.articles);

  @override
  List<Object?> get props => [articles];
}
