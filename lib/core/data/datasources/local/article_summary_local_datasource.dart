import 'package:newsreader/core/data/models/article_summary_model.dart';

abstract class ArticleSummaryLocalDataSource {
  Future<ArticleSummaryModel?> getByArticleId(String articleId);
  Future<void> save(ArticleSummaryModel model);
}
