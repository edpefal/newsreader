import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/features/favorites/domain/usecases/get_favorites.dart';

part 'favorites_state.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  final GetFavorites _getFavorites;

  FavoritesCubit(this._getFavorites) : super(const FavoritesLoading());

  Future<void> loadFavorites() async {
    emit(const FavoritesLoading());
    final articles = await _getFavorites.execute();
    emit(FavoritesLoaded(articles));
  }
}
