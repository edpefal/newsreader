import 'package:newsreader/core/data/models/daily_summary_free_usage_model.dart';

abstract class DailySummaryFreeUsageLocalDataSource {
  /// Última copia conocida del cupo gratis semanal, o `null` si nunca se
  /// sincronizó ni se registró uso local todavía.
  Future<DailySummaryFreeUsageModel?> get();

  /// Reemplaza la copia local con lo que devolvió el servidor (ver
  /// `SyncUserData`).
  Future<void> applyRemote(DailySummaryFreeUsageModel model);

  /// Marca el cupo gratis de la semana calendario en curso como usado, sin
  /// esperar al próximo sync -- ver
  /// `DailySummaryFreeUsageRepository.recordLocalUsage`.
  Future<void> recordLocalUsage();
}
