import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/feed/feed_sync_trigger.dart';
import 'package:newsreader/core/observability/telemetry_client.dart';
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
  final TelemetryClient _observabilityClient;

  /// Invocación de `_feedSyncTrigger.execute()` en curso, si hay una. Se
  /// cachea para que `syncAndReload()` (pull-to-refresh manual) y la fase
  /// silenciosa de `syncAfterSignIn()` nunca disparen dos invocaciones
  /// simultáneas de `sync-feeds` para el mismo usuario si se solapan --
  /// ambas esperan y reusan la misma llamada en vuelo.
  Future<FeedSyncResult>? _inFlightFeedSync;

  /// Tope de vueltas y de tiempo total para el loop de reintento de
  /// `syncAndReload()` (pull-to-refresh manual, ver
  /// `openspec/changes/fix-pull-to-refresh-partial-sync/design.md` -
  /// Decisión 3). Con el tope de fuentes por invocación del servidor (20) y
  /// la evidencia de producción citada ahí (~45-89 fuentes entre cuentas
  /// reales), 5 vueltas cubren cómodamente los casos observados sin
  /// arriesgar un gesto de refresh que tarde varios minutos; el presupuesto
  /// de tiempo acota el peor caso (cada invocación individual ya tiene su
  /// propio timeout HTTP de 90s) sin necesitar bajar el tope de vueltas para
  /// el caso común, que es rápido.
  static const int _maxSyncRounds = 5;
  static const Duration _maxSyncDuration = Duration(seconds: 60);

  InboxCubit(
    this._getInboxArticles,
    this._getSources,
    this._feedSyncTrigger,
    this._markArticleAsRead,
    this._syncUserData,
    this._observabilityClient,
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
    try {
      await _syncUserData.execute();
    } catch (e, st) {
      // No dejar la pantalla en `InboxLoading` para siempre si falla (sin
      // red, Supabase caído): se sigue con lo que ya haya local.
      _observabilityClient.captureException(e, st);
    }
    await _reload();
    unawaited(_silentFeedRefresh());
  }

  /// Refresca los feeds contra el servidor en segundo plano tras el login,
  /// sin bloquear la UI: el Inbox ya se muestra con lo que había en la nube
  /// (ver `syncAfterSignIn()`), y esto lo pone al día por si nadie hizo
  /// pull-to-refresh en varios días. A diferencia de `syncAndReload()`, es
  /// silencioso -- no propaga errores ni fuentes fallidas a la UI (ni
  /// siquiera una excepción inesperada de `_feedSyncTrigger` o
  /// `_syncUserData`), porque es una mejora automática, no una acción
  /// pedida explícitamente por el usuario.
  Future<void> _silentFeedRefresh() async {
    final current = state;
    if (current is InboxLoaded) {
      emit(
        InboxLoaded(
          current.articles,
          hasSources: current.hasSources,
          readArticleId: current.readArticleId,
          isSyncingInBackground: true,
          openArticleId: current.openArticleId,
        ),
      );
    }
    // Subir el estado local pendiente (incl. borrados de fuentes) ANTES del
    // fetch, igual que `syncAndReload()`: si se dispara el fetch primero,
    // `sync-feeds` todavía ve en Postgres una fuente que el usuario acaba
    // de borrar localmente y le crea artículos nuevos, que el `_reload()`
    // final resucita en el Inbox.
    try {
      await _syncUserData.execute();
    } catch (e, st) {
      _observabilityClient.captureException(e, st);
    }
    try {
      await _triggerFeedSync();
    } catch (e, st) {
      // Silencioso a propósito: ver el comentario del método.
      _observabilityClient.captureException(e, st);
    }
    try {
      await _syncUserData.execute();
    } catch (e, st) {
      _observabilityClient.captureException(e, st);
    }
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
          openArticleId: current.openArticleId,
        ),
      );
    }
    try {
      await _syncUserData.execute();
    } catch (e, st) {
      // No dejar el indicador de progreso colgado si falla (sin red,
      // Supabase caído): se sigue con lo que ya haya local.
      _observabilityClient.captureException(e, st);
    }
    await _reload();
  }

  Future<void> markAsRead(String articleId) async {
    await _markArticleAsRead.execute(articleId);
    await _reload(readArticleId: articleId);
  }

  /// Selecciona [articleId] como el artículo abierto en el panel de detalle
  /// (layout de dos paneles): se resalta en la columna central en vez de
  /// desaparecer, aunque `ReaderScreen` ya lo haya marcado como leído. Si
  /// había otro artículo abierto, este se cierra (se anima su salida de la
  /// lista, igual que hoy) y el nuevo pasa a resaltarse.
  Future<void> selectArticle(String articleId) async {
    final current = state;
    if (current is! InboxLoaded) return;
    final previous = current.openArticleId;
    if (previous == articleId) return;
    if (previous == null) {
      emit(
        InboxLoaded(
          current.articles,
          hasSources: current.hasSources,
          isSyncingInBackground: current.isSyncingInBackground,
          searchQuery: current.searchQuery,
          openArticleId: articleId,
        ),
      );
      return;
    }
    await _reload(readArticleId: previous, openArticleId: articleId);
  }

  /// Cierra el artículo actualmente abierto en el panel de detalle (el
  /// usuario volvió con el botón del lector): se anima su salida de la
  /// columna central, igual que al marcarlo como leído.
  Future<void> closeOpenArticle() async {
    final current = state;
    if (current is! InboxLoaded || current.openArticleId == null) return;
    await _reload(readArticleId: current.openArticleId, clearOpenArticleId: true);
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
          openArticleId: current.openArticleId,
        ),
      );
    }
  }

  Future<FeedSyncResult> syncAndReload() async {
    // Evento de producto solo acá, no en `syncAfterSignIn()` ni
    // `_silentFeedRefresh()`/`syncInBackground()`: esta es la única
    // sincronización que el usuario dispara explícitamente (pull-to-refresh
    // manual); las demás son automáticas.
    _observabilityClient.trackEvent('sync_triggered');
    // Subir el estado local (incluyendo borrados de fuentes) antes de
    // disparar el fetch: si se dispara primero, `sync-feeds` todavía ve en
    // Postgres una fuente que el usuario acaba de borrar localmente y le
    // crea artículos nuevos, que después el pull de abajo resucita en el
    // Inbox. Se vuelve a llamar después del fetch para bajar esos artículos
    // nuevos en la misma pasada de refresh.
    //
    // Ambas llamadas van en try/catch: si fallan (sin red, Supabase caído),
    // no deben propagarse sin capturar -- `_triggerFeedSync()` ya reporta
    // el error de red de forma explícita vía `FeedSyncResult.isNetworkError`
    // (que `_onRefresh()` sí muestra al usuario), así que un fallo acá no
    // debe además romper el `RefreshIndicator` con una excepción sin manejar.
    try {
      await _syncUserData.execute();
    } catch (e, st) {
      _observabilityClient.captureException(e, st);
    }
    final result = await _syncFeedsUntilCovered();
    try {
      await _syncUserData.execute();
    } catch (e, st) {
      _observabilityClient.captureException(e, st);
    }
    await _reload();
    return result;
  }

  /// Reintenta `_triggerFeedSync()` en loop, dentro del mismo gesto de
  /// pull-to-refresh, hasta cubrir todas las fuentes del usuario o alcanzar
  /// un tope explícito -- ver `openspec/changes/
  /// fix-pull-to-refresh-partial-sync/design.md` (Decisiones 2, 3 y 4).
  /// Exclusivo de `syncAndReload()`: `syncAfterSignIn()`/
  /// `_silentFeedRefresh()` (login) y el fetch al agregar una fuente siguen
  /// invocando `_triggerFeedSync()` una única vez, sin este mecanismo.
  ///
  /// La condición de parada (la primera que se cumpla, evaluada al final de
  /// cada vuelta) es: ya se intentó, en conjunto, al menos tantas fuentes
  /// como tiene el usuario; la vuelta actual no intentó ninguna fuente; la
  /// vuelta actual falló por error de red; o se alcanzó el tope de vueltas
  /// o de tiempo total. Nunca se corta una invocación en curso a mitad de
  /// camino -- los topes solo deciden si se arranca una vuelta más.
  Future<FeedSyncResult> _syncFeedsUntilCovered() async {
    // Se dispara `_getSources.execute()` acá (sin `await` todavía) en vez de
    // esperarlo antes de la primera vuelta: si se lo esperara primero, se
    // introduciría un salto de microtask extra antes de la primera llamada a
    // `_triggerFeedSync()` que puede hacer perder la deduplicación con una
    // invocación de `_feedSyncTrigger.execute()` ya en curso (ver
    // `_inFlightFeedSync`) disparada casi al mismo tiempo por
    // `_silentFeedRefresh()` (login). Se resuelve recién cuando hace falta,
    // después de la primera vuelta.
    final sourceCountFuture = _getSources.execute().then((s) => s.length);
    final stopwatch = Stopwatch()..start();

    var synced = 0;
    final failedSourceIds = <String>{};
    var isNetworkError = false;
    var attemptedTotal = 0;
    var sourceCount = 0;
    var sourceCountResolved = false;

    for (var round = 0; round < _maxSyncRounds; round++) {
      final result = await _triggerFeedSync();
      synced += result.synced;
      failedSourceIds.addAll(result.failedSourceIds);
      final attemptedThisRound = result.synced + result.failedSourceIds.length;
      attemptedTotal += attemptedThisRound;

      if (!sourceCountResolved) {
        sourceCount = await sourceCountFuture;
        sourceCountResolved = true;
      }

      if (result.isNetworkError) {
        isNetworkError = true;
        break;
      }
      if (attemptedThisRound == 0) break;
      if (attemptedTotal >= sourceCount) break;
      if (stopwatch.elapsed >= _maxSyncDuration) break;
    }

    return FeedSyncResult(
      synced: synced,
      failedSourceIds: failedSourceIds.toList(),
      isNetworkError: isNetworkError,
    );
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

  /// Recarga los artículos desde el repositorio. `openArticleId` sostiene la
  /// selección resaltada de la columna central (ver `InboxLoaded`): si no se
  /// pasa explícitamente, se conserva la que ya tenía el estado anterior
  /// (por ejemplo, un pull-to-refresh o una sincronización en segundo plano
  /// no deben perder la selección abierta). Pasar `clearOpenArticleId: true`
  /// (usado por `closeOpenArticle`) es la única forma de limpiarla.
  Future<void> _reload({
    String? readArticleId,
    String? openArticleId,
    bool clearOpenArticleId = false,
  }) async {
    final previous = state;
    final searchQuery = previous is InboxLoaded ? previous.searchQuery : '';
    final effectiveOpenArticleId = clearOpenArticleId
        ? null
        : openArticleId ?? (previous is InboxLoaded ? previous.openArticleId : null);
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
        openArticleId: effectiveOpenArticleId,
      ),
    );
  }
}
