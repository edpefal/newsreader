import 'package:equatable/equatable.dart';

/// Consumo del límite diario de resúmenes de artículo del usuario (ver
/// capability `ai-usage-budget`), tal como lo conoce el dispositivo -- entre
/// el último `SyncUserData` y el último resumen generado localmente (ver
/// `AiUsageRepository.recordLocalUsage`). El servidor sigue siendo la única
/// fuente de verdad que efectivamente aplica el límite.
class AiUsageStatus extends Equatable {
  final int summariesUsedToday;
  final int dailyLimit;

  const AiUsageStatus({
    required this.summariesUsedToday,
    required this.dailyLimit,
  });

  int get remaining => (dailyLimit - summariesUsedToday).clamp(0, dailyLimit);

  bool get limitReached => remaining <= 0;

  @override
  List<Object?> get props => [summariesUsedToday, dailyLimit];
}
