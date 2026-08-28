import 'package:newsreader/core/domain/entities/article_summary.dart';

abstract class ArticleSummaryRepository {
  Future<ArticleSummary?> getByArticleId(String articleId);
  Future<void> save(ArticleSummary summary);
}
