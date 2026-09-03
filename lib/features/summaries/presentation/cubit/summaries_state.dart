part of 'summaries_cubit.dart';

sealed class SummariesState extends Equatable {
  const SummariesState();
}

final class SummariesLoading extends SummariesState {
  const SummariesLoading();

  @override
  List<Object?> get props => [];
}

final class SummariesLoaded extends SummariesState {
  final List<DailySummary> summaries;
  final bool canGenerateToday;
  final bool alreadyGeneratedToday;

  /// `true` si el usuario tiene suscripción activa -- en ese caso el cupo
  /// gratis semanal (`freeTierAvailable`) es irrelevante, nunca se consulta
  /// ni se muestra.
  final bool isSubscribed;

  /// Cupo gratis semanal de resumen diario disponible (ver capability
  /// `ai-usage-budget`). Solo tiene sentido cuando `isSubscribed` es
  /// `false`; con suscripción activa siempre es `true` sin haberse
  /// consultado.
  final bool freeTierAvailable;

  const SummariesLoaded({
    required this.summaries,
    required this.canGenerateToday,
    required this.alreadyGeneratedToday,
    required this.isSubscribed,
    required this.freeTierAvailable,
  });

  @override
  List<Object?> get props => [
        summaries,
        canGenerateToday,
        alreadyGeneratedToday,
        isSubscribed,
        freeTierAvailable,
      ];
}

final class SummaryGenerating extends SummariesState {
  final List<DailySummary> summaries;

  const SummaryGenerating(this.summaries);

  @override
  List<Object?> get props => [summaries];
}

final class SummaryGenerationError extends SummariesState {
  final List<DailySummary> summaries;
  final bool canGenerateToday;
  final AppErrorCode code;

  const SummaryGenerationError({
    required this.summaries,
    required this.canGenerateToday,
    required this.code,
  });

  @override
  List<Object?> get props => [summaries, canGenerateToday, code];
}
