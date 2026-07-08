import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/repositories/article_repository.dart';
import 'package:newsreader/core/data/datasources/local/article_local_datasource.dart';
import 'package:newsreader/core/data/models/article_model.dart';

class ArticleRepositoryImpl implements ArticleRepository {
  final ArticleLocalDataSource _localDataSource;

  const ArticleRepositoryImpl(this._localDataSource);

  @override
  Future<List<Article>> getInboxArticles() async {
    final models = await _localDataSource.getInboxArticles();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Article>> getFavorites() async {
    final models = await _localDataSource.getFavorites();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Article>> getArchive() async {
    final models = await _localDataSource.getArchive();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Article>> getArticlesBySource(String sourceId) async {
    final models = await _localDataSource.getArticlesBySource(sourceId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Article?> getArticleById(String id) async {
    final model = await _localDataSource.getArticleById(id);
    return model?.toEntity();
  }

  @override
  Future<void> saveArticle(Article article) =>
      _localDataSource.saveArticle(ArticleModel.fromEntity(article));

  @override
  Future<void> updateArticle(Article article) =>
      _localDataSource.updateArticle(ArticleModel.fromEntity(article));

  @override
  Future<void> deleteArticle(String id) => _localDataSource.deleteArticle(id);

  @override
  Future<void> deleteArticlesBySource(
    String sourceId, {
    bool keepFavorites = true,
  }) =>
      _localDataSource.deleteArticlesBySource(
        sourceId,
        keepFavorites: keepFavorites,
      );

  @override
  Future<bool> articleExists(String articleUrl) =>
      _localDataSource.articleExists(articleUrl);

  @override
  Future<List<Article>> getArchivedArticles() async {
    final models = await _localDataSource.getArchivedArticles();
    return models.map((m) => m.toEntity()).toList();
  }
}
