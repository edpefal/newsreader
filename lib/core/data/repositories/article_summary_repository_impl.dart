import 'package:newsreader/core/data/datasources/local/article_summary_local_datasource.dart';
import 'package:newsreader/core/data/models/article_summary_model.dart';
import 'package:newsreader/core/domain/entities/article_summary.dart';
import 'package:newsreader/core/domain/repositories/article_summary_repository.dart';

class ArticleSummaryRepositoryImpl implements ArticleSummaryRepository {
  final ArticleSummaryLocalDataSource _dataSource;

  const ArticleSummaryRepositoryImpl(this._dataSource);

  @override
  Future<ArticleSummary?> getByArticleId(String articleId) async {
    final model = await _dataSource.getByArticleId(articleId);
    return model?.toEntity();
  }

  @override
  Future<void> save(ArticleSummary summary) =>
      _dataSource.save(ArticleSummaryModel.fromEntity(summary));
}
