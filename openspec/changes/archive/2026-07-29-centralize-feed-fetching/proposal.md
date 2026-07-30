## Why

Cada dispositivo hace fetch de los feeds RSS por su cuenta (`SyncSources`), generando artículos con ids independientes por dispositivo. Cuando dos dispositivos de la misma cuenta descubren el mismo artículo antes de sincronizar entre sí, terminan creando dos filas distintas para el mismo contenido — visible como duplicados en el inbox, y hace que el estado de lectura no converja entre dispositivos (son ids distintos que la sincronización no puede relacionar). Un parche a nivel de cliente (id determinístico derivado de la URL) no resuelve el historial ya existente, porque cada dispositivo solo genera el id nuevo para artículos que todavía no tiene guardados localmente. La causa de fondo es estructural: dos escritores independientes creando el mismo contenido no pueden converger sin coordinación central.

## What Changes

- Se agrega una Edge Function (`sync-feeds`) que hace fetch y parseo de los feeds RSS del lado del servidor, autenticada con el JWT del usuario (nunca `service_role` desde el cliente).
- `sync-feeds` se invoca únicamente on-demand: el pull-to-refresh del cliente la llama directamente antes de traer los cambios, en vez de hacer fetch de RSS en el dispositivo. **Sin cron baseline** — se evaluó y se descartó (ver design.md): agrega complejidad (`pg_cron`/`pg_net`/Vault) que no se justifica para una app de newsletters donde la frescura en segundo plano no es crítica; el pull-to-refresh ya cubre el caso de uso real.
- Los artículos se insertan en Postgres con `id` generado por el servidor (`gen_random_uuid()`) y un constraint `unique(source_id, article_url)` que garantiza que un mismo artículo real nunca se duplique, sin importar cuántas veces se dispare el fetch.
- **BREAKING**: se elimina `SyncSources` del cliente (`lib/features/inbox/domain/usecases/sync_sources.dart`) y su uso en `InboxCubit.syncAndReload()`. El cliente deja de crear artículos — solo los lee de Postgres vía sync.
- **BREAKING**: `SyncUserData` deja de subir (`push`) el contenido de los artículos (title, excerpt, contentHtml, etc.) al servidor. El cliente solo sube el estado de usuario sobre artículos existentes: `isRead`, `isFavorite`, `deletedAt` (soft-delete/archivo).
- Se limpia el historial actual: se borra la tabla `articles` en Postgres y las boxes locales de artículos en cada dispositivo, para empezar con ids canónicos consistentes (no se migra el estado de lectura/favoritos existente).

## Capabilities

### New Capabilities
- `feed-polling`: fetch centralizado de los feeds RSS del lado del servidor, con dedupe garantizado por constraint de base de datos, invocado on-demand desde el cliente (pull-to-refresh).

### Modified Capabilities
Ninguna en `openspec/specs/` todavía — `cloud-sync` solo existe como delta spec pendiente dentro del change `sync-user-data-to-cloud` (no archivado). Como esta propuesta cambia esa misma superficie (qué sube/baja `SyncUserData`), se edita directamente esa delta spec pendiente en vez de declarar un segundo delta en paralelo (ver tarea correspondiente en tasks.md).

## Impact

- **Nuevo**: `supabase/functions/sync-feeds/`, migración SQL para el constraint de dedupe en `articles`.
- **Eliminado**: `lib/features/inbox/domain/usecases/sync_sources.dart` y su registro en DI/tests.
- **Modificado**: `lib/features/sync/domain/usecases/sync_user_data.dart` (deja de subir contenido de artículos), `lib/features/inbox/presentation/cubit/inbox_cubit.dart` (pull-to-refresh invoca `sync-feeds` en vez de `SyncSources`).
- **Datos**: se trunca `articles` en Postgres y las boxes Hive locales de artículos en todos los dispositivos (pérdida intencional del estado de lectura/favoritos actual, según se acordó explorando el cambio).
- Depende de que `sync-user-data-to-cloud` siga su curso (o se coordine con esta change) ya que ambas tocan `SyncUserData` y la tabla `articles`.
