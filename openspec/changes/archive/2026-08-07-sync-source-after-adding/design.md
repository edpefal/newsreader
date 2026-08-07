## Context

Ver `proposal.md` para la motivación. Estado actual relevante:

- `AddSourceScreen` (`lib/features/sources/presentation/screens/add_source_screen.dart`), en `AddSourceSuccess`, hace `Navigator.of(context).pop(true)` — vuelve a `SourcesScreen`.
- `SourcesScreen` (`lib/features/sources/presentation/screens/sources_screen.dart`) dispara el flujo con `context.push<bool>('/sources/add')` y, si vuelve `true`, recarga `SourcesCubit`.
- `SourceDetailCubit.loadArticles(sourceId)` solo lee de Hive local vía `GetSourceArticles` — no dispara ningún fetch.
- `FeedSyncTrigger.execute()` (interfaz en `lib/core/feed/feed_sync_trigger.dart`, implementación `SupabaseFeedSyncTrigger`) dispara el fetch de feeds de **toda la cuenta** contra la Edge Function `sync-feeds`, que ordena `ORDER BY last_synced_at ASC NULLS FIRST LIMIT 20` — una fuente recién creada (`last_synced_at` nulo) siempre cae primero en ese batch.
- `FeedSyncTrigger.execute()` solo crea artículos en Postgres; no los baja al dispositivo. Bajarlos requiere `SyncUserData.execute()` (`lib/features/sync/domain/usecases/sync_user_data.dart`), que es el mismo mecanismo bidireccional que ya usa `InboxCubit`.
- `InboxCubit._silentFeedRefresh()` ya establece el precedente de disparar un fetch automático (post-login) y tragarse cualquier error silenciosamente, sin mensaje al usuario.
- La ruta `/sources/:id` (`lib/presentation/app/router.dart`) resuelve el `NewsSource` vía `state.extra` o `SourceRepository.getSourceById` y construye `SourceDetailScreen(source:, getSourceArticles:)`.

## Goals / Non-Goals

**Goals:**
- Que una fuente recién agregada muestre sus artículos sin que el usuario tenga que saber que existe pull-to-refresh en el Inbox.
- No introducir un mecanismo de sync por fuente individual nuevo (ni cliente ni servidor).

**Non-Goals:**
- No se resuelve el caso extremo de ≥20 fuentes con `last_synced_at` nulo simultáneamente (la nueva fuente podría no entrar en el batch) — se acepta como limitación conocida del enfoque de reusar el fetch de cuenta completa.
- No se agrega un indicador especial distinto al spinner de carga ya existente en `SourceDetailScreen` — se reusa `SourceDetailLoading`.
- No se comparte el "in-flight dedup" que tiene `InboxCubit` para su propio fetch — este es un trigger independiente, con su propia invocación a `FeedSyncTrigger.execute()`.

## Decisions

### 1. Reusar `FeedSyncTrigger` de cuenta completa, no un sync por fuente

Construir un parámetro de fuente única implicaría cambiar la interfaz `FeedSyncTrigger`, `SupabaseFeedSyncTrigger`, y la Edge Function `sync-feeds`. El ordenamiento `last_synced_at ASC NULLS FIRST` del servidor ya resuelve el caso común (fuente recién creada siempre primera en el batch) sin ningún cambio de servidor. Se documenta el edge case (≥20 fuentes nunca sincronizadas a la vez) como riesgo aceptado, no como algo a resolver en este change.

### 2. `SyncUserData.execute()` (subir) → `FeedSyncTrigger.execute()` → `SyncUserData.execute()` (bajar), igual que `InboxCubit.syncAndReload()`

**Corregido tras verificación manual** — la primera versión de esta decisión omitía el `_syncUserData.execute()` inicial, razonando (mal) que "la fuente recién agregada no tiene borrados pendientes que subir". Esa lectura solo cubría el motivo original del paso en `InboxCubit.syncAndReload()` (evitar que el servidor resucite artículos de una fuente recién *borrada*), pero pasó por alto el motivo simétrico para una fuente recién *agregada*: `SourceRepositoryImpl.addSource()` solo escribe en Hive local, nunca sube nada a Supabase. Sin el `_syncUserData.execute()` inicial, el servidor todavía no sabe que la fuente existe cuando corre `sync-feeds` — el fetch se ejecuta igual, pero para todas las fuentes del usuario *excepto* la nueva, así que nunca llegan artículos. La prueba manual mostró exactamente eso: se agregó la fuente, se mostró el spinner, pero terminó sin artículos.

El flujo correcto (idéntico en forma al de `InboxCubit.syncAndReload()`): `SyncUserData.execute()` (sube la fuente nueva a Postgres) → `FeedSyncTrigger.execute()` (silenciando error — el servidor ya la ve, la sincroniza) → `SyncUserData.execute()` (baja los artículos nuevos a Hive) → `GetSourceArticles.execute(sourceId)` (relee local).

### 3. Reusar el estado `SourceDetailLoading` existente, sin agregar un estado nuevo

A diferencia del indicador diferenciado que se agregó en `AddSourceCubit` (`AddSourceValidatingHeuristics`, para distinguir "buscando candidatos" de "validando"), acá no hay necesidad de distinguir "sincronizando" de "cargando": una fuente recién agregada no tiene artículos locales previos, así que el spinner de `SourceDetailLoading` ya cubre correctamente todo el período (sync + carga) sin ambigüedad visual.

### 4. Flag de "sincronizar al abrir" vía query param de la ruta (`?justAdded=true`), no vía el shape de `state.extra`

`state.extra` en `/sources/:id` ya tiene un tipo fijo (`NewsSource`) usado tanto para la navegación normal (tap en la lista) como para el fallback de deep link (`SourceRepository.getSourceById`). Envolver ese extra en un record `{source, justAdded}` obligaría a tocar el tipo en ambos casos (incluyendo el fallback de deep link, que no tiene forma natural de saber "justAdded"). Usar un query param (`state.uri.queryParameters['justAdded'] == 'true'`) es más simple: por defecto ausente (`false`) en cualquier otra navegación (tap en lista, deep link, back), y explícito solo en el push que sigue a `AddSourceSuccess`.

**Alternativa considerada:** `context.pushReplacement('/sources/${id}', extra: source)` directamente desde `AddSourceScreen`, sin pasar por `SourcesScreen`. Se descarta porque el requirement ya existente "la lista de fuentes se actualiza..." depende de que `SourcesScreen` reciba el resultado del `push<T>('/sources/add')` para recargar — cambiar `AddSourceScreen` para que navegue directamente rompería ese mecanismo (o requeriría duplicar la llamada a `SourcesCubit.loadSources()` fuera de `SourcesScreen`, más frágil). Popear el `NewsSource` de vuelta a `SourcesScreen` y que sea ella quien continúe la navegación mantiene un solo lugar responsable de "qué pasa después de agregar una fuente".

### 5. Errores de sincronización en silencio, sin mensaje de error

Igual criterio que `InboxCubit._silentFeedRefresh()`: es una mejora automática, no una acción explícita del usuario contra la que deba reaccionar. La fuente ya fue validada (feed resuelto y parseado) al momento de agregarla, así que un fallo acá es transitorio (red), no evidencia de que la fuente esté mal configurada.

## Risks / Trade-offs

- **[Riesgo] Fuente no cubierta por el batch de 20** → Mitigación: aceptado como edge case raro (requiere ≥20 fuentes con `last_synced_at` nulo simultáneamente, algo que solo ocurriría tras una importación masiva de OPML con muchas fuentes nunca sincronizadas). Si se vuelve un problema real, la solución futura es un parámetro de fuente única en la Edge Function, fuera de alcance acá.
- **[Trade-off] Doble fetch si el usuario also hace pull-to-refresh del Inbox casi al mismo tiempo** → Aceptado: no se comparte el dedup in-flight de `InboxCubit`, así que en el peor caso hay dos invocaciones de `sync-feeds` casi simultáneas para el mismo usuario — ya cubierto por el dedupe a nivel de constraint de base de datos (capability `feed-polling`, "Dedupe garantizado por constraint de base de datos"), así que no genera artículos duplicados, solo trabajo de servidor redundante en un caso raro.
