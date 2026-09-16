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

  const SummariesLoaded({required this.summaries});

  @override
  List<Object?> get props => [summaries];
}
