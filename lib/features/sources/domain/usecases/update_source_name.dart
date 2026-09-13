import 'dart:async';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/domain/repositories/source_repository.dart';
import 'package:newsreader/core/observability/telemetry_client.dart';
import 'package:newsreader/features/sync/domain/usecases/sync_user_data.dart';

class UpdateSourceName {
  final SourceRepository _repository;
  final SyncUserData _syncUserData;
  final AuthClient _authClient;
  final TelemetryClient _observabilityClient;

  const UpdateSourceName(
    this._repository,
    this._syncUserData,
    this._authClient,
    this._observabilityClient,
  );

  Future<void> execute(String sourceId, String newName) async {
    final sources = await _repository.getSources();
    final source = sources.firstWhere((s) => s.id == sourceId);
    await _repository.updateSource(source.copyWith(name: newName));

    _pushRename();
  }

  /// Best-effort: sube el nuevo nombre inmediatamente para reducir el
  /// tiempo que tarda en propagarse a otro dispositivo, sin bloquear ni
  /// retrasar la actualización local ni la interfaz. Si falla o no hay
  /// sesión, no pasa nada -- el próximo `SyncUserData`
  /// (login/resume/pull-to-refresh) lo sube igual, porque `updatedAt` ya
  /// cambió localmente.
  void _pushRename() {
    if (_authClient.currentUserId == null) return;
    unawaited(_tryPushRename());
  }

  Future<void> _tryPushRename() async {
    try {
      await _syncUserData.execute();
    } catch (e, st) {
      _observabilityClient.captureException(e, st);
    }
  }
}
