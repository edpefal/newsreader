part of 'inbox_cubit.dart';

sealed class InboxState extends Equatable {
  const InboxState();
}

final class InboxLoading extends InboxState {
  const InboxLoading();

  @override
  List<Object?> get props => [];
}

final class InboxLoaded extends InboxState {
  final List<Article> articles;

  const InboxLoaded(this.articles);

  @override
  List<Object?> get props => [articles];
}
