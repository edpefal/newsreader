part of 'sources_cubit.dart';

sealed class SourcesState extends Equatable {
  const SourcesState();
}

final class SourcesLoading extends SourcesState {
  const SourcesLoading();

  @override
  List<Object?> get props => [];
}

final class SourcesLoaded extends SourcesState {
  final List<NewsSource> sources;

  const SourcesLoaded(this.sources);

  @override
  List<Object?> get props => [sources];
}
