import 'package:hive_ce/hive.dart';

import '../../models/article_model.dart';
import 'article_local_datasource.dart';

class HiveArticleDatasource implements ArticleLocalDataSource {
  final Box<ArticleModel> _box;

  const HiveArticleDatasource(this._box);

  @override
  Future<List<ArticleModel>> getInboxArticles() async {
    final articles = _box.values
        .where((a) => !a.isRead && !a.isArchived)
        .toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return articles;
  }

  @override
  Future<List<ArticleModel>> getFavorites() async {
    final articles = _box.values.where((a) => a.isFavorite).toList()
      ..sort((a, b) {
        final aDate = a.savedAsFavoriteAt ?? a.publishedAt;
        final bDate = b.savedAsFavoriteAt ?? b.publishedAt;
        return bDate.compareTo(aDate);
      });
    return articles;
  }

  @override
  Future<List<ArticleModel>> getArchive() async {
    final articles = _box.values
        .where((a) => a.isArchived && !a.isRead)
        .toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return articles;
  }

  @override
  Future<List<ArticleModel>> getArticlesBySource(String sourceId) async =>
      _box.values.where((a) => a.sourceId == sourceId).toList();

  @override
  Future<ArticleModel?> getArticleById(String id) async => _box.get(id);

  @override
  Future<void> saveArticle(ArticleModel model) async =>
      _box.put(model.id, model);

  @override
  Future<void> updateArticle(ArticleModel model) async =>
      _box.put(model.id, model);

  @override
  Future<void> deleteArticle(String id) async => _box.delete(id);

  @override
  Future<void> deleteArticlesBySource(
    String sourceId, {
    bool keepFavorites = true,
  }) async {
    final toDelete = _box.values
        .where((a) => a.sourceId == sourceId)
        .where((a) => !keepFavorites || !a.isFavorite)
        .toList();
    for (final article in toDelete) {
      await _box.delete(article.id);
    }
  }

  @override
  Future<bool> articleExists(String articleUrl) async =>
      _box.values.any((a) => a.articleUrl == articleUrl);

  @override
  Future<List<ArticleModel>> getReadArticlesOlderThan(DateTime date) async =>
      _box.values
          .where((a) => a.isRead && !a.isFavorite && a.publishedAt.isBefore(date))
          .toList();

  @override
  Future<List<ArticleModel>> getUnreadNonArchivedArticlesOlderThan(
    DateTime date,
  ) async =>
      _box.values
          .where(
            (a) => !a.isRead && !a.isArchived && a.publishedAt.isBefore(date),
          )
          .toList();
}
