## Why

Con login real ya implementado (`add-auth-foundation`), los datos del usuario (fuentes, artículos, favoritos, resúmenes) siguen viviendo exclusivamente en Hive local — se pierden al reinstalar o cambiar de dispositivo, y no hay forma de usar la cuenta desde más de un teléfono. Este change agrega sincronización con la nube, sentando además una base necesaria para el futuro paywall (que va a requerir saber cuántos resúmenes generó un usuario, sin importar desde qué dispositivo).

## What Changes

- Se agregan tablas en Postgres (Supabase) espejo de los datos hoy solo-locales: fuentes, artículos (con su estado de leído/favorito/archivado), y resúmenes diarios — todas con RLS por `user_id = auth.uid()`.
- Nuevo use case `SyncUserData` (nombre distinto y sin relación con `SyncSources`, que sigue haciendo exclusivamente fetch de feeds RSS): al abrir la app, sube los cambios locales pendientes y baja los cambios remotos, en una sola pasada bidireccional.
- Detección de cambios locales vía un campo `updatedAt` en los modelos de Hive (`Article`, `NewsSource`, `DailySummary`), comparado contra un cursor "última vez sincronizado" guardado localmente — sin agregar una cola/outbox separada.
- Los borrados (eliminar una fuente, limpieza automática de artículos) pasan a ser soft-delete (`deletedAt`) hasta que se confirma que se propagaron a todos los dispositivos, en vez de un borrado físico inmediato.
- Resolución de conflictos: last-write-wins por `updatedAt`. El único caso de conflicto real identificado es `ToggleFavorite` (una operación de toggle, no de "set"); se acepta LWW sin merge especial, dado el bajo impacto de perder un toggle concurrente entre dispositivos.
- Primer login de un usuario con datos ya existentes en Hive local: esos datos se suben a la nube como estado inicial (no se descartan).
- Los repositorios y use cases existentes (`ArticleRepositoryImpl`, `SourceRepositoryImpl`, `SummaryRepositoryImpl`, `MarkArticleAsRead`, `ToggleFavorite`, `AddSource`, etc.) **no cambian** — siguen siendo Hive-puro. Solo los datasources locales (`HiveArticleDatasource`, `HiveSourceDatasource`, `HiveSummaryDatasource`) reciben un cambio chico y centralizado: estampar `updatedAt` automáticamente en cada guardado. La sincronización en sí vive enteramente en el nuevo use case `SyncUserData`, que orquesta ambos lados (repos locales + cliente de Supabase), igual que `SyncSources` ya orquesta feeds + repos.
- Sin sincronización en tiempo real (sin Supabase Realtime, sin websockets) — el sync se dispara al abrir la app / pull-to-refresh, igual que el fetch de feeds RSS ya funciona hoy.

## Capabilities

### New Capabilities
- `cloud-sync`: sincronización bidireccional de fuentes, artículos y resúmenes diarios entre dispositivos vía Postgres/Supabase, disparada al abrir la app.

### Modified Capabilities
(ninguna — `source-management`, `article-lifecycle` y `daily-summaries` mantienen el mismo comportamiento observable para el usuario; la sincronización es una capa nueva y aditiva, no cambia qué significa agregar una fuente o marcar un artículo como leído)

## Impact

- Nuevas tablas en Postgres: `sources`, `articles`, `daily_summaries` (nombres a definir en design.md), con policies RLS por `user_id`.
- `lib/core/data/models/`: se agrega `updatedAt` (y `deletedAt` donde aplica) a `NewsSourceModel`, `ArticleModel`, `DailySummaryModel`. Requiere migración de Hive TypeAdapters (`dart run build_runner build`).
- Nuevo `lib/features/sync/domain/usecases/sync_user_data.dart` (o ubicación equivalente).
- Nuevo cliente/abstracción para hablar con las tablas de Postgres desde el use case de sync (a definir en design.md: `supabase_flutter` ya está en el proyecto desde `add-auth-foundation`, o HTTP plano vía `HttpClient` como el resto de la app).
- `lib/core/data/datasources/local/hive_article_datasource.dart`, `hive_source_datasource.dart`, `hive_summary_datasource.dart`: estampar `updatedAt` (y soft-delete vía `deletedAt`) en cada escritura.
- `main.dart`: se dispara `SyncUserData` junto con `SyncSources` al arrancar la app (después de login).
- Sin cambios en los use cases existentes (`MarkArticleAsRead`, `ToggleFavorite`, `AddSource`, `DeleteSource`, etc.) ni en las pantallas.
