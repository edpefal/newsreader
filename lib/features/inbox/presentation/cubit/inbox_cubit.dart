import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/feed/feed_sync_trigger.dart';
import 'package:newsreader/core/utils/article_text_matcher.dart';
import 'package:newsreader/features/inbox/domain/usecases/get_inbox_articles.dart';
import 'package:newsreader/features/inbox/domain/usecases/mark_article_as_read.dart';
import 'package:newsreader/features/sources/domain/usecases/get_sources.dart';
import 'package:newsreader/features/sync/domain/usecases/sync_user_data.dart';

part 'inbox_state.dart';

class InboxCubit extends Cubit<InboxState> {
  final GetInboxArticles _getInboxArticles;
  final GetSources _getSources;
  final FeedSyncTrigger _feedSyncTrigger;
  final MarkArticleAsRead _markArticleAsRead;
  final SyncUserData _syncUserData;

  /// Invocación de `_feedSyncTrigger.execute()` en curso, si hay una. Se
  /// cachea para que `syncAndReload()` (pull-to-refresh manual) y la fase
  /// silenciosa de `syncAfterSignIn()` nunca disparen dos invocaciones
  /// simultáneas de `sync-feeds` para el mismo usuario si se solapan --
  /// ambas esperan y reusan la misma llamada en vuelo.
  Future<FeedSyncResult>? _inFlightFeedSync;

  InboxCubit(
    this._getInboxArticles,
    this._getSources,
    this._feedSyncTrigger,
    this._markArticleAsRead,
    this._syncUserData,
  ) : super(const InboxLoading());

  Future<void> loadArticles() async {
    emit(const InboxLoading());
    await _reload();
  }

  /// Sincroniza y recarga tras detectar una sesión nueva (primer login, o
  /// login después de cerrar sesión). Emite `InboxLoading` antes de
  /// arrancar el sync -- sin esto, la pantalla se queda mostrando el
  /// estado vacío de antes del login (sin spinner) durante los segundos
  /// que tarda `SyncUserData`, dando la impresión de que no hay fuentes.
  Future<void> syncAfterSignIn() async {
    emit(const InboxLoading(isSyncing: true));
    await _syncUserData.execute();
    await _reload();
    unawaited(_silentFeedRefresh());
  }

  /// Refresca los feeds contra el servidor en segundo plano tras el login,
  /// sin bloquear la UI: el Inbox ya se muestra con lo que había en la nube
  /// (ver `syncAfterSignIn()`), y esto lo pone al día por si nadie hizo
  /// pull-to-refresh en varios días. A diferencia de `syncAndReload()`, es
  /// silencioso -- no propaga errores ni fuentes fallidas a la UI (ni
  /// siquiera una excepción inesperada de `_feedSyncTrigger`), porque es una
  /// mejora automática, no una acción pedida explícitamente por el usuario.
  Future<void> _silentFeedRefresh() async {
    final current = state;
    if (current is InboxLoaded) {
      emit(
        InboxLoaded(
          current.articles,
          hasSources: current.hasSources,
          readArticleId: current.readArticleId,
          isSyncingInBackground: true,
        ),
      );
    }
    try {
      await _triggerFeedSync();
    } catch (_) {
      // Silencioso a propósito: ver el comentario del método.
    }
    await _syncUserData.execute();
    await _reload();
  }

  Future<void> loadArticlesAfterReading(String articleId) =>
      _reload(readArticleId: articleId);

  /// Sincroniza tras volver del background sin ocultar el contenido ya
  /// cargado. A diferencia de `loadArticles()`/`syncAfterSignIn()`, no
  /// emite `InboxLoading` (pantalla completa) -- eso reemplazaría los
  /// artículos ya visibles por un spinner mientras sincroniza. Si el
  /// estado actual es `InboxLoaded`, se re-emite con
  /// `isSyncingInBackground: true` para que la UI muestre un indicador no
  /// invasivo sin perder el contenido en pantalla.
  Future<void> syncInBackground() async {
    final current = state;
    if (current is InboxLoaded) {
      emit(
        InboxLoaded(
          current.articles,
          hasSources: current.hasSources,
          readArticleId: current.readArticleId,
          isSyncingInBackground: true,
        ),
      );
    }
    await _syncUserData.execute();
    await _reload();
  }

  Future<void> markAsRead(String articleId) async {
    await _markArticleAsRead.execute(articleId);
    await _reload(readArticleId: articleId);
  }

  /// Filtra, en memoria, la lista de artículos ya cargada por [query] (ver
  /// `InboxLoaded.visibleArticles`), sin recargar desde el repositorio. Si el
  /// estado actual no es `InboxLoaded`, no tiene efecto.
  void search(String query) {
    final current = state;
    if (current is InboxLoaded) {
      emit(
        InboxLoaded(
          current.articles,
          hasSources: current.hasSources,
          isSyncingInBackground: current.isSyncingInBackground,
          searchQuery: query,
        ),
      );
    }
  }

  Future<FeedSyncResult> syncAndReload() async {
    // Subir el estado local (incluyendo borrados de fuentes) antes de
    // disparar el fetch: si se dispara primero, `sync-feeds` todavía ve en
    // Postgres una fuente que el usuario acaba de borrar localmente y le
    // crea artículos nuevos, que después el pull de abajo resucita en el
    // Inbox. Se vuelve a llamar después del fetch para bajar esos artículos
    // nuevos en la misma pasada de refresh.
    await _syncUserData.execute();
    final result = await _triggerFeedSync();
    await _syncUserData.execute();
    await _reload();
    return result;
  }

  /// Dispara `_feedSyncTrigger.execute()`, o reusa la invocación ya en
  /// curso si hay una (ver `_inFlightFeedSync`).
  Future<FeedSyncResult> _triggerFeedSync() {
    final existing = _inFlightFeedSync;
    if (existing != null) return existing;
    final future = _feedSyncTrigger.execute();
    _inFlightFeedSync = future;
    // `.ignore()` evita que Dart reporte como "unhandled" el future nuevo
    // que crea `whenComplete` si `future` termina en error -- el error
    // real sigue propagándose normalmente a quien haga `await` sobre el
    // `future` que se retorna acá.
    future.whenComplete(() => _inFlightFeedSync = null).ignore();
    return future;
  }

  Future<void> _reload({String? readArticleId}) async {
    final previous = state;
    final searchQuery = previous is InboxLoaded ? previous.searchQuery : '';
    final results = await Future.wait([
      _getInboxArticles.execute(),
      _getSources.execute(),
    ]);
    final articles = results[0] as List<Article>;
    final hasSources = (results[1] as List).isNotEmpty;
    emit(
      InboxLoaded(
        articles,
        hasSources: hasSources,
        readArticleId: readArticleId,
        searchQuery: searchQuery,
      ),
    );
  }
}
