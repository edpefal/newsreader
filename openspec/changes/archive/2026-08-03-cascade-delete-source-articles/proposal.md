## Why

Al eliminar una fuente, el borrado de sus artículos en Supabase depende hoy de que el cliente ejecute con éxito un loop de un `UPDATE` por artículo (`CloudSyncClient.updatePartial`); si ese loop se interrumpe (red, backgrounding, cierre de la app) antes de terminar, las filas restantes quedan vivas en Supabase para siempre — sin retry, sin red de seguridad del lado del servidor. Esto ya ocurrió en producción: un usuario eliminó la fuente Hacker News hace tiempo y sus artículos (no favoritos) resucitaron en el dispositivo tras un pull posterior, porque nunca llegaron a tener `deleted_at` en Supabase.

## What Changes

- Nuevo trigger en Postgres sobre `sources`: cuando una fuente pasa a tener `deleted_at` (soft-delete), cascada automáticamente ese `deleted_at`/`updated_at` a todos sus artículos del mismo usuario en la misma transacción, **excepto los favoritos** (mismo criterio que ya usa el cliente hoy vía `keepFavorites: true`).
- La garantía de borrado deja de depender de que el cliente empuje exitosamente N filas de artículos: solo necesita empujar el borrado de la fuente (una sola fila), y el servidor hace el resto.
- Backfill de una sola vez: reparar los artículos ya huérfanos en producción (de fuentes ya borradas, no favoritos, que nunca llegaron a tener `deleted_at`).
- `CloudSyncClient.updatePartial` pasa de un loop de updates fila por fila a un único `UPDATE ... WHERE id IN (...)` cuando el payload es compartido, para reducir la superficie de fallo de cualquier sincronización batch (no solo la de borrado de fuente).

## Capabilities

### Modified Capabilities
- `cloud-sync`: el borrado de una fuente ahora garantiza, del lado del servidor, que sus artículos (no favoritos) queden marcados como borrados — ya no depende únicamente de que el cliente propague el estado de cada artículo individualmente.

## Impact

- **Base de datos**: nueva migration en `supabase/migrations` con el trigger de cascada + statement de backfill.
- **Cliente**: `lib/core/sync/supabase_cloud_sync_client.dart` (`updatePartial` pasa a batch).
- **No afectado**: `DeleteSource`, `ArticleRepository.deleteArticlesBySource` y el criterio `keepFavorites: true` del cliente (siguen igual — el trigger espeja ese mismo criterio, no lo reemplaza). Tampoco se introduce borrado físico de filas; se mantiene el patrón de soft-delete vía `deleted_at` exclusivamente.
