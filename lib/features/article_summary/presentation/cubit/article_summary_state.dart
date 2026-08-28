part of 'article_summary_cubit.dart';

sealed class ArticleSummaryState extends Equatable {
  const ArticleSummaryState();
}

final class ArticleSummaryLoading extends ArticleSummaryState {
  const ArticleSummaryLoading();

  @override
  List<Object?> get props => [];
}

final class ArticleSummaryLoaded extends ArticleSummaryState {
  final ArticleSummary summary;

  const ArticleSummaryLoaded(this.summary);

  @override
  List<Object?> get props => [summary];
}

final class ArticleSummaryError extends ArticleSummaryState {
  final AppErrorCode code;

  const ArticleSummaryError(this.code);

  @override
  List<Object?> get props => [code];
}
