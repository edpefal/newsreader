import 'dart:async';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/data/models/article_model.dart';
import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/repositories/article_repository.dart';
import 'package:newsreader/core/observability/observability_client.dart';
import 'package:newsreader/core/sync/article_state_row.dart';
import 'package:newsreader/core/sync/cloud_sync_client.dart';

class MarkArticleAsRead {
  final ArticleRepository _repository;
  final CloudSyncClient _cloudSyncClient;
  final AuthClient _authClient;
  final ObservabilityClient _observabilityClient;

  const MarkArticleAsRead(
    this._repository,
    this._cloudSyncClient,
    this._authClient,
    this._observabilityClient,
  );

  Future<void> execute(String articleId) async {
    final article = await _repository.getArticleById(articleId);
    if (article == null || article.isRead) return;

    final now = DateTime.now();
    final updated = article.copyWith(
      isRead: true,
      readAt: now,
      updatedAt: now,
    );
    await _repository.updateArticle(updated);

    _pushReadState(updated);
  }

  /// Best-effort: sube el estado inmediatamente para reducir la ventana de
  /// staleness entre dispositivos, sin bloquear ni retrasar la actualización
  /// local ni la interfaz. Si falla o no hay sesión, no pasa nada -- el
  /// próximo `SyncUserData` (login/resume/pull-to-refresh) lo sube igual,
  /// porque `updatedAt` ya cambió localmente.
  void _pushReadState(Article article) {
    if (_authClient.currentUserId == null) return;
    unawaited(_tryPushReadState(article));
  }

  Future<void> _tryPushReadState(Article article) async {
    try {
      final row = articleStateRow(ArticleModel.fromEntity(article));
      await _cloudSyncClient.updatePartial('articles', [row]);
    } catch (e, st) {
      // Best-effort: el próximo SyncUserData lo sube igual, pero se reporta
      // para poder detectar fallas sistemáticas de este push.
      _observabilityClient.captureException(e, st);
    }
  }
}
