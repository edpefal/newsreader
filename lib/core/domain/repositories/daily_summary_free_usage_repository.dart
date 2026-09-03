import 'package:newsreader/core/domain/entities/daily_summary_free_usage_status.dart';

/// Cupo gratis semanal de resumen diario (ver capability `ai-usage-budget`).
/// El servidor es la única fuente de verdad que realmente aplica el límite
/// (vía `check_and_record_daily_summary_free_usage`); este repositorio
/// expone lo que el dispositivo sabe al respecto, para mostrar un
/// indicador sin depender de que una solicitud falle primero. Solo aplica
/// a usuarios sin suscripción activa.
abstract class DailySummaryFreeUsageRepository {
  /// Estado de la semana calendario en curso según lo sincronizado con el
  /// servidor (ver `SyncUserData`) más cualquier uso registrado localmente
  /// desde entonces (ver [recordLocalUsage]). Si la semana sincronizada no
  /// es la semana calendario en curso (día del dispositivo), se trata como
  /// cupo disponible (no usado).
  Future<DailySummaryFreeUsageStatus> getStatus();

  /// Registra localmente que se generó 1 resumen diario gratis, sin
  /// esperar al próximo `SyncUserData` -- ver `GenerateDailySummary`.
  Future<void> recordLocalUsage();
}
