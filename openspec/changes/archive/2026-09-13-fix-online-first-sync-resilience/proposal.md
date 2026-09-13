## Why

Una auditoría del código de sincronización (`SyncUserData`, `SupabaseCloudSyncClient`, `InboxCubit`, `SourceDetailCubit`, `SourcesCubit`) encontró seis fallas concretas en la estrategia online-first actual, todas verificables en el código de hoy: una pantalla que se queda cargando para siempre si Supabase falla, una jerarquía de errores de sincronización que nunca llega a la interfaz, dos rutas de sync sin protección de invocaciones concurrentes, una ventana de carrera donde un artículo borrado puede "resucitar", eliminar/renombrar una fuente que puede tardar indefinidamente en propagarse a otro dispositivo, y una pérdida de datos silenciosa posible al cerrar sesión con cambios sin subir. Estas fallas degradan la experiencia offline/con mala conexión, que es justamente el caso que una estrategia "online-first" bien hecha debería cubrir con gracia.

## What Changes

- Capturar los fallos de `SyncUserData.execute()` en **todos** sus llamadores (`SourceDetailCubit.syncAndLoadArticles`, `InboxCubit.syncAfterSignIn`, `InboxCubit.syncInBackground`, `InboxCubit._silentFeedRefresh`) y transicionar siempre a un estado terminal (nunca dejar el cubit indefinidamente en `Loading`).
- Envolver también el primer `SyncUserData.execute()` de `SourceDetailCubit.syncAndLoadArticles()` (push de la fuente recién agregada) en el mismo manejo silencioso que ya existe para el fetch de feeds de ese método, para que un fallo ahí no deje la pantalla en `Loading` para siempre: en vez de un estado nuevo, se sigue el mismo camino ya especificado — mostrar los artículos locales disponibles (potencialmente ninguno) sin mensaje de error.
- Clasificar los errores de `SupabaseCloudSyncClient` con `AppErrorCode` (en particular `network`/`timeout` cuando corresponde) en lugar de una `CloudSyncException(String)` genérica, y agregar un timeout explícito a sus llamadas Postgrest (`upsert`, `updatePartial`, `fetchChangedSince`), igual que ya existe para las llamadas HTTP directas.
- Agregar protección de invocación concurrente a `SyncUserData.execute()` (mismo patrón `_inFlightFeedSync` que ya usa el trigger de feeds), para que llamadas solapadas (arranque + resume de app) no dupliquen trabajo ni regresionen el cursor de sincronización.
- Unificar el orden de operaciones "subir estado local pendiente → disparar fetch de feeds" en **todos** los callers que disparan un fetch de feeds tras una posible mutación local pendiente (`InboxCubit._silentFeedRefresh`, `SourceDetailCubit.syncAndLoadArticles`), cerrando la ventana en la que un artículo recién borrado puede "resucitar" porque el servidor no se enteró todavía del borrado antes de re-sincronizar esa fuente.
- Agregar push inmediato best-effort (mismo patrón usado hoy para `isRead`/`isFavorite`) al borrar y al renombrar una fuente, en vez de depender de que algo más dispare una sincronización completa más adelante.
- Antes de `ClearLocalUserData.execute()` en el flujo de cierre de sesión, intentar un `SyncUserData.execute()` final para subir cualquier cambio local pendiente; si falla, informar al usuario (vía diálogo de confirmación) que puede haber cambios recientes sin sincronizar antes de continuar con el cierre de sesión.
- Corregir la referencia a `SyncSources` en `CLAUDE.md` (use case eliminado en `centralize-feed-fetching`; el fetch de feeds hoy vive en la Edge Function `sync-feeds`), para que el documento refleje la arquitectura real.

Fuera de alcance (documentado explícitamente, no se implementa en este change): detección proactiva de conectividad (`connectivity_plus`/banner "sin conexión"), una cola de reintentos persistente con backoff, y sincronización periódica en segundo plano (cron del lado del servidor o background fetch del SO). Son mejoras de UX/infra válidas pero de mayor alcance, evaluadas y descartadas para este change por decisión explícita del usuario.

## Capabilities

### New Capabilities

(ninguna)

### Modified Capabilities

- `cloud-sync`: clasificación y timeout de errores de sincronización, guard de concurrencia en `SyncUserData`, orden garantizado subida-antes-de-fetch en todos los triggers relevantes, push inmediato de borrado/rename de fuente, y flush de pendientes (o aviso al usuario) antes de limpiar datos locales al cerrar sesión.
- `source-management`: el fallo del push de una fuente recién agregada (no solo el fallo del fetch de feeds) también debe manejarse sin dejar la pantalla de detalle cargando indefinidamente.

## Impact

- **Código afectado**: `lib/features/sync/domain/usecases/sync_user_data.dart`, `lib/core/sync/supabase_cloud_sync_client.dart`, `lib/core/errors/app_exception.dart` y `app_error_code.dart`, `lib/features/sources/presentation/cubit/source_detail_cubit.dart`, `lib/features/sources/presentation/cubit/sources_cubit.dart`, `lib/features/sources/domain/usecases/delete_source.dart` y `update_source_name.dart`, `lib/features/inbox/presentation/cubit/inbox_cubit.dart`, `lib/features/settings/presentation/screens/settings_screen.dart` (flujo de `_signOut`).
- **Tests**: nuevos casos en `source_detail_cubit_test.dart` (fallo de `SyncUserData`), `sync_user_data_test.dart` (concurrencia, timeout, clasificación de error), `sources_cubit_test.dart` (push inmediato de borrado/rename), `inbox_cubit_test.dart` (orden subida-antes-de-fetch en `_silentFeedRefresh`), test del flujo de logout (flush antes de limpiar).
- **i18n**: cualquier mensaje nuevo visible al usuario (ej. aviso de "cambios sin sincronizar" al cerrar sesión) requiere sus 3 traducciones (`app_en.arb`, `app_es.arb`, `app_fr.arb`) en el mismo change.
- **Sin cambios de esquema de Supabase** ni de Edge Functions — todo el trabajo es del lado del cliente Flutter y de `CLAUDE.md`.
- **Sin dependencias nuevas.**
