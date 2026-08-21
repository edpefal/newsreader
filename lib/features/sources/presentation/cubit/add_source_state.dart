part of 'add_source_cubit.dart';

sealed class AddSourceState extends Equatable {
  const AddSourceState();
}

/// La URL ingresada no es un feed y no se pudo detectar automáticamente
/// (`FeedDiscoveryException`). A diferencia de [AddSourceError], ofrece la
/// alternativa de generar una dirección de email.
final class AddSourceFeedDiscoveryFailed extends AddSourceState {
  final AppErrorCode code;
  final String originalUrl;

  const AddSourceFeedDiscoveryFailed(this.code, this.originalUrl);

  @override
  List<Object?> get props => [code, originalUrl];
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

/// La URL ingresada tal cual no resultó ser un feed válido y el sistema
/// pasó a probar varios candidatos heurísticos en paralelo.
final class AddSourceValidatingHeuristics extends AddSourceState {
  const AddSourceValidatingHeuristics();

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
  final AppErrorCode code;

  const AddSourceError(this.code);

  @override
  List<Object?> get props => [code];
}
