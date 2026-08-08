import 'package:newsreader/core/domain/entities/news_source.dart';

/// Determina si [source] coincide con [query] para propósitos de búsqueda
/// local: coincidencia por substring, insensible a mayúsculas/minúsculas,
/// sobre nombre y autor. Un [query] vacío o solo espacios matchea
/// cualquier fuente.
bool sourceMatchesQuery(NewsSource source, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return true;

  return source.name.toLowerCase().contains(normalizedQuery) ||
      (source.author?.toLowerCase().contains(normalizedQuery) ?? false);
}
