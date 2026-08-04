## Context

El borrado es soft-delete exclusivamente vía `deleted_at` (sin policy de delete física, ver `supabase/migrations/20260725000000_sync_user_data.sql`). Hoy `sources` y `articles` no tienen ninguna relación declarada a nivel de base de datos (`articles.source_id` es `text` suelto, sin `references`); toda la propagación del borrado de artículos de una fuente depende del cliente: `DeleteSource` soft-borra localmente (respetando `keepFavorites: true`) y, en la próxima corrida de `SyncUserData`, empuja el estado de cada artículo vía `CloudSyncClient.updatePartial`, que hoy hace un `UPDATE` por fila en un loop secuencial sin retry. Ver proposal.md - Why para el caso real que disparó este change (artículos de Hacker News resucitados tras quedar huérfanos en Supabase).

## Goals / Non-Goals

**Goals:**
- Garantizar, del lado del servidor, que borrar una fuente deje sus artículos (no favoritos) marcados como borrados — sin depender de que el cliente complete un push de N filas.
- Reparar los artículos ya huérfanos en producción.
- Reducir la fragilidad general de `updatePartial` para sincronizaciones batch futuras.

**Non-Goals:**
- No se introduce borrado físico de filas — se mantiene soft-delete vía `deleted_at` en todos los casos.
- No se cambia el criterio de negocio `keepFavorites: true` del cliente ni la UX de borrado de fuentes.
- No se agrega un mecanismo de sincronización en tiempo real ni se cambia cuándo corre `SyncUserData` (sigue disparándose en los mismos puntos: apertura, pull-to-refresh, foreground, login).

## Decisions

**Trigger de Postgres sobre `sources`, no una Edge Function ni un RPC explícito.** Un trigger `AFTER UPDATE` que dispara cuando `deleted_at` pasa de `null` a no-`null` cascada en la misma transacción del `UPDATE` que ya hace hoy el cliente al empujar el borrado de la fuente (vía `_syncSources` en `sync_user_data.dart`, sin cambios de código necesarios ahí). No se eligió una Edge Function porque el cliente ya hace un `UPDATE`/`upsert` directo a `sources` vía PostgREST — agregar un endpoint nuevo solo para esto sería una ruta adicional a mantener sin necesidad, cuando un trigger cubre el mismo caso de forma transparente y también protege contra cualquier futuro camino de código (o bug) que marque una fuente como borrada sin pasar por `DeleteSource`.

**El trigger corre con los privilegios del usuario autenticado, sin `SECURITY DEFINER`.** El `UPDATE` que dispara el trigger ya pasó la policy `sources_update_own` (mismo `user_id`); el `UPDATE` que el trigger ejecuta sobre `articles` sigue siendo sobre filas del mismo `user_id`, así que la policy `articles_update_own` (`user_id = auth.uid()`) lo permite sin necesitar privilegios elevados. Se evita así ampliar la superficie de qué puede hacer un trigger más allá de lo que el usuario ya podía hacer explícitamente.

**El trigger respeta `is_favorite = false` (o null) como condición del `WHERE`,** igual que el criterio `keepFavorites: true` del cliente — no se toca ningún artículo favorito, sin importar de qué fuente sea.

**Backfill como parte de la misma migration, con un `UPDATE` de una sola vez, no un job separado.** El volumen de artículos huérfanos en producción es acotado (fuentes ya borradas por usuarios existentes); un `UPDATE ... WHERE source_id IN (SELECT id FROM sources WHERE deleted_at IS NOT NULL) AND deleted_at IS NULL AND is_favorite = false` corre una sola vez al aplicar la migration y no necesita infraestructura de job separada.

**`updatePartial` pasa a un único `UPDATE ... WHERE id IN (...)` cuando el payload es idéntico entre filas** (que es el caso de un borrado de fuente: todas las filas de artículos comparten el mismo `deleted_at`). Para el caso general donde los payloads difieren entre filas (ej. distintos `is_read`/`updated_at` por artículo en una sync normal), se evalúa agrupar por payload idéntico y hacer un `UPDATE ... WHERE id IN (...)` por grupo en vez de mantener un `UPDATE` por fila — reduce la cantidad de round-trips y por lo tanto la ventana de fallo parcial, aunque no la elimina completamente para el caso de payloads heterogéneos. Esta mejora es complementaria al trigger, no un sustituto: el trigger sigue siendo la única garantía que no depende de que el cliente complete ningún push.

## Risks / Trade-offs

- **[Riesgo] El backfill de una sola vez podría tocar más o menos filas de las esperadas** si hay fuentes borradas de otros usuarios con datos inconsistentes → Mitigación: el `WHERE` filtra explícitamente por `source_id` de fuentes ya borradas y excluye favoritos; se revisa el conteo de filas afectadas antes/después de aplicar la migration en producción.
- **[Riesgo] Un trigger es una fuente de comportamiento "invisible" en el código de la app** (alguien que lea solo el cliente Dart no ve la cascada) → Mitigación: se documenta con un comentario claro en la migration SQL, siguiendo la convención ya usada en este repo de explicar el "por qué" en comentarios de migration.
- **[Trade-off] El trigger no ayuda si el push del borrado de la fuente en sí mismo nunca llega a Supabase** (ej. el usuario borra la fuente y desinstala la app antes de cualquier sync) → Aceptado: es un caso mucho más acotado que "N artículos" (una sola fila), y no es peor que el comportamiento actual para la fuente misma; sigue fuera de alcance de este change.

## Migration Plan

1. Migration de Postgres: función + trigger de cascada sobre `sources`, más el `UPDATE` de backfill de una sola vez.
2. Cambio de cliente (`updatePartial` a batch) — no requiere coordinación de deploy con la migration; son independientes.
3. Rollback: `DROP TRIGGER`/`DROP FUNCTION` revierte la cascada a futuro sin afectar los artículos ya marcados como borrados por el backfill (soft-delete no se deshace solo, que es el comportamiento esperado). El cambio de `updatePartial` se revierte con un revert de código normal.
