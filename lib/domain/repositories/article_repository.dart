import '../entities/article.dart';

abstract class ArticleRepository {
  Future<List<Article>> getInboxArticles();
  Future<List<Article>> getFavorites();
  Future<List<Article>> getArchive();
  Future<List<Article>> getArticlesBySource(String sourceId);
  Future<Article?> getArticleById(String id);
  Future<void> saveArticle(Article article);
  Future<void> updateArticle(Article article);
  Future<void> deleteArticle(String id);
  Future<void> deleteArticlesBySource(String sourceId, {bool keepFavorites = true});
  Future<bool> articleExists(String articleUrl);
  Future<List<Article>> getReadArticlesOlderThan(DateTime date);
  Future<List<Article>> getUnreadNonArchivedArticlesOlderThan(DateTime date);
}
