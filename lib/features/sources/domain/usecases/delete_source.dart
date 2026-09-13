import 'dart:async';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/domain/repositories/article_repository.dart';
import 'package:newsreader/core/domain/repositories/source_repository.dart';
import 'package:newsreader/core/observability/telemetry_client.dart';
import 'package:newsreader/features/sync/domain/usecases/sync_user_data.dart';

class DeleteSource {
  final SourceRepository _sourceRepository;
  final ArticleRepository _articleRepository;
  final SyncUserData _syncUserData;
  final AuthClient _authClient;
  final TelemetryClient _observabilityClient;

  const DeleteSource(
    this._sourceRepository,
    this._articleRepository,
    this._syncUserData,
    this._authClient,
    this._observabilityClient,
  );

  Future<void> execute(String sourceId) async {
    await _articleRepository.deleteArticlesBySource(
      sourceId,
      keepFavorites: true,
    );
    await _sourceRepository.deleteSource(sourceId);

    _pushDeletion();
  }

  /// Best-effort: sube el borrado inmediatamente para reducir el tiempo que
  /// tarda en propagarse a otro dispositivo, sin bloquear ni retrasar el
  /// borrado local ni la interfaz. Si falla o no hay sesión, no pasa nada --
  /// el próximo `SyncUserData` (login/resume/pull-to-refresh) lo sube igual,
  /// porque `deletedAt`/`updatedAt` ya cambiaron localmente.
  void _pushDeletion() {
    if (_authClient.currentUserId == null) return;
    unawaited(_tryPushDeletion());
  }

  Future<void> _tryPushDeletion() async {
    try {
      await _syncUserData.execute();
    } catch (e, st) {
      _observabilityClient.captureException(e, st);
    }
  }
}
