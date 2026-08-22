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
  final AiUsageStatus usage;

  const SummariesLoaded({
    required this.summaries,
    required this.canGenerateToday,
    required this.usage,
  });

  @override
  List<Object?> get props => [summaries, canGenerateToday, usage];
}

final class SummaryGenerating extends SummariesState {
  final List<DailySummary> summaries;
  final AiUsageStatus usage;

  const SummaryGenerating(this.summaries, this.usage);

  @override
  List<Object?> get props => [summaries, usage];
}

final class SummaryGenerationError extends SummariesState {
  final List<DailySummary> summaries;
  final bool canGenerateToday;
  final AppErrorCode code;
  final AiUsageStatus usage;

  const SummaryGenerationError({
    required this.summaries,
    required this.canGenerateToday,
    required this.code,
    required this.usage,
  });

  @override
  List<Object?> get props => [summaries, canGenerateToday, code, usage];
}
