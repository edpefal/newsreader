part of 'add_source_cubit.dart';

sealed class AddSourceState extends Equatable {
  const AddSourceState();
}

/// La URL ingresada no es un feed y no se pudo detectar automáticamente
/// (`FeedDiscoveryException`). A diferencia de [AddSourceError], ofrece la
/// alternativa de generar una dirección de email.
final class AddSourceFeedDiscoveryFailed extends AddSourceState {
  final String message;
  final String originalUrl;

  const AddSourceFeedDiscoveryFailed(this.message, this.originalUrl);

  @override
  List<Object?> get props => [message, originalUrl];
}

final class AddSourceGeneratingEmailFeed extends AddSourceState {
  const AddSourceGeneratingEmailFeed();

  @override
  List<Object?> get props => [];
}

final class AddSourceEmailFeedGenerated extends AddSourceState {
  final GeneratedEmailFeed feed;

  const AddSourceEmailFeedGenerated(this.feed);

  @override
  List<Object?> get props => [feed];
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
