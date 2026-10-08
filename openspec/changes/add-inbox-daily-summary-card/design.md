## Context

Ver `proposal.md` para la motivación. Estado actual relevante:

- `DailySummary` (entidad) / `DailySummaryModel` (Hive `typeId: 2`, caja indexada por `dateKey(date)`) llega desde el servidor vía `SyncUserData._syncSummaries`. El cliente nunca crea resúmenes, solo los lee.
- La Edge Function `generate-daily-summaries` guarda `date = start.toISOString()` (medianoche local del usuario expresada en UTC) y usa `insert` plano: nunca reescribe una fila, así que no puede resetear `dismissed_at`.
- `dateKey` formatea ese `DateTime` en UTC. Para offsets negativos (México) la clave coincide con la fecha local; para offsets positivos (Francia, España) cae en el día anterior, por lo que `getByDate(hoy)` **no sirve** para saber cuál es el resumen de hoy.
- `SyncUserData` sube solo los resúmenes con `updatedAt` posterior al cursor (`getChangedSince`) y aplica los remotos con `applyRemote`, que reemplaza el modelo completo (ya conserva `sourceBlocks` local si el remoto trae `null`).
- `SupabaseCloudSyncClient.upsert` es un upsert plano de PostgREST (solo toca las columnas del payload); `updatePartial` actualiza solo las columnas indicadas y es lo que usan `MarkArticleAsRead`/`ToggleFavorite` para su push inmediato.
- El Inbox usa `InboxCubit` + un `AnimatedList` de `Article` dentro de un `RefreshIndicator`, con separadores de fecha, `Dismissible(endToStart)` por artículo y `openArticleId` para el resaltado en dos paneles. La rama de lista vacía es un `SingleChildScrollView` aparte. La rama Inbox del router (`articleListBranch`) solo conoce `/` y `/article/:id`.
- `SummaryDetailScreen` vive en la rama Resúmenes (`/summaries/:id`, resuelto con `SummaryRepository.getById`), tiene su propio `Scaffold`+`AppBar` y ya se embebe así en el panel derecho de esa rama.
- El tema es monocromo (ink/paper). `primaryContainer` no está definido; el único color de marca es `ReevoAccent` (óxido), una `ThemeExtension` que solo se referencia de forma explícita.

## Goals / Non-Goals

**Goals:**
- Tarjeta temporal del resumen de hoy en el Inbox, con descarte sincronizado entre dispositivos y push inmediato.
- Reutilizar `SummaryDetailScreen` sin romper el layout adaptativo.
- No requerir cambios en versiones de cliente ya publicadas.

**Non-Goals:**
- Cambiar la generación del resumen, su elegibilidad o la tab Resúmenes.
- Marcar como "leído" un resumen en la tab Resúmenes (`dismissed_at` es solo "se quitó del Inbox").
- Acumular tarjetas de días anteriores.
- Un backfill en servidor: tras actualizar, quien ya leyó el resumen de hoy antes de actualizar verá la tarjeta una vez.
- Cambios de huso horario a mitad de día.

## Decisions

**1. `dismissed_at` en `DailySummary`, no una tabla ni un flag local.**
Columna nullable en `daily_summaries` + `@HiveField(7) DateTime? dismissedAt`. Reutiliza el sync existente. Descartadas: flag solo local (se eligió sincronizar entre dispositivos) y una tabla `dismissed_cards` aparte.

**2. Descartar sube `updatedAt` y hace push inmediato.**
`DismissDailySummary` escribe `dismissedAt = now` y `updatedAt = now` en una sola operación del datasource, idempotente (si ya tiene `dismissedAt`, no hace nada: no emite dos veces ni re-sube). Luego intenta `CloudSyncClient.updatePartial('daily_summaries', [{id, dismissed_at, updated_at}])` best-effort, sin bloquear, ignorando fallas y solo con sesión activa, igual que `MarkArticleAsRead`. El sync completo lo repara si falla. Esto replica el patrón ahora documentado en `CLAUDE.md` ("Offline-first con push inmediato").

**3. `applyRemote` conserva `dismissedAt` local.**
Igual que hoy con `sourceBlocks`: si el remoto llega con `dismissed_at == null` y el local tiene valor, se conserva el local, evitando que un sync pise un descarte aún no subido.

**4. "Resumen pendiente" se deriva, comparando fechas locales; no con `getByDate`.**
`GetPendingInboxSummary` recorre `getAll()` y devuelve el resumen cuya `date.toLocal()` (solo la parte de fecha) coincide con la fecha local de hoy y que tiene `dismissedAt == null`, o `null`. Es correcto para cualquier offset sin tocar datos existentes. Descartada: corregir cómo se indexa la caja (invasivo, tocaría datos ya guardados). El mismo criterio de "es hoy" lo reutiliza `DismissDailySummary` para decidir si escribe (solo hoy).

**5. Reactividad local: `Stream` del repositorio, no refresh manual.**
`SummaryRepository` expone `Stream<List<DailySummary>> watchAll()`, respaldado por `box.watch()` de Hive CE dentro del datasource (Hive no sube de capa). `InboxCubit` se suscribe en su constructor/`loadArticles` y recalcula `pendingSummary` ante cada evento; cancela la suscripción en `close()`. Un solo mecanismo cubre los tres casos: abrir desde otra tab, descarte traído por sync y llegada del resumen del día. Descartada: `refreshPendingSummary()` llamado al volver a la tab y tras cada sync (dos puntos de llamada olvidables).

**6. La tarjeta vive en un `CustomScrollView`, no en el `AnimatedList`.**
Se refactoriza `InboxScreen` a `RefreshIndicator > CustomScrollView` con `SliverToBoxAdapter` (tarjeta, con `AnimatedSize`/`AnimatedSwitcher` para entrada y salida) + `SliverAnimatedList` (artículos y separadores). La rama de lista vacía aloja la tarjeta y el estado vacío dentro del mismo scroll. Cambia el tipo de `_listKey` (`SliverAnimatedListState`) y hay que preservar swipe de artículos, animación de salida y resaltado `openArticleId`; se cubre con tests de los comportamientos existentes. `InboxLoaded` gana `pendingSummary` (el `DailySummary?`) y `openSummaryId`; `visibleArticles` y la búsqueda no se tocan. Descartada: `Column` con la tarjeta fija arriba (contradice que scrollee con la lista).

**7. Ruta propia `/summary/:id` en la rama Inbox.**
Se agrega bajo la raíz `/` de `articleListBranch`, reutilizando `SummaryDetailScreen`, `RouteExtraResolver` + `SummaryRepository.getById`, y una ruta anidada de artículo (`:articleId`) como en Resúmenes, para que abrir un artículo desde el resumen no cambie de tab. Descartada: reutilizar `/summaries/:id` (cambia de tab/rail en iPad y rompe el contexto del back). `onNotFound` reporta `captureMessage` `warning` antes de redirigir a `/`. Como el router ya usa `getIt` en este archivo, el cableado del callback ahí no viola la regla de `get_it`.

**8. El descarte ocurre al mostrarse el detalle: callback `onOpened`.**
`SummaryDetailScreen` recibe `onOpened` por constructor y lo invoca una vez al mostrarse. Ambas rutas (`/summaries/:id` y `/summary/:id`) lo conectan a `DismissDailySummary`, que descarta solo el resumen de hoy e ignora los demás. Así cubre también la restauración de ruta y los enlaces directos, y abrir desde la tab Resúmenes quita la tarjeta. Descartadas: escribirlo en el tap de la tarjeta y en el de `SummaryListItem` por separado (no cubre rutas abiertas directamente) y un `SummaryDetailCubit` nuevo (pesado para una pantalla de solo lectura).

**9. Ciclo de vida de la tarjeta, por ancho.**
- `< 840dp`: al abrir se descarta y la tarjeta sale de `pendingSummary` con animación.
- `>= 840dp`: `dismissedAt` se persiste al abrir, pero `InboxCubit` conserva el resumen visible mientras `openSummaryId == summary.id`. `openSummaryId` se mantiene mientras la ruta activa esté bajo `/summary/:id/**` (incluido un artículo abierto desde él, con back al resumen) y se limpia solo al volver al estado vacío (`onEmptyDetailShown`, hoy `closeOpenArticle`) o al seleccionar otro elemento. `openArticleId` y `openSummaryId` son mutuamente excluyentes.

**10. Swipe: `endToStart`, fondo propio, sin deshacer.**
Mismo gesto que los artículos, con un fondo distinto del teal de "leído" (otro color, ícono de cerrar). Sin SnackBar de deshacer: revertir `dismissed_at` ya sincronizado es complejidad innecesaria para algo recuperable desde la tab. Además, acción semántica "Descartar" para lectores de pantalla.

**11. Aspecto: tarjeta sólida con `ReevoAccent`, referenciado explícitamente.**
Relleno `ReevoAccent.unreadFavoriteAccent` (`#C1401F` claro / `#E2794D` oscuro), texto con el color de mayor contraste de cada tema (papel sobre óxido en claro; superficie oscura sobre óxido claro en oscuro). Estado seleccionado en dos paneles: borde de 2px en `onSurface` con margen para que no se funda con la lista, y CTA "Abierto" en vez de "Leer" (el relleno no puede ser más fuerte, así que no se reutiliza `secondaryContainer`). No se usa `primaryContainer` (no está definido en este tema monocromo y daría el lavanda por defecto de Material). Hasta 3 avatares + `+N`; se reutiliza el widget de avatar existente de `SummaryListItem`/tile (si no es reutilizable, se extrae a `core/widgets/`, sin importar de otro feature).

**12. Eventos y errores desde el Cubit/caso de uso, vía `TelemetryClient`.**
`inbox_summary_card_opened` / `_dismissed` con `{article_count}` se emiten en `InboxCubit` solo desde el tap y el swipe de la tarjeta; no al abrir desde la tab Resúmenes ni en el camino de sync/`applyRemote`. Los `catch (e, st)` nuevos llaman `captureException(e, st)` con contexto `{operation: load|watch|dismiss}` y sin `content`. `sourceBlocks == null` no se reporta.

**13. Textos en los 3 `.arb`, español neutro con tuteo.**
Claves `inboxSummaryCardTitle`, `inboxSummaryCardCta`, `inboxSummaryCardOpen`, `inboxSummaryCardDismiss`, `inboxSummaryCardCount` (con `count` y `sources`, plural), `inboxSummaryCardCountOnly` (fallback sin fuentes). El francés lleva texto real.

## Risks / Trade-offs

- **[Cliente nuevo antes que la migración]** El upsert/`updatePartial` de `daily_summaries` falla por columna inexistente y se pierde el sync de resúmenes → **migración primero, cliente después** (tarea explícita; Sentry lo mostraría con contexto `daily_summaries`).
- **[Clientes 1.8.x]** No conocen `dismissed_at` → el upsert plano no lo borra y la columna es nullable, así que son compatibles. Verificar en `reevo-dev` antes de prod.
- **[Refactor del `AnimatedList`]** Toca animaciones de swipe, salida al abrir y resaltado en iPad → tests de esos comportamientos antes de mover nada, y cambio acotado a esa pantalla.
- **[Primera apertura tras actualizar]** Quien ya leyó el resumen de hoy antes de actualizar verá la tarjeta una vez. Aceptado; no hay backfill.
- **[Dos dispositivos descartan a la vez]** Ambos escriben un `dismissed_at` no nulo; el efecto visible es el mismo.
- **[Cambio de día con la app abierta]** `pendingSummary` se recalcula con cada evento del `Stream` y en cada carga/sync; no hay timer de medianoche.
- **[Selección dual en iPad]** `openArticleId` y `openSummaryId` son mutuamente excluyentes; el cubit limpia uno al fijar el otro, y `openSummaryId` debe sobrevivir a la navegación a la ruta anidada de artículo.
- **[`Scaffold`/`AppBar` propios de `SummaryDetailScreen`]** Ya es el patrón de la rama Resúmenes en dos paneles; se mantiene el mismo comportamiento, sin introducir un caso nuevo.

## Migration Plan

1. Rama `add-inbox-daily-summary-card`; implementar y correr `flutter analyze` + `flutter test`.
2. Migración `add_daily_summaries_dismissed_at` (aditiva, nullable, sin default) aplicada con `apply_migration` según la nota de migraciones del repo (no `db push`). Confirmar con el usuario si va a `reevo-dev`, `reevo` o ambos. **Debe aplicarse antes de publicar el cliente.**
3. Publicar el cliente. No hay rollback de datos necesario: la columna es inocua si el cliente se revierte.
4. Tras el merge, volver a `main`, actualizar y borrar la rama local y remota.
