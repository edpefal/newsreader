import 'package:equatable/equatable.dart';

/// Consumo del cupo gratis semanal de resumen diario del usuario (ver
/// capability `ai-usage-budget`), tal como lo conoce el dispositivo -- entre
/// el último `SyncUserData` y el último resumen gratis generado localmente
/// (ver `DailySummaryFreeUsageRepository.recordLocalUsage`). El servidor
/// sigue siendo la única fuente de verdad que efectivamente aplica el
/// límite. Solo aplica a usuarios sin suscripción activa -- un usuario
/// suscripto no consulta ni consume este cupo.
class DailySummaryFreeUsageStatus extends Equatable {
  final bool usedThisWeek;
  final DateTime weekStart;

  const DailySummaryFreeUsageStatus({
    required this.usedThisWeek,
    required this.weekStart,
  });

  bool get available => !usedThisWeek;

  @override
  List<Object?> get props => [usedThisWeek, weekStart];
}
