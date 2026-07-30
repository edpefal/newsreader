import 'package:newsreader/core/data/models/daily_summary_model.dart';

abstract class SummaryLocalDataSource {
  Future<List<DailySummaryModel>> getAll();
  Future<void> save(DailySummaryModel model);
  Future<DailySummaryModel?> getByDate(DateTime date);

  /// Todos los resúmenes con `updatedAt` posterior a [since], o todos si
  /// [since] es `null`. Usado por el sync.
  Future<List<DailySummaryModel>> getChangedSince(DateTime? since);

  /// Aplica un resumen recibido de la nube tal cual (sin re-estampar
  /// `updatedAt`).
  Future<void> applyRemote(DailySummaryModel model);

  /// Borra todos los resúmenes locales (usado al cerrar sesión).
  Future<void> clearAll();
}
