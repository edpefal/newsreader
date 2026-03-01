import '../../models/article_model.dart';

abstract class ArticleLocalDataSource {
  Future<List<ArticleModel>> getInboxArticles();
  Future<List<ArticleModel>> getFavorites();
  Future<List<ArticleModel>> getArchive();
  Future<List<ArticleModel>> getArticlesBySource(String sourceId);
  Future<ArticleModel?> getArticleById(String id);
  Future<void> saveArticle(ArticleModel model);
  Future<void> updateArticle(ArticleModel model);
  Future<void> deleteArticle(String id);
  Future<void> deleteArticlesBySource(String sourceId, {bool keepFavorites = true});
  Future<bool> articleExists(String articleUrl);
  Future<List<ArticleModel>> getReadArticlesOlderThan(DateTime date);
  Future<List<ArticleModel>> getUnreadNonArchivedArticlesOlderThan(DateTime date);
}
