import 'package:newsreader/core/domain/entities/ai_usage_status.dart';

/// Consumo del límite diario de resúmenes de artículo (ver capability
/// `ai-usage-budget`). El servidor es la única fuente de verdad que
/// realmente aplica el límite (vía `check_and_record_ai_usage`); este
/// repositorio expone lo que el dispositivo sabe al respecto, para mostrar
/// un indicador sin depender de que una solicitud falle primero.
abstract class AiUsageRepository {
  /// Consumo del día en curso según lo sincronizado con el servidor (ver
  /// `SyncUserData`) más cualquier uso registrado localmente desde entonces
  /// (ver [recordLocalUsage]). Si el día sincronizado no es hoy (día del
  /// dispositivo), se trata como 0 consumido.
  Future<AiUsageStatus> getStatus();

  /// Registra localmente que se generó 1 resumen de artículo, sin esperar
  /// al próximo `SyncUserData` -- ver `GenerateArticleSummary`.
  Future<void> recordLocalUsage();
}
