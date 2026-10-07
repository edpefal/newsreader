## Why

Un usuario de prod tiene el mismo feed (`https://www.error500.net/feed`) dado de alta dos veces como fuentes activas distintas, cada una con su propia copia de ~26 artículos: cada artículo aparece duplicado en el Inbox y el resumen diario del 4 de octubre salió con dos entradas `Error500` en su agrupación por fuente. La causa es que nada impide el duplicado fuera del dispositivo donde se agrega: `AddSource` solo consulta la caja local (`sourceExists`), `sources` en Supabase no tiene unicidad por `(user_id, feed_url)`, y la sincronización sube y baja por `id` sin deduplicar por URL. Agregar el mismo feed desde un dispositivo que todavía no tenía la otra fuente (otro dispositivo, sesión nueva antes de sincronizar, caja local reiniciada) crea dos filas.

## What Changes

- **Servidor (migración):** deduplicar los datos existentes y crear un índice único parcial sobre `sources (user_id, feed_url) WHERE deleted_at IS NULL`. La deduplicación conserva la fuente más antigua (`added_at`), fusiona el estado de lectura/favorito/archivado de los artículos repetidos en los de la fuente conservada, mueve los artículos que solo existían en la duplicada y da de baja (`deleted_at`) la fuente sobrante.
- **Cliente, al agregar:** `AddSource` consulta también a la nube (best-effort, si hay sesión y red) antes de crear la fuente, para informar "ya estás suscrito" cuando el feed existe en otro dispositivo; sin red o sin sesión se mantiene la verificación local de hoy.
- **Cliente, al sincronizar:** el `upsert` de `sources` deja de ser una operación que se cae completa ante un conflicto de unicidad (error `23505`): las bajas se envían primero, y si aun así hay conflicto se reconcilia fuente por fuente adoptando la fuente remota existente y descartando la local duplicada, sin bloquear el resto del ciclo de sincronización.
- Sin texto nuevo visible: se reutiliza el mensaje de fuente duplicada que ya existe en los 3 idiomas, y no se agrega ningún `AppErrorCode` nuevo. Sin cambios de layout ni de pantallas.
- Comparación de `feed_url` por igualdad exacta, igual que hoy; no se agrega normalización (barra final, mayúsculas) en este change.

## Capabilities

### New Capabilities
<!-- Ninguna -->

### Modified Capabilities
- `source-management`: la verificación de duplicado al agregar una fuente también considera las fuentes del usuario que existen en la nube y aún no están en el dispositivo.
- `cloud-sync`: una fuente activa es única por usuario y feed URL en el servidor; un conflicto de unicidad al subir una fuente se reconcilia sin impedir la sincronización de las demás entidades.

## Impact

- Nueva migración en `supabase/migrations/` (deduplicación + índice único parcial).
- `lib/features/sources/domain/usecases/add_source.dart` y la abstracción de nube que use para consultar fuentes remotas (`core/sync/`), con su registro en `core/di/injection.dart`.
- `lib/core/sync/supabase_cloud_sync_client.dart` (clasificación del `23505`) y `lib/features/sync/domain/usecases/sync_user_data.dart` (orden de envío y reconciliación).
- Tests unitarios de `AddSource`, de `SyncUserData` y de la clasificación del error; verificación de la migración con SQL sobre datos de ejemplo.
- **Orden de despliegue:** la migración no debe aplicarse antes de que el cliente nuevo esté publicado (ver `design.md`). Requiere confirmar con el usuario a cuál(es) proyecto(s) de Supabase (`reevo` prod / `reevo-dev`) se aplica.
- **Fuera de alcance:** agrupar el resumen diario por `source_id` en vez de por nombre, y normalizar `feed_url`.
