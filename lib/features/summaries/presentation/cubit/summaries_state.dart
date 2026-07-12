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

  const SummariesLoaded({
    required this.summaries,
    required this.canGenerateToday,
  });

  @override
  List<Object?> get props => [summaries, canGenerateToday];
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
  final String message;

  const SummaryGenerationError({
    required this.summaries,
    required this.canGenerateToday,
    required this.message,
  });

  @override
  List<Object?> get props => [summaries, canGenerateToday, message];
}
