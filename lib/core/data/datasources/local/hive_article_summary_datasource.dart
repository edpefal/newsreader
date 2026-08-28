import 'package:hive_ce/hive.dart';

import 'package:newsreader/core/data/datasources/local/article_summary_local_datasource.dart';
import 'package:newsreader/core/data/models/article_summary_model.dart';

class HiveArticleSummaryDatasource implements ArticleSummaryLocalDataSource {
  final Box<ArticleSummaryModel> _box;

  const HiveArticleSummaryDatasource(this._box);

  @override
  Future<ArticleSummaryModel?> getByArticleId(String articleId) async =>
      _box.get(articleId);

  @override
  Future<void> save(ArticleSummaryModel model) async =>
      _box.put(model.articleId, model);
}
