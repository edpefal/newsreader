part of 'source_detail_cubit.dart';

sealed class SourceDetailState extends Equatable {
  const SourceDetailState();
}

final class SourceDetailLoading extends SourceDetailState {
  const SourceDetailLoading();

  @override
  List<Object?> get props => [];
}

final class SourceDetailLoaded extends SourceDetailState {
  final List<Article> articles;

  const SourceDetailLoaded(this.articles);

  @override
  List<Object?> get props => [articles];
}
