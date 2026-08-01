import 'package:newsreader/core/domain/entities/news_source.dart';

abstract class SourceRepository {
  Future<List<NewsSource>> getSources();

  /// Busca una fuente por su `id`, o `null` si no existe.
  Future<NewsSource?> getSourceById(String id);
  Future<NewsSource> addSource(NewsSource source);
  Future<void> updateSource(NewsSource source);
  Future<void> deleteSource(String sourceId);
  Future<bool> sourceExists(String feedUrl);
}
