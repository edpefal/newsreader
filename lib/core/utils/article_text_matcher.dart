import 'package:newsreader/core/domain/entities/article.dart';

/// Determina si [article] coincide con [query] para propósitos de búsqueda
/// local: coincidencia por substring, insensible a mayúsculas/minúsculas,
/// sobre título, nombre de fuente y autor. No considera `contentHtml` ni
/// `excerpt`. Un [query] vacío o solo espacios matchea cualquier artículo.
bool articleMatchesQuery(Article article, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return true;

  return article.title.toLowerCase().contains(normalizedQuery) ||
      article.sourceName.toLowerCase().contains(normalizedQuery) ||
      (article.author?.toLowerCase().contains(normalizedQuery) ?? false);
}
