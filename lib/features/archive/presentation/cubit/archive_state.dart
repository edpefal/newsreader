part of 'archive_cubit.dart';

sealed class ArchiveState extends Equatable {
  const ArchiveState();
}

final class ArchiveLoading extends ArchiveState {
  const ArchiveLoading();

  @override
  List<Object?> get props => [];
}

final class ArchiveLoaded extends ArchiveState {
  final List<Article> articles;

  const ArchiveLoaded(this.articles);

  @override
  List<Object?> get props => [articles];
}
