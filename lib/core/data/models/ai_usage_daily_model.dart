import 'package:hive_ce/hive.dart';

part 'ai_usage_daily_model.g.dart';

/// Copia local, de solo lectura, de la fila `ai_usage_daily` del usuario
/// (ver capability `ai-usage-budget`). A diferencia de `sources`/`articles`,
/// el cliente nunca sube cambios de esta tabla -- solo se sincroniza en
/// sentido servidor-a-cliente vía `SyncUserData`, más los incrementos
/// optimistas locales de `recordLocalUsage` entre sincronizaciones.
@HiveType(typeId: 4)
class AiUsageDailyModel extends HiveObject {
  @HiveField(0)
  DateTime day;

  @HiveField(1)
  int summariesUsed;

  AiUsageDailyModel({required this.day, required this.summariesUsed});
}
