## 1. Implementación en `InboxCubit`

- [x] 1.1 Agregar las constantes `_maxSyncRounds` (5) y `_maxSyncDuration` (`Duration(seconds: 60)`) a `InboxCubit` (`lib/features/inbox/presentation/cubit/inbox_cubit.dart`), documentando por qué esos valores (ver `design.md` - Decisión 3).
- [x] 1.2 Modificar `syncAndReload()` para, después del primer `_syncUserData.execute()` y antes del `_reload()` final, loopear la invocación de `_triggerFeedSync()` según la condición de parada de `design.md` - Decisión 2: obtener `sourceCount` vía `_getSources.execute()`, acumular `attemptedTotal` (`synced + failedSourceIds.length` de cada vuelta), y detenerse en la primera vuelta donde `attemptedTotal >= sourceCount`, la vuelta actual no intentó ninguna fuente, la vuelta actual devolvió `isNetworkError: true`, o se alcanzó `_maxSyncRounds`/`_maxSyncDuration`.
- [x] 1.3 Agregar los resultados de todas las vueltas en un único `FeedSyncResult` final (ver `design.md` - Decisión 4): `synced` sumado, `failedSourceIds` deduplicado vía `Set`, `isNetworkError` de la vuelta que cortó el loop.
- [x] 1.4 Verificar que el `_syncUserData.execute()` posterior al fetch y el `_reload()` final de `syncAndReload()` sigan ejecutándose exactamente una vez al terminar el loop (no una vez por vuelta).
- [x] 1.5 Confirmar que `syncAfterSignIn()`/`_silentFeedRefresh()` (login) y el fetch automático al agregar una fuente siguen invocando `_triggerFeedSync()` una única vez, sin el loop — el mecanismo de reintento es exclusivo de `syncAndReload()` (pull-to-refresh manual), según el alcance de `proposal.md`.

## 2. Tests

- [x] 2.1 Test (`bloc_test`) en `test/unit/features/inbox/presentation/cubit/inbox_cubit_test.dart`: con más fuentes que las que una sola invocación cubre, `syncAndReload()` invoca `_feedSyncTrigger.execute()` más de una vez y el `FeedSyncResult` final agrega `synced` de todas las vueltas.
- [x] 2.2 Test: con pocas fuentes (una sola invocación ya cubre `sourceCount`), `syncAndReload()` invoca `_feedSyncTrigger.execute()` exactamente una vez (sin vueltas adicionales innecesarias).
- [x] 2.3 Test: si se alcanza `_maxSyncRounds` sin cubrir todas las fuentes, el loop se detiene igual, y `syncAndReload()` continúa con `_reload()` normalmente (no queda colgado ni lanza una excepción).
- [x] 2.4 Test: si una vuelta intermedia devuelve `isNetworkError: true`, el loop se detiene inmediatamente (no se invoca `_feedSyncTrigger.execute()` de nuevo) y el `FeedSyncResult` final tiene `isNetworkError: true`.
- [x] 2.5 Test: si la misma fuente aparece en `failedSourceIds` en más de una vuelta, el `FeedSyncResult` final la reporta una sola vez (sin duplicados).
- [x] 2.6 Revisar los tests existentes de `syncAndReload()` (fallos parciales, red, push previo al fetch) que ya están en el archivo y ajustarlos si la nueva lógica de loop cambia cuántas veces se invocan los mocks involucrados (`mockGetSources`, `mockFeedSyncTrigger`, `mockSyncUserData`).

## 3. Verificación

- [x] 3.1 Correr `flutter analyze` sin warnings.
- [x] 3.2 Correr `flutter test test/unit/features/inbox/` y confirmar que todos los tests (existentes + nuevos) pasan.
- [x] 3.3 Correr `openspec validate --change fix-pull-to-refresh-partial-sync --strict` y confirmar que la delta spec de `feed-polling` es válida.
