import 'package:hive_ce/hive.dart';

part 'daily_summary_free_usage_model.g.dart';

/// Copia local, de solo lectura, de la fila `daily_summary_free_usage` del
/// usuario (ver capability `ai-usage-budget`). Mismo patrón que
/// `AiUsageDailyModel`: el cliente nunca sube cambios de esta tabla, solo
/// se sincroniza en sentido servidor-a-cliente vía `SyncUserData`, más los
/// incrementos optimistas locales de `recordLocalUsage` entre
/// sincronizaciones.
@HiveType(typeId: 5)
class DailySummaryFreeUsageModel extends HiveObject {
  @HiveField(0)
  DateTime weekStart;

  @HiveField(1)
  bool used;

  DailySummaryFreeUsageModel({required this.weekStart, required this.used});
}
