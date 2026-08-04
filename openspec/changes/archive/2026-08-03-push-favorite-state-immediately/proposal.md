## Why

Marcar un artículo como favorito solo se sube a la nube en el próximo `SyncUserData.execute()` (login, resume, o pull-to-refresh) — igual que le pasaba a "leído" antes de `push-read-state-immediately`. El usuario quiere que favoritos se comporte igual que leído hoy: no depender de un pull-to-refresh para que el servidor se entere de que algo se marcó como favorito.

## What Changes

- `ToggleFavorite` empuja el estado (`is_favorite`, `saved_as_favorite_at`, `updated_at`) del artículo a Supabase de forma inmediata y best-effort, además de la actualización local en Hive que ya hacía — mismo patrón que ya usa `MarkArticleAsRead` desde `push-read-state-immediately`.
- El push inmediato es fire-and-forget: no bloquea ni retrasa la actualización local ni la UI. Si falla, se ignora silenciosamente — la próxima `SyncUserData` lo sube igual porque `updatedAt` ya cambió localmente.
- El push solo se intenta si hay sesión activa (mismo gate que `MarkArticleAsRead`).
- Se reusa el helper compartido `articleStateRow` (`core/sync/article_state_row.dart`) que ya centraliza el mapeo `ArticleModel` → fila parcial de Supabase — no se crea un mapeo nuevo.

## Capabilities

### Modified Capabilities
- `cloud-sync`: se agrega, para el estado "favorito" de un artículo, el mismo camino de propagación adicional que ya existe para "leído" — push inmediato y best-effort al marcarlo, en paralelo al mecanismo de sincronización completa que sigue siendo la red de seguridad.

## Impact

- `lib/features/reader/domain/usecases/toggle_favorite.dart`: dispara el push inmediato tras actualizar el artículo local (favorito y des-favorito).
- `lib/core/di/injection.dart`: `ToggleFavorite` pasa a depender de `CloudSyncClient` y `AuthClient`, igual que `MarkArticleAsRead`.
- Sin cambios de esquema en Supabase ni Edge Functions nuevas — se reutiliza `CloudSyncClient.updatePartial` sobre la tabla `articles` ya existente.
- Fuera de alcance: archivado sigue sincronizándose solo por el trigger completo existente (no se generaliza el mecanismo a todos los campos de estado en este change).
