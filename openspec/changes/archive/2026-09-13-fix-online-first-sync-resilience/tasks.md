## 1. Clasificación y timeout de errores de sincronización con la nube

- [x] 1.1 Agregar `AppErrorCode.cloudSyncFailed` en `lib/core/errors/app_error_code.dart` con su comentario de uso.
- [x] 1.2 Convertir `CloudSyncException` (en `lib/core/sync/cloud_sync_client.dart` o donde esté definida) para que extienda `AppException`, aceptando un `AppErrorCode`.
- [x] 1.3 En `lib/core/sync/supabase_cloud_sync_client.dart`, clasificar el error capturado en `upsert`, `updatePartial` y `fetchChangedSince`: `TimeoutException` → `AppErrorCode.timeout`, error de conectividad (`SocketException`/equivalente de Supabase) → `AppErrorCode.network`, cualquier otro → `AppErrorCode.cloudSyncFailed`.
- [x] 1.4 Envolver las llamadas Postgrest de `upsert`, cada `update` de `updatePartial`, y cada página de `fetchChangedSince` en `.timeout(Duration(seconds: 30))`.
- [x] 1.5 Tests unitarios para la clasificación de error y el timeout en `test/unit/core/sync/supabase_cloud_sync_client_test.dart` (o el archivo de test existente para este cliente).

## 2. Ningún caller de `SyncUserData.execute()` queda colgado

- [x] 2.1 En `SourceDetailCubit.syncAndLoadArticles()` (`lib/features/sources/presentation/cubit/source_detail_cubit.dart`), envolver el primer `_syncUserData.execute()` en el mismo `try/catch` (reportar a observabilidad, seguir adelante) que ya usa `_feedSyncTrigger.execute()` en ese método.
- [x] 2.2 En `InboxCubit.syncAfterSignIn()` y `InboxCubit.syncInBackground()` (`lib/features/inbox/presentation/cubit/inbox_cubit.dart`), capturar el fallo de `_syncUserData.execute()` y emitir un estado terminal en vez de dejar la excepción sin manejar (`InboxLoaded` con lo que ya haya localmente si `syncInBackground`; para `syncAfterSignIn`, cargar igualmente desde local tras el fallo).
- [x] 2.3 En `InboxCubit._silentFeedRefresh()`, envolver también el `_syncUserData.execute()` final (después del fetch) en el mismo manejo silencioso que ya cubre `_triggerFeedSync()`.
- [x] 2.4 Test en `source_detail_cubit_test.dart`: `SyncUserData.execute()` lanza una excepción → el cubit emite `SourceDetailLoaded` con los artículos locales disponibles, no se queda en `SourceDetailLoading`.
- [x] 2.5 Tests en `inbox_cubit_test.dart` cubriendo el fallo de `_syncUserData.execute()` en cada uno de los tres métodos tocados en 2.2/2.3.
- [x] 2.6 (Descubierto durante la implementación, no listado originalmente pero cubierto por el requirement general de `cloud-sync`): `InboxCubit.syncAndReload()` tenía el mismo problema — su primer `_syncUserData.execute()` podía lanzar sin capturar antes de llegar a `_triggerFeedSync()`, rompiendo el `RefreshIndicator` de pull-to-refresh. Envueltas ambas llamadas en `try/catch`, con test en `inbox_cubit_test.dart`.

## 3. Orden garantizado subida-antes-de-fetch en `_silentFeedRefresh`

- [x] 3.1 Reordenar `InboxCubit._silentFeedRefresh()` para subir el estado local pendiente (`_syncUserData.execute()`) antes de `_triggerFeedSync()`, y volver a sincronizar después del fetch para bajar los cambios que este genere — mismo patrón que `syncAndReload()`.
- [x] 3.2 Test en `inbox_cubit_test.dart` que verifique el orden de llamadas (subida → fetch → bajada) en `_silentFeedRefresh()`, con mocks que registren el orden de invocación.

## 4. Guard de concurrencia en `SyncUserData`

- [x] 4.1 Agregar un `Future<void>? _inFlight` de instancia a `SyncUserData` (`lib/features/sync/domain/usecases/sync_user_data.dart`): si `execute()` se llama mientras ya hay una invocación en curso, reusar (esperar) esa misma `Future` en vez de iniciar una pasada nueva.
- [x] 4.2 Test unitario en `sync_user_data_test.dart`: dos llamadas concurrentes a `execute()` resultan en una sola pasada real contra `CloudSyncClient` (verificar con un mock que cuenta invocaciones).

## 5. Push inmediato de borrado y renombrado de fuente

- [x] 5.1 Inyectar `SyncUserData` en `DeleteSource` (`lib/features/sources/domain/usecases/delete_source.dart`) y disparar un `unawaited` best-effort a `execute()` tras el borrado local, con `try/catch` que solo reporta a observabilidad (mismo patrón que `MarkArticleAsRead`/`ToggleFavorite`). Solo intentar el push si hay sesión activa.
- [x] 5.2 Inyectar `SyncUserData` en `UpdateSourceName` (`lib/features/sources/domain/usecases/update_source_name.dart`) y aplicar el mismo patrón de push inmediato best-effort.
- [x] 5.3 Actualizar el registro de dependencias en `lib/core/di/injection.dart` para las nuevas dependencias de `DeleteSource`/`UpdateSourceName`.
- [x] 5.4 Crear `test/unit/features/sources/domain/usecases/delete_source_test.dart` y `update_source_name_test.dart` (no existían pruebas dedicadas para estos use cases): verifican que se intenta el push inmediato, que su fallo no impide que la operación local se complete, y que no se intenta sin sesión activa.

## 6. Flush de cambios pendientes antes de cerrar sesión

- [x] 6.1 En `SettingsScreen._signOut()` (`lib/features/settings/presentation/screens/settings_screen.dart`), intentar `SyncUserData.execute()` antes de `clearLocalUserData.execute()`.
- [x] 6.2 Si ese intento falla, mostrar un `AlertDialog` de confirmación (`SignOutUnsyncedChangesDialog`, `lib/features/settings/presentation/widgets/`) con las opciones "Cancelar" y "Cerrar sesión de todos modos" antes de continuar con `clearLocalUserData.execute()` + `authClient.signOut()`.
- [x] 6.3 Agregar las claves de texto nuevas (título/cuerpo del diálogo, botones) en `lib/l10n/app_en.arb`, `app_es.arb` (tuteo, sin voseo) y `app_fr.arb`, y correr `flutter gen-l10n`.
- [x] 6.4 Inyectar `SyncUserData` en `SettingsScreen` (constructor param) y actualizar su construcción en `lib/presentation/app/router.dart`. (No requirió cambios en `injection.dart`: `SyncUserData` ya estaba registrado.)
- [x] 6.5 Widget test para `SettingsScreen` cubriendo: flush exitoso (sin diálogo), flush fallido con "Cancelar" (no se cierra sesión), flush fallido con "Cerrar sesión de todos modos" (se limpia y cierra sesión igual).

## 7. Documentación

- [x] 7.1 Corregir `CLAUDE.md`: quitar la referencia a `SyncSources` como use case de `features/inbox/domain/usecases/` y describir que el fetch de feeds hoy se centraliza en la Edge Function `sync-feeds`, disparada por `FeedSyncTrigger`/`SupabaseFeedSyncTrigger`. También se agregó el feature `sync/` (ausente del árbol) para que `SyncUserData`/`ClearLocalUserData` queden documentados.

## 8. Verificación final

- [x] 8.1 Correr `flutter analyze` sin warnings.
- [x] 8.2 Correr `flutter test` completo (610 tests, todos verdes).
- [x] 8.3 Correr `openspec validate --strict` sobre el change.
