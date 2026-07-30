/// Dispara el fetch centralizado de feeds del lado del servidor (Edge
/// Function `sync-feeds`) para las fuentes del usuario actual, y espera a
/// que termine. El servidor es el único que parsea RSS/Atom y crea
/// artículos — el cliente nunca lo hace (ver openspec/changes/
/// centralize-feed-fetching/design.md).
abstract class FeedSyncTrigger {
  Future<FeedSyncResult> execute();
}

class FeedSyncResult {
  final int synced;
  final List<String> failedSourceIds;
  final bool isNetworkError;

  const FeedSyncResult({
    required this.synced,
    required this.failedSourceIds,
    this.isNetworkError = false,
  });
}

class FeedSyncException implements Exception {
  final String message;

  const FeedSyncException(this.message);

  @override
  String toString() => 'FeedSyncException: $message';
}
