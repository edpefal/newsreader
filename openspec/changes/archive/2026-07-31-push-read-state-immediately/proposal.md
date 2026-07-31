## Why

Hoy, marcar un artículo como leído solo se sube a la nube en el próximo `SyncUserData.execute()` (login, resume desde background, o pull-to-refresh) — el capability `cloud-sync` funciona explícitamente sin tiempo real. Eso significa que si el usuario lee un artículo en el celular y no vuelve a abrir la app ni hace pull, otro dispositivo de la misma cuenta puede tardar mucho en enterarse (o nunca, si la app no se cierra ni reabre en ese dispositivo tampoco). Queremos reducir esa ventana de staleness para el caso más común — "leído" — sin esperar a un trigger de sync completo y sin agregar un backend nuevo.

## What Changes

- `MarkArticleAsRead` empuja el estado (`is_read`, `read_at`, `updated_at`) del artículo recién marcado a Supabase de forma inmediata y best-effort, además de la actualización local en Hive que ya hacía.
- El push inmediato es fire-and-forget: no bloquea ni retrasa la actualización local ni el reload de la UI. Si falla (sin red, error de Supabase), se ignora silenciosamente — la próxima sincronización completa (`SyncUserData`) lo sube igual porque `updatedAt` ya cambió localmente.
- El push solo se intenta si hay una sesión activa (mismo gate que usa `SyncUserData.execute()`).
- Se extrae el mapeo `ArticleModel` → fila parcial de Supabase (hoy privado en `SyncUserData._articleStateToRow`) a un lugar compartido en `core/sync`, para que tanto el sync por batch como este push puntual usen la misma lógica de columnas.
- Fuera de alcance: favoritos y archivado siguen sincronizándose solo por los triggers existentes (no se generaliza el mecanismo en este change). No se crea ningún endpoint/Edge Function nuevo.

## Capabilities

### New Capabilities

(ninguna)

### Modified Capabilities

- `cloud-sync`: se agrega un camino de propagación adicional para el estado "leído" de un artículo — push inmediato y best-effort al marcarlo, en paralelo al mecanismo de sincronización completa por trigger que ya existe (que sigue siendo la red de seguridad si el push falla).

## Impact

- `lib/features/inbox/domain/usecases/mark_article_as_read.dart`: dispara el push inmediato tras actualizar el artículo local.
- `lib/core/sync/` (nuevo helper compartido): mapeo `ArticleModel` → fila parcial de Supabase, reusado por `SyncUserData` y por `MarkArticleAsRead`.
- `lib/features/sync/domain/usecases/sync_user_data.dart`: usa el helper compartido en vez de su mapeo privado.
- `lib/core/di/injection.dart`: `MarkArticleAsRead` pasa a depender de `CloudSyncClient` y `AuthClient`.
- Sin cambios de esquema en Supabase ni Edge Functions nuevas — se reutiliza `CloudSyncClient.updatePartial` sobre la tabla `articles` ya existente.
