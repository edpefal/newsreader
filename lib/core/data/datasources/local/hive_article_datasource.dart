import 'package:hive_ce/hive.dart';

import 'package:newsreader/core/data/models/article_model.dart';
import 'package:newsreader/core/data/datasources/local/article_local_datasource.dart';

class HiveArticleDatasource implements ArticleLocalDataSource {
  final Box<ArticleModel> _box;

  const HiveArticleDatasource(this._box);

  Iterable<ArticleModel> get _live =>
      _box.values.where((a) => a.deletedAt == null);

  @override
  Future<List<ArticleModel>> getInboxArticles() async {
    final articles = _live.where((a) => !a.isRead).toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return articles;
  }

  @override
  Future<List<ArticleModel>> getFavorites() async {
    final articles = _live.where((a) => a.isFavorite).toList()
      ..sort((a, b) {
        final aDate = a.savedAsFavoriteAt ?? a.publishedAt;
        final bDate = b.savedAsFavoriteAt ?? b.publishedAt;
        return bDate.compareTo(aDate);
      });
    return articles;
  }

  @override
  Future<List<ArticleModel>> getArchive() async {
    final articles = _live.where((a) => a.isRead).toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return articles;
  }

  @override
  Future<List<ArticleModel>> getArticlesBySource(String sourceId) async =>
      _live.where((a) => a.sourceId == sourceId).toList()
        ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

  @override
  Future<ArticleModel?> getArticleById(String id) async {
    final model = _box.get(id);
    return model?.deletedAt == null ? model : null;
  }

  @override
  Future<void> saveArticle(ArticleModel model) async {
    model.updatedAt = DateTime.now();
    await _box.put(model.id, model);
  }

  @override
  Future<void> updateArticle(ArticleModel model) async {
    model.updatedAt = DateTime.now();
    await _box.put(model.id, model);
  }

  @override
  Future<void> deleteArticle(String id) async {
    final model = _box.get(id);
    if (model == null) return;
    final now = DateTime.now();
    model
      ..deletedAt = now
      ..updatedAt = now;
    await _box.put(id, model);
  }

  @override
  Future<void> deleteArticlesBySource(
    String sourceId, {
    bool keepFavorites = true,
  }) async {
    final toDelete = _live
        .where((a) => a.sourceId == sourceId)
        .where((a) => !keepFavorites || !a.isFavorite)
        .toList();
    final now = DateTime.now();
    for (final article in toDelete) {
      article
        ..deletedAt = now
        ..updatedAt = now;
      await _box.put(article.id, article);
    }
  }

  @override
  Future<bool> articleExists(String articleUrl) async =>
      _live.any((a) => a.articleUrl == articleUrl);

  @override
  Future<List<ArticleModel>> getArchivedArticles() async =>
      _live.where((a) => a.isArchived).toList();

  @override
  Future<List<ArticleModel>> getChangedSince(DateTime? since) async =>
      _box.values
          .where((a) => since == null || (a.updatedAt?.isAfter(since) ?? true))
          .toList();

  @override
  Future<void> applyRemote(ArticleModel model) async =>
      _box.put(model.id, model);

  @override
  Future<void> purge(String id) async => _box.delete(id);

  @override
  Future<void> clearAll() async => _box.clear();
}
