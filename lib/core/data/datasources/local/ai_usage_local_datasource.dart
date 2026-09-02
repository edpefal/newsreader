import 'package:newsreader/core/data/models/ai_usage_daily_model.dart';

abstract class AiUsageLocalDataSource {
  /// Última copia conocida del consumo diario, o `null` si nunca se
  /// sincronizó ni se registró uso local todavía.
  Future<AiUsageDailyModel?> get();

  /// Reemplaza la copia local con lo que devolvió el servidor (ver
  /// `SyncUserData`).
  Future<void> applyRemote(AiUsageDailyModel model);

  /// Incrementa en 1 el consumo del día en curso, sin esperar al próximo
  /// sync -- ver `AiUsageRepository.recordLocalUsage`.
  Future<void> recordLocalUsage();
}
