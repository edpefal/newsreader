import 'dart:async';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/domain/repositories/summary_repository.dart';
import 'package:newsreader/core/observability/telemetry_client.dart';
import 'package:newsreader/core/sync/cloud_sync_client.dart';
import 'package:newsreader/core/utils/is_local_today.dart';

/// Quita del Inbox el resumen de hoy (al abrirlo o descartarlo con swipe).
/// Solo escribe para el resumen de hoy; los de días anteriores se ignoran.
class DismissDailySummary {
  final SummaryRepository _repository;
  final CloudSyncClient _cloudSyncClient;
  final AuthClient _authClient;
  final TelemetryClient _observabilityClient;

  const DismissDailySummary(
    this._repository,
    this._cloudSyncClient,
    this._authClient,
    this._observabilityClient,
  );

  Future<void> execute(String summaryId) async {
    try {
      final summary = await _repository.getById(summaryId);
      if (summary == null || !isLocalToday(summary.date)) return;

      final dismissed = await _repository.dismiss(summaryId);
      if (dismissed == null) return; // ya descartado: nada que subir

      _pushDismissal(dismissed);
    } catch (e, st) {
      _observabilityClient.captureException(
        e,
        st,
        context: const {'operation': 'dismiss'},
      );
    }
  }

  /// Best-effort, igual que `MarkArticleAsRead`: no bloquea ni retrasa la
  /// actualización local; si falla o no hay sesión, el próximo
  /// `SyncUserData` lo sube porque `updatedAt` ya cambió.
  void _pushDismissal(DailySummary summary) {
    if (_authClient.currentUserId == null) return;
    unawaited(_tryPush(summary));
  }

  Future<void> _tryPush(DailySummary summary) async {
    try {
      await _cloudSyncClient.updatePartial('daily_summaries', [
        {
          'id': summary.id,
          'dismissed_at': summary.dismissedAt!.toUtc().toIso8601String(),
          'updated_at': (summary.updatedAt ?? DateTime.now())
              .toUtc()
              .toIso8601String(),
        },
      ]);
    } catch (e, st) {
      _observabilityClient.captureException(
        e,
        st,
        context: const {'operation': 'dismiss_push'},
      );
    }
  }
}
