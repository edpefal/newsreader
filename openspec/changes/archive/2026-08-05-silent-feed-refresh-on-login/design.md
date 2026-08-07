## Context

`InboxCubit` (`lib/features/inbox/presentation/cubit/inbox_cubit.dart`) ya tiene dos caminos de sincronización relevantes:

- `syncAfterSignIn()`: hoy solo llama a `SyncUserData.execute()` (baja lo que ya esté en Postgres) y recarga. No dispara `FeedSyncTrigger`.
- `syncAndReload()` (pull-to-refresh manual): sube estado local, llama a `FeedSyncTrigger.execute()` (Edge Function `sync-feeds`, hasta 20 fuentes por invocación, `CONCURRENCY=3`, 10s de timeout por fuente, hasta ~70s en el peor caso), vuelve a bajar con `SyncUserData`, y recarga. Muestra snackbars si hay error de red o fuentes fallidas.

`InboxState.InboxLoaded` ya tiene el flag `isSyncingInBackground`, consumido por `_BackgroundSyncIndicator` en `inbox_screen.dart` (`LinearProgressIndicator` no invasivo), hoy usado solo por `syncInBackground()` (resume). Ver proposal.md para la motivación completa.

## Goals / Non-Goals

**Goals:**
- Que `syncAfterSignIn()` dispare el mismo fetch de feeds que ya hace `syncAndReload()`, sin agregar latencia percibida al login.
- Evitar dos invocaciones simultáneas de `sync-feeds` para el mismo usuario si el fetch de login y un pull-to-refresh manual coinciden.

**Non-Goals:**
- No se modifica `syncInBackground()` (resume) — fuera de alcance de este change, ver proposal.md.
- No se modifica `sync-feeds` (Edge Function) ni ningún componente de servidor.
- No se agrega persistencia de "última vez que se hizo fetch de feeds" ni ningún criterio de cooldown/frescura — se descartó explícitamente en la exploración previa a favor de disparar siempre en login, dado que el fetch ya no bloquea la UI.

## Decisions

### Decisión 1: Fase silenciosa como una continuación no esperada dentro de `syncAfterSignIn()`

`syncAfterSignIn()` sigue bloqueando (con `InboxLoading`) solo hasta que `SyncUserData.execute()` + `_reload()` terminan, igual que hoy. Después de eso, en vez de retornar, arranca — sin `await` en el flujo que bloquea al llamador — una segunda fase:

```dart
Future<void> syncAfterSignIn() async {
  emit(const InboxLoading(message: 'Sincronizando fuentes...'));
  await _syncUserData.execute();
  await _reload();
  unawaited(_silentFeedRefresh());
}

Future<void> _silentFeedRefresh() async {
  final current = state;
  if (current is InboxLoaded) {
    emit(InboxLoaded(current.articles, hasSources: current.hasSources,
        isSyncingInBackground: true));
  }
  await _triggerFeedSync(); // ver Decisión 2, resultado ignorado a propósito
  await _syncUserData.execute();
  await _reload();
}
```

Se eligió no esperar `_silentFeedRefresh()` desde `syncAfterSignIn()` (en vez de, por ejemplo, exponer un método público separado que la UI dispare) para no cambiar el punto de invocación existente en `app.dart` (`widget.inboxCubit.syncAfterSignIn()`, línea 58) ni requerir que la UI orqueste dos llamadas. El estado `isSyncingInBackground` es lo único que la UI necesita observar, y ya lo hace.

**Alternativa considerada**: exponer `syncAfterSignIn()` como un método que retorna antes de la fase silenciosa y que `app.dart` dispare esa segunda fase explícitamente. Se descartó por agregar una responsabilidad de orquestación a la capa de UI que hoy no tiene, sin ningún beneficio (nada más necesita ese punto de corte).

### Decisión 2: Guard de invocación única compartido entre `syncAfterSignIn()` y `syncAndReload()`

Se agrega un campo privado en `InboxCubit`:

```dart
Future<FeedSyncResult>? _inFlightFeedSync;

Future<FeedSyncResult> _triggerFeedSync() {
  final existing = _inFlightFeedSync;
  if (existing != null) return existing;
  final future = _feedSyncTrigger.execute();
  _inFlightFeedSync = future;
  future.whenComplete(() => _inFlightFeedSync = null);
  return future;
}
```

Tanto `_silentFeedRefresh()` como `syncAndReload()` pasan a llamar `_triggerFeedSync()` en vez de `_feedSyncTrigger.execute()` directamente. Si ambos flujos se solapan, el segundo reutiliza el `Future` ya en curso en vez de disparar una segunda invocación a la Edge Function.

**Por qué en memoria y no persistido**: el guard solo necesita vivir mientras el `Future` está en curso (segundos, no across sesiones), y `InboxCubit` ya es un singleton de larga vida (ver comentario en `app.dart:48-52`), así que un campo en memoria es suficiente y no requiere Hive ni ningún almacenamiento adicional.

**Alternativa considerada**: un `Completer` o un `bool _isSyncing` con cola de esperas. Se descartó por ser más código para el mismo resultado — cachear el `Future` mismo ya es awaitable por múltiples llamadores sin necesitar coordinación adicional.

### Decisión 3: `syncAndReload()` conserva su comportamiento de feedback (snackbars); la fase silenciosa no

`syncAndReload()` sigue retornando `FeedSyncResult` tal como hoy, y `inbox_screen.dart` sigue mostrando sus snackbars de error — eso no cambia. `_silentFeedRefresh()` llama a `_triggerFeedSync()` pero descarta el resultado sin propagar ningún error a la UI, incluso si en ese momento resulta ser la misma invocación compartida que un pull-to-refresh concurrente (ese pull-to-refresh sí verá y mostrará el resultado real vía su propio camino de retorno).

## Risks / Trade-offs

- **[Riesgo] El fetch silencioso puede tardar hasta ~70s en el peor caso (muchas fuentes lentas), y durante ese tiempo el guard bloquea que un pull-to-refresh manual dispare una invocación nueva** → Mitigación: no es una regresión — hoy, sin este change, un pull-to-refresh durante ese lapso ya iniciaría su propia invocación de 70s; con el guard, en el peor caso el usuario espera el resto de la invocación ya en curso en vez de una invocación nueva completa, lo cual es igual o mejor. Trade-off aceptado explícitamente en la exploración previa.
- **[Riesgo] Si el usuario cierra la app antes de que `_silentFeedRefresh()` termine, la actualización de estado (`emit`) podría ejecutarse sobre un Cubit cerrado** → Mitigación: mismo riesgo que ya existe hoy en `syncInBackground()`, que tiene el mismo patrón de `await` tras un `emit` sin garantía de que el Cubit siga abierto; no se introduce un caso nuevo, se sigue el patrón ya aceptado en el código existente.
- **[Trade-off] No hay cooldown/frescura: cada login dispara el fetch, incluso si el último fue hace pocos minutos** → Aceptado: como el fetch ya no bloquea la UI (Decisión 1) y el guard evita duplicar invocaciones concurrentes (Decisión 2), el costo marginal de un fetch "innecesario" ocasional es bajo comparado con la complejidad de trackear frescura por fuente. Si se observa costo real (facturación de Edge Function, rate-limiting de feeds de origen), es una mejora futura acotada, no un rediseño.
