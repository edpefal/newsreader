import 'dart:async';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/data/models/article_model.dart';
import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/repositories/article_repository.dart';
import 'package:newsreader/core/sync/article_state_row.dart';
import 'package:newsreader/core/sync/cloud_sync_client.dart';

class ToggleFavorite {
  final ArticleRepository _repository;
  final CloudSyncClient _cloudSyncClient;
  final AuthClient _authClient;

  const ToggleFavorite(
    this._repository,
    this._cloudSyncClient,
    this._authClient,
  );

  Future<void> execute(String articleId) async {
    final article = await _repository.getArticleById(articleId);
    if (article == null) return;

    final nowFavorite = !article.isFavorite;
    final updated = article.copyWith(
      isFavorite: nowFavorite,
      savedAsFavoriteAt: nowFavorite ? DateTime.now() : null,
    );
    await _repository.updateArticle(updated);

    _pushFavoriteState(updated);
  }

  /// Best-effort: sube el estado inmediatamente para reducir la ventana de
  /// staleness entre dispositivos, sin bloquear ni retrasar la actualización
  /// local ni la interfaz. Si falla o no hay sesión, no pasa nada -- el
  /// próximo `SyncUserData` (login/resume/pull-to-refresh) lo sube igual,
  /// porque `updatedAt` ya cambió localmente.
  void _pushFavoriteState(Article article) {
    if (_authClient.currentUserId == null) return;
    unawaited(_tryPushFavoriteState(article));
  }

  Future<void> _tryPushFavoriteState(Article article) async {
    try {
      final row = articleStateRow(ArticleModel.fromEntity(article));
      await _cloudSyncClient.updatePartial('articles', [row]);
    } catch (_) {
      // Best-effort: el próximo SyncUserData lo sube igual.
    }
  }
}
