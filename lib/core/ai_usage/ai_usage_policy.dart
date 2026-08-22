import 'package:equatable/equatable.dart';

/// Abstracción sobre el estado de presupuesto diario de IA del usuario
/// actual (ver capability `ai-usage-budget`). Sigue la regla de
/// abstracciones del proyecto: ningún SDK de terceros se importa directo en
/// `domain/`/`presentation/` -- mismo patrón que `SubscriptionStatusProvider`.
///
/// No expone un `canGenerate()`/`recordUsage()`: la autoridad real sobre el
/// presupuesto vive del lado del servidor (`check_and_record_ai_usage`), así
/// que un chequeo previo del cliente sería solo asesorio y podría quedar
/// stale entre que se muestra y que efectivamente se dispara la generación.
abstract class AiUsagePolicy {
  Future<AiUsageStatus> getStatus();
}

class AiUsageStatus extends Equatable {
  final int wordsUsed;
  final int wordLimit;
  final DateTime resetsAt;

  const AiUsageStatus({
    required this.wordsUsed,
    required this.wordLimit,
    required this.resetsAt,
  });

  bool get isLimitReached => wordsUsed >= wordLimit;

  @override
  List<Object?> get props => [wordsUsed, wordLimit, resetsAt];
}
