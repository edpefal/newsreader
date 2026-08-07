## 1. Guard de invocación única

- [x] 1.1 En `lib/features/inbox/presentation/cubit/inbox_cubit.dart`, agregar el campo privado `Future<FeedSyncResult>? _inFlightFeedSync` y el método `_triggerFeedSync()` que reutiliza la invocación en curso si existe, o dispara `_feedSyncTrigger.execute()` y la cachea hasta que complete (ver design.md, Decisión 2).
- [x] 1.2 Reemplazar la llamada directa a `_feedSyncTrigger.execute()` dentro de `syncAndReload()` por `_triggerFeedSync()`, sin cambiar el resto de su comportamiento (snackbars, orden de sync).

## 2. Fase silenciosa tras el login

- [x] 2.1 Agregar el método privado `_silentFeedRefresh()` en `InboxCubit`: emite `InboxLoaded(..., isSyncingInBackground: true)` si el estado actual es `InboxLoaded`, llama a `_triggerFeedSync()` descartando el resultado, y luego `_syncUserData.execute()` + `_reload()`.
- [x] 2.2 Modificar `syncAfterSignIn()` para que, tras su `_reload()` actual, dispare `_silentFeedRefresh()` sin esperarlo (`unawaited`), de forma que el método siga retornando apenas termina la sincronización inicial.
- [x] 2.3 Confirmar que `_BackgroundSyncIndicator` (`lib/features/inbox/presentation/screens/inbox_screen.dart`) no requiere cambios: debe reaccionar igual al `isSyncingInBackground` emitido desde la nueva fase silenciosa.

## 3. Tests

- [x] 3.1 En `test/unit/features/inbox/presentation/cubit/inbox_cubit_test.dart`, agregar un test que verifique que `syncAfterSignIn()` dispara `_feedSyncTrigger.execute()` (vía mock) además de `_syncUserData.execute()`, y que el Inbox se recarga con el resultado final.
- [x] 3.2 Agregar un test que verifique que, si `syncAndReload()` se invoca mientras la fase silenciosa de `syncAfterSignIn()` sigue en curso, `_feedSyncTrigger.execute()` (el mock subyacente) se invoca una sola vez, no dos.
- [x] 3.3 Agregar un test que verifique que un error o resultado con `failedSourceIds` durante la fase silenciosa no emite ningún estado de error ni dispara side-effects de UI (a diferencia de `syncAndReload()`).
- [x] 3.4 Correr `flutter test test/unit/` y `flutter analyze` para confirmar que no hay regresiones ni warnings.

## 4. Verificación manual

- [x] 4.1 Con una cuenta cuyas fuentes no se refrescaron en días, iniciar sesión y confirmar que el Inbox muestra primero el contenido existente, luego aparece la barra de progreso no invasiva, y al terminar se actualiza con artículos nuevos sin ningún snackbar.
- [x] 4.2 Simular una falla de red durante la fase silenciosa (por ejemplo, cortando conectividad justo tras el login) y confirmar que no aparece ningún mensaje de error visible.
