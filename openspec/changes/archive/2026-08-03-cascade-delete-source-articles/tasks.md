## 1. Base de datos

- [x] 1.1 Crear migration en `supabase/migrations` con una función + trigger `AFTER UPDATE` sobre `sources`: cuando `deleted_at` pasa de `null` a no-`null`, marca `deleted_at`/`updated_at` en todos los artículos (`articles.source_id = sources.id`, mismo `user_id`) que no sean favoritos (`is_favorite = false`).
- [x] 1.2 En la misma migration, agregar el `UPDATE` de backfill de una sola vez: marcar `deleted_at`/`updated_at` en los artículos huérfanos existentes (de fuentes con `deleted_at IS NOT NULL`, artículo con `deleted_at IS NULL`, `is_favorite = false`).
- [x] 1.3 Verificar manualmente en un entorno de prueba (o con una query de conteo antes/después) que el trigger no toca artículos favoritos ni artículos de fuentes de otros usuarios. — Verificado en producción: 2 fuentes borradas (Hacker News: Front Page, xkcd.com), 24 artículos totales entre ambas, 0 favoritos entre ellos, y tras el backfill 0 quedan con `deleted_at is null` (todos correctamente marcados como borrados).

## 2. Cliente — `updatePartial` en batch

- [x] 2.1 En `lib/core/sync/supabase_cloud_sync_client.dart`, cambiar `updatePartial` para agrupar las filas por payload idéntico (excluyendo `id`) y ejecutar un `UPDATE ... WHERE id IN (...)` por grupo en vez de un `UPDATE` por fila.
- [x] 2.2 Actualizar/agregar tests unitarios de `SupabaseCloudSyncClient`/`SyncUserData` que cubran: múltiples artículos con el mismo payload de borrado (un solo request agrupado) y payloads heterogéneos (se agrupan correctamente sin mezclar datos entre artículos). — La lógica de agrupamiento se extrajo a `groupRowsByPayload` (función pura) porque no hay precedente en el repo de mockear la cadena fluida de `postgrest`/`supabase_flutter`; se testea directamente sin tocar la red.

## 3. Verificación

- [x] 3.1 `flutter analyze` sin warnings nuevos.
- [x] 3.2 `flutter test` (unit) incluyendo los casos nuevos de `updatePartial`.
- [x] 3.3 Aplicar la migration a producción (`supabase db push`) y confirmar con una query que los artículos huérfanos de Hacker News (y cualquier otra fuente ya borrada) quedaron con `deleted_at` seteado, salvo los favoritos. — Migration `20260801010000` aplicada; confirmado con la API REST (service role) que los 24 artículos de las 2 fuentes borradas quedaron con `deleted_at` seteado.
- [x] 3.4 Probar manualmente: borrar una fuente con varios artículos (algunos favoritos) desde la app, hacer pull-to-refresh en otro dispositivo/sesión, y confirmar que los no favoritos desaparecen y los favoritos permanecen. — Confirmado por el usuario: funcionó.
