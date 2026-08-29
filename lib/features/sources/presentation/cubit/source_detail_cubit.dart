import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/feed/feed_sync_trigger.dart';
import 'package:newsreader/core/observability/telemetry_client.dart';
import 'package:newsreader/features/sources/domain/usecases/get_source_articles.dart';
import 'package:newsreader/features/sync/domain/usecases/sync_user_data.dart';

part 'source_detail_state.dart';

class SourceDetailCubit extends Cubit<SourceDetailState> {
  final GetSourceArticles _getSourceArticles;
  final FeedSyncTrigger _feedSyncTrigger;
  final SyncUserData _syncUserData;
  final TelemetryClient _observabilityClient;

  SourceDetailCubit(
    this._getSourceArticles,
    this._feedSyncTrigger,
    this._syncUserData,
    this._observabilityClient,
  ) : super(const SourceDetailLoading());

  Future<void> loadArticles(String sourceId) async {
    emit(const SourceDetailLoading());
    final articles = await _getSourceArticles.execute(sourceId);
    emit(SourceDetailLoaded(articles));
  }

  /// Sincroniza feeds antes de cargar, para el caso de una fuente recién
  /// agregada que todavía no tiene artículos locales.
  ///
  /// `SourceRepositoryImpl.addSource()` solo guarda en Hive local -- el
  /// servidor todavía no sabe que esta fuente existe. Por eso el primer
  /// `_syncUserData.execute()` va ANTES del fetch: sube la fuente nueva a
  /// Postgres para que `sync-feeds` la vea y la incluya en el batch. Sin
  /// ese paso, el fetch corre para todas las fuentes del usuario excepto
  /// la recién agregada. El segundo `_syncUserData.execute()` baja los
  /// artículos que ese fetch acaba de crear.
  ///
  /// Igual criterio que `InboxCubit._silentFeedRefresh()`: el error del
  /// fetch se ignora en silencio -- la fuente ya fue validada al
  /// agregarla, así que un fallo acá es una falla de red transitoria, no
  /// evidencia de que esté mal.
  Future<void> syncAndLoadArticles(String sourceId) async {
    emit(const SourceDetailLoading());
    await _syncUserData.execute();
    try {
      await _feedSyncTrigger.execute();
    } catch (e, st) {
      // Silencioso a propósito: ver el comentario del método.
      _observabilityClient.captureException(e, st);
    }
    await _syncUserData.execute();
    final articles = await _getSourceArticles.execute(sourceId);
    emit(SourceDetailLoaded(articles));
  }
}
