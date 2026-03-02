import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/core/domain/repositories/source_repository.dart';
import 'package:newsreader/core/data/datasources/local/source_local_datasource.dart';
import 'package:newsreader/core/data/models/news_source_model.dart';

class SourceRepositoryImpl implements SourceRepository {
  final SourceLocalDataSource _localDataSource;

  const SourceRepositoryImpl(this._localDataSource);

  @override
  Future<List<NewsSource>> getSources() async {
    final models = await _localDataSource.getSources();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<NewsSource> addSource(NewsSource source) async {
    final model = NewsSourceModel.fromEntity(source);
    await _localDataSource.saveSource(model);
    return source;
  }

  @override
  Future<void> updateSource(NewsSource source) async {
    await _localDataSource.updateSource(NewsSourceModel.fromEntity(source));
  }

  @override
  Future<void> deleteSource(String sourceId) async {
    await _localDataSource.deleteSource(sourceId);
  }

  @override
  Future<bool> sourceExists(String feedUrl) =>
      _localDataSource.sourceExists(feedUrl);
}
