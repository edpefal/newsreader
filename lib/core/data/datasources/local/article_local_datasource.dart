import 'package:newsreader/core/data/models/article_model.dart';

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
  Future<List<ArticleModel>> getArchivedArticles();

  /// Todos los artículos (incluidos los soft-deleted) con `updatedAt`
  /// posterior a [since], o todos si [since] es `null`. Usado por el
  /// sync con la nube — a diferencia de los demás getters, no filtra
  /// borrados lógicos, porque el sync necesita ver los tombstones para
  /// propagarlos.
  Future<List<ArticleModel>> getChangedSince(DateTime? since);

  /// Aplica un artículo recibido de la nube tal cual (sin re-estampar
  /// `updatedAt`, a diferencia de [saveArticle]/[updateArticle]): se
  /// confía en el `updatedAt` que ya trae desde Postgres.
  Future<void> applyRemote(ArticleModel model);

  /// Borra físicamente un artículo (usado al recibir un tombstone remoto
  /// ya confirmado, o al purgar un tombstone local ya subido).
  Future<void> purge(String id);

  /// Borra todos los artículos locales (usado al cerrar sesión, para que
  /// la próxima cuenta que inicie sesión en este dispositivo arranque sin
  /// datos de la cuenta anterior y sin colisiones de `id` al sincronizar).
  Future<void> clearAll();
}
