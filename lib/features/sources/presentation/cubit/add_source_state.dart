part of 'add_source_cubit.dart';

sealed class AddSourceState extends Equatable {
  const AddSourceState();
}

final class AddSourceInitial extends AddSourceState {
  const AddSourceInitial();

  @override
  List<Object?> get props => [];
}

final class AddSourceValidating extends AddSourceState {
  const AddSourceValidating();

  @override
  List<Object?> get props => [];
}

final class AddSourceSuccess extends AddSourceState {
  final NewsSource source;

  const AddSourceSuccess(this.source);

  @override
  List<Object?> get props => [source];
}

final class AddSourceError extends AddSourceState {
  final String message;

  const AddSourceError(this.message);

  @override
  List<Object?> get props => [message];
}
