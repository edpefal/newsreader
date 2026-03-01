import '../entities/news_source.dart';

abstract class SourceRepository {
  Future<List<NewsSource>> getSources();
  Future<NewsSource> addSource(NewsSource source);
  Future<void> updateSource(NewsSource source);
  Future<void> deleteSource(String sourceId);
  Future<bool> sourceExists(String feedUrl);
}
