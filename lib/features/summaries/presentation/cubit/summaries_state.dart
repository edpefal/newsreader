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
  /// `null` cuando todavía no existe ningún resumen.
  final DailySummary? summary;

  const SummariesLoaded({required this.summary});

  @override
  List<Object?> get props => [summary];
}
