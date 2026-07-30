## 1. Estado del Inbox

- [x] 1.1 Agregar el campo `isSyncingInBackground` (bool, default `false`) a `InboxLoaded` en `inbox_state.dart`, incluido en `props`.

## 2. Cubit

- [x] 2.1 Agregar `InboxCubit.syncInBackground()`: si el estado actual es `InboxLoaded`, re-emitirlo con `isSyncingInBackground: true`; correr `SyncUserData.execute()`; luego `_reload()` (que emite `InboxLoaded` con `isSyncingInBackground: false` por default). Si el estado actual no es `InboxLoaded` (ej. todavía `InboxLoading`), no emitir el flag intermedio y solo correr sync + `_reload()`.
- [x] 2.2 Escribir tests unitarios para `syncInBackground()`: emite `isSyncingInBackground: true` antes de sincronizar, `false` (implícito) después; no rompe si el estado inicial no es `InboxLoaded`.

## 3. UI

- [x] 3.1 En `inbox_screen.dart`, renderizar un `LinearProgressIndicator` debajo del `AppBar` (por ejemplo, en `bottom` del `AppBar` o como primer hijo del body) cuando `state is InboxLoaded && state.isSyncingInBackground`.
- [x] 3.2 Escribir/actualizar widget test de `InboxScreen` confirmando que el indicador aparece con `isSyncingInBackground: true` y no aparece con `false`, y que los artículos siguen visibles en ambos casos.

## 4. Integración con el resume de background

- [x] 4.1 En `app.dart`, cambiar `didChangeAppLifecycleState` para llamar a `widget.inboxCubit.syncInBackground()` en vez de `getIt<SyncUserData>().execute().then((_) => widget.inboxCubit.loadArticles())`.
- [x] 4.2 Correr `flutter analyze` y `flutter test`, resolver cualquier issue. Sin issues, 223/223 pasan.

## 5. Verificación manual

- [x] 5.1 Probar en un dispositivo con el Inbox ya con artículos: mandar a background, volver, confirmar que aparece el `LinearProgressIndicator` debajo del título sin que el contenido desaparezca, y que se oculta al terminar. Confirmado en emulador Android.
