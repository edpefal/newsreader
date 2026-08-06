import 'dart:convert';

import 'package:newsreader/features/favorites/domain/usecases/get_favorites.dart';

/// Genera un JSON con los artículos favoritos del usuario, para que pueda
/// conservarlos independientemente de la app (ver capability `data-export`).
class ExportFavoritesJson {
  final GetFavorites _getFavorites;

  const ExportFavoritesJson(this._getFavorites);

  Future<String> execute() async {
    final favorites = await _getFavorites.execute();

    final data = favorites
        .map((article) => {
              'title': article.title,
              'articleUrl': article.articleUrl,
              'sourceName': article.sourceName,
              'savedAsFavoriteAt': article.savedAsFavoriteAt?.toIso8601String(),
            })
        .toList();

    return const JsonEncoder.withIndent('  ').convert(data);
  }
}
