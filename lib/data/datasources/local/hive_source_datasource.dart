import 'package:hive_ce/hive.dart';

import '../../models/news_source_model.dart';
import 'source_local_datasource.dart';

class HiveSourceDatasource implements SourceLocalDataSource {
  final Box<NewsSourceModel> _box;

  const HiveSourceDatasource(this._box);

  @override
  Future<List<NewsSourceModel>> getSources() async =>
      _box.values.toList();

  @override
  Future<void> saveSource(NewsSourceModel model) async =>
      _box.put(model.id, model);

  @override
  Future<void> updateSource(NewsSourceModel model) async =>
      _box.put(model.id, model);

  @override
  Future<void> deleteSource(String id) async => _box.delete(id);

  @override
  Future<bool> sourceExists(String feedUrl) async =>
      _box.values.any((s) => s.feedUrl == feedUrl);
}
