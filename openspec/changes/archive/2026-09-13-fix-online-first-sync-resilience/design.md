## Context

`SyncUserData.execute()` (`lib/features/sync/domain/usecases/sync_user_data.dart`) es el único punto que sube/baja datos con `SupabaseCloudSyncClient` (`lib/core/sync/supabase_cloud_sync_client.dart`), que envuelve cualquier error de Postgrest en `CloudSyncException(String)` sin `AppErrorCode` ni timeout propio. `SyncUserData.execute()` no tiene `try/catch` interno, así que esa excepción se propaga tal cual a cada caller. Hoy la capturan con gracia solo `main.dart` (arranque) e `InboxCubit.syncAndReload()` en su segunda mitad; el resto de los callers (`SourceDetailCubit.syncAndLoadArticles`, `InboxCubit.syncAfterSignIn`, `InboxCubit._silentFeedRefresh`) no la capturan, lo que deja `SourceDetailCubit` en `SourceDetailLoading()` indefinidamente si falla. Ver proposal.md - Why para el resto de los hallazgos (guard de concurrencia ausente, orden fetch-antes-de-subir en `_silentFeedRefresh`, sin push inmediato de borrado/rename de fuente, sin flush antes de limpiar datos al cerrar sesión).

## Goals / Non-Goals

**Goals:**
- Que ningún cubit quede en un estado de carga indefinido por un fallo de `SyncUserData.execute()` o de `SupabaseCloudSyncClient`.
- Que los errores de sincronización con la nube usen la misma jerarquía (`AppErrorCode`) que el resto de los errores de red de la app, para que el código que ya sabe mostrar `isNetworkError`/snackbars localizados también sirva acá sin duplicar lógica.
- Que invocaciones solapadas de `SyncUserData.execute()` no dupliquen trabajo ni puedan regresionar el cursor de sincronización.
- Que el orden "subir pendientes → disparar fetch de feeds" sea el mismo en todos los callers que encadenan ambas cosas, para no reabrir la ventana de "artículo resucitado" ya cerrada en `syncAndReload()`.
- Que borrar/renombrar una fuente tenga la misma garantía de propagación oportuna que ya tienen favoritos/leído.
- Que cerrar sesión con cambios locales sin subir sea una decisión informada del usuario, no una pérdida silenciosa.

**Non-Goals:**
- Detección proactiva de conectividad, banner de "sin conexión", cola de reintentos persistente con backoff, o sync periódico en segundo plano — explícitamente fuera de alcance (ver proposal.md).
- Cambiar el modelo de resolución de conflictos (`last-write-wins` por `updatedAt`) — no se toca.
- Tocar el timeout ni el comportamiento de `sync-feeds` (Edge Function) — solo el cliente Flutter.

## Decisions

### 1. `CloudSyncException` pasa a extender `AppException` con `AppErrorCode`

`CloudSyncException` deja de ser una clase suelta con un `String message` y pasa a extender `AppException` (`lib/core/errors/app_exception.dart`), igual que `NetworkException`/`TimeoutException`. `SupabaseCloudSyncClient` clasifica el error capturado antes de relanzarlo:
- `TimeoutException` (de `dart:async`, la del propio `Future.timeout` que se agrega en la decisión 2) → `AppErrorCode.timeout`.
- Errores cuyo tipo o mensaje indican falta de conectividad (`SocketException`, o el `PostgrestException`/`ClientException` que el SDK de Supabase lanza cuando no hay red) → `AppErrorCode.network`.
- Cualquier otro error (ej. `PostgrestException` con código de error de servidor) → un nuevo `AppErrorCode.cloudSyncFailed`, para no perder la distinción "esto vino de la nube" mezclándolo con `unknown`.

Alternativa descartada: mantener `CloudSyncException` como una clase separada y solo agregar un mapeo manual a `AppErrorCode` en cada caller. Se descarta porque obligaría a repetir esa clasificación en cada uno de los ~5 call sites en vez de una sola vez en el cliente, y porque el resto de la app ya asume que "error de dominio visible al usuario" = `AppException`.

### 2. Timeout explícito en `SupabaseCloudSyncClient`

Se envuelve cada llamada Postgrest (`upsert`, la secuencia de `update` de `updatePartial`, y cada página de `fetchChangedSince`) en `.timeout(Duration(seconds: 30))`. 30s porque `fetchChangedSince` puede paginar varias tandas de 1000 filas en una resincronización grande (ver comentario existente sobre el límite de 1000 filas de PostgREST); un timeout más corto que el de `sync-feeds` (90s) sería sensato dado que esto es solo lectura/escritura de Postgres, no fetch de RSS externo.

Alternativa descartada: un único timeout para todo `SyncUserData.execute()` (una sola tabla lenta no debería abortar las demás tablas que ya se sincronizaron bien).

### 3. Guard de concurrencia en `SyncUserData` vía un caller compartido, no dentro del use case

En vez de agregar el guard `Future<void>? _inFlight` dentro de `SyncUserData` mismo (que tiene alcance de instancia y `get_it` ya lo registra como singleton, así que funcionaría), se sigue el mismo patrón que `InboxCubit._inFlightFeedSync`: el guard vive donde efectivamente pueden solaparse las invocaciones. Dado que hoy el solape real detectado es entre el arranque diferido de `main.dart` y `didChangeAppLifecycleState` → `InboxCubit.syncInBackground()`, y `SyncUserData` ya es un singleton vía `get_it`, el guard se agrega directamente en `SyncUserData.execute()` (un solo `Future<void>? _inFlight` de instancia, reusado por cualquier caller) — es la opción que protege a todos los callers presentes y futuros sin coordinarlos manualmente entre sí, y es consistente con que `SyncUserData` ya centraliza el cursor de sincronización como estado de instancia.

Alternativa descartada: agregar el guard en cada cubit que llama a `SyncUserData` (como hace `InboxCubit` para `_feedSyncTrigger`). Se descarta porque el solape problemático es *entre* distintos cubits/entry points (arranque vs. resume vs. detalle de fuente), no dentro de uno solo — un guard por cubit no lo previene.

### 4. Orden subida-antes-de-fetch: extraer el patrón ya usado en `syncAndReload()`

`InboxCubit.syncAndReload()` ya implementa el orden correcto (`_syncUserData.execute()` → `_triggerFeedSync()` → `_syncUserData.execute()`) con su razón documentada en un comentario. `_silentFeedRefresh()` invierte el orden (fetch primero). Se corrige `_silentFeedRefresh()` para que seguir el mismo orden: subir pendientes → fetch → bajar. `SourceDetailCubit.syncAndLoadArticles()` ya sigue el orden correcto (sync → fetch → sync); solo le falta el manejo silencioso del primer `execute()` (ver decisión 5).

No se extrae una función compartida entre `InboxCubit` y `SourceDetailCubit` para este patrón de 3 pasos: son cubits de features distintas (`inbox` y `sources`) y, por la regla de arquitectura del proyecto, un feature no importa código de otro — extraerlo a `core/` para tres líneas usadas en dos sitios sería una abstracción prematura para el tamaño real del problema.

### 5. Manejo silencioso simétrico en `SourceDetailCubit`, sin nuevo estado

En vez de agregar un estado `SourceDetailError` a `SourceDetailState`, se envuelve el primer `_syncUserData.execute()` de `syncAndLoadArticles()` en el mismo `try/catch` (reportar a observabilidad, seguir adelante) que ya usa el `_feedSyncTrigger.execute()` de ese mismo método. El requirement de `source-management` ya especifica que un fallo de sincronización en esta pantalla se maneja en silencio mostrando los artículos locales disponibles — no hay necesidad de un estado de error distinto, y agregar uno sería introducir un camino de UI (mensaje de error visible) que el requirement existente explícitamente no pide.

### 6. Push inmediato de borrado/rename de fuente: mismo patrón que favoritos/leído, sin bloquear la UI

`DeleteSource.execute()` y `UpdateSourceName.execute()` agregan, después de la escritura local, un `unawaited` best-effort a `SyncUserData.execute()` (no un push de una sola tabla — se reusa el use case completo porque ya es idempotente y barato cuando no hay nada más pendiente), envuelto en `try/catch` que solo reporta a observabilidad, igual que `MarkArticleAsRead`/`ToggleFavorite`. `SourcesCubit.deleteSource()`/`updateSourceName()` no cambian su firma ni su `await` actual sobre el use case — el push es responsabilidad del use case, no del cubit, para que cualquier caller futuro (no solo `SourcesCubit`) lo obtenga gratis.

Alternativa descartada: un push específico de una sola fila (`upsert` puntual de esa fuente) en vez de `SyncUserData.execute()` completo. Se descarta por consistencia con el patrón ya elegido para favoritos/leído y porque evita introducir un segundo camino de serialización fuente→fila (`SyncUserData._sourceToRow` es privado hoy).

### 7. Confirmación de cierre de sesión con flush previo

`_signOut()` en `SettingsScreen` intenta `SyncUserData.execute()` antes de `ClearLocalUserData.execute()`. Si ese intento falla (se captura `AppException`/lo que sea que lance ahora `SyncUserData`), se muestra un `AlertDialog` de confirmación con un mensaje nuevo (`settingsSignOutUnsyncedChangesWarning` o similar, con sus 3 traducciones) indicando que puede haber cambios recientes sin sincronizar, con opciones "Cancelar" y "Cerrar sesión de todos modos". Si el flush tiene éxito, se cierra sesión directamente sin diálogo adicional (comportamiento actual, sin fricción para el caso feliz).

Alternativa descartada: bloquear el cierre de sesión por completo si el flush falla. Se descarta porque el usuario podría estar sin conexión de forma prolongada y necesitar cerrar sesión igual (ej. para probar con otra cuenta) — la garantía que importa es que sea una decisión informada, no impedirla.

## Risks / Trade-offs

- [El guard de concurrencia de `SyncUserData.execute()` podría enmascarar que dos callers legítimamente quieren resultados independientes] → No es el caso hoy: todos los callers actuales solo quieren "que el estado esté al día", nunca un resultado por-invocación: reusar la invocación en vuelo (igual que `_inFlightFeedSync`) es semánticamente correcto.
- [Clasificar `PostgrestException` como `network` por heurística de mensaje/tipo puede tener falsos negativos] → Se prioriza cubrir los casos reales observables (`SocketException`, error de conexión de `http`/Supabase) sobre una clasificación exhaustiva; cualquier error no reconocido cae en `AppErrorCode.cloudSyncFailed`, que sigue siendo mejor que un `CloudSyncException` suelto sin código.
- [El push inmediato de borrado/rename de fuente agrega una llamada de red adicional (`SyncUserData.execute()` completo) a cada borrado/rename, más costosa que un `upsert` puntual] → Aceptado: mismo costo relativo que ya se paga en cada `MarkArticleAsRead`/`ToggleFavorite`, y borrar/renombrar una fuente es una acción de baja frecuencia comparada con marcar artículos como leídos.
- [El diálogo de confirmación al cerrar sesión con flush fallido agrega un paso a un flujo existente sin fricción] → Aceptado: solo aparece en el caso de falla real (sin red o Supabase caído), no en el camino feliz.

## Migration Plan

Sin migración de datos ni de esquema. Es un cambio de comportamiento del cliente Flutter, desplegable como cualquier release normal de la app (no requiere coordinación con las Edge Functions ni con Postgres). Rollback: revertir el release de la app: no hay estado persistido nuevo que requiera limpieza (el nuevo `AppErrorCode.cloudSyncFailed` es solo un valor de enum adicional, y el guard de concurrencia no persiste nada).
