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

  const SummariesLoaded({
    required this.summaries,
    required this.canGenerateToday,
    required this.alreadyGeneratedToday,
  });

  @override
  List<Object?> get props => [summaries, canGenerateToday, alreadyGeneratedToday];
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
