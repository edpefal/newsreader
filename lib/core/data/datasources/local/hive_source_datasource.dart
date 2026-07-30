import 'package:hive_ce/hive.dart';

import 'package:newsreader/core/data/models/news_source_model.dart';
import 'package:newsreader/core/data/datasources/local/source_local_datasource.dart';

class HiveSourceDatasource implements SourceLocalDataSource {
  final Box<NewsSourceModel> _box;

  const HiveSourceDatasource(this._box);

  Iterable<NewsSourceModel> get _live =>
      _box.values.where((s) => s.deletedAt == null);

  @override
  Future<List<NewsSourceModel>> getSources() async => _live.toList();

  @override
  Future<void> saveSource(NewsSourceModel model) async {
    model.updatedAt = DateTime.now();
    await _box.put(model.id, model);
  }

  @override
  Future<void> updateSource(NewsSourceModel model) async {
    model.updatedAt = DateTime.now();
    await _box.put(model.id, model);
  }

  @override
  Future<void> deleteSource(String id) async {
    final model = _box.get(id);
    if (model == null) return;
    final now = DateTime.now();
    model
      ..deletedAt = now
      ..updatedAt = now;
    await _box.put(id, model);
  }

  @override
  Future<bool> sourceExists(String feedUrl) async =>
      _live.any((s) => s.feedUrl == feedUrl);

  @override
  Future<List<NewsSourceModel>> getChangedSince(DateTime? since) async =>
      _box.values
          .where((s) => since == null || (s.updatedAt?.isAfter(since) ?? true))
          .toList();

  @override
  Future<void> applyRemote(NewsSourceModel model) async =>
      _box.put(model.id, model);

  @override
  Future<void> purge(String id) async => _box.delete(id);

  @override
  Future<void> clearAll() async => _box.clear();
}
