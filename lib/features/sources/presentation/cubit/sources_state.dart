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
  final String searchQuery;

  const SourcesLoaded(this.sources, {this.searchQuery = ''});

  List<NewsSource> get visibleSources => searchQuery.isEmpty
      ? sources
      : sources.where((s) => sourceMatchesQuery(s, searchQuery)).toList();

  @override
  List<Object?> get props => [sources, searchQuery];
}
