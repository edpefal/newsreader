import 'package:newsreader/core/data/models/news_source_model.dart';

abstract class SourceLocalDataSource {
  Future<List<NewsSourceModel>> getSources();
  Future<void> saveSource(NewsSourceModel model);
  Future<void> updateSource(NewsSourceModel model);
  Future<void> deleteSource(String id);
  Future<bool> sourceExists(String feedUrl);

  /// Todas las fuentes (incluidas las soft-deleted) con `updatedAt`
  /// posterior a [since], o todas si [since] es `null`. Usado por el sync.
  Future<List<NewsSourceModel>> getChangedSince(DateTime? since);

  /// Aplica una fuente recibida de la nube tal cual (sin re-estampar
  /// `updatedAt`).
  Future<void> applyRemote(NewsSourceModel model);

  /// Borra físicamente una fuente (tombstone remoto confirmado, o purga de
  /// un tombstone local ya subido).
  Future<void> purge(String id);

  /// Borra todas las fuentes locales (usado al cerrar sesión).
  Future<void> clearAll();
}
