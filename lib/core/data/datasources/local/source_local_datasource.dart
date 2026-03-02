import 'package:newsreader/core/data/models/news_source_model.dart';

abstract class SourceLocalDataSource {
  Future<List<NewsSourceModel>> getSources();
  Future<void> saveSource(NewsSourceModel model);
  Future<void> updateSource(NewsSourceModel model);
  Future<void> deleteSource(String id);
  Future<bool> sourceExists(String feedUrl);
}
