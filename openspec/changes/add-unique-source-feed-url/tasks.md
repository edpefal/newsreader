## 1. Cliente: clasificar el conflicto de unicidad

- [x] 1.1 En `SupabaseCloudSyncClient._throwClassified` (`lib/core/sync/supabase_cloud_sync_client.dart`), mapear una `PostgrestException` con código `23505` a `CloudSyncException(AppErrorCode.duplicateSource)`; no agregar ningún `AppErrorCode` ni clave de i18n nueva.
- [x] 1.2 Test unitario de la clasificación: `23505` produce `duplicateSource`; un `504`, un `SocketException` y otro código de Postgrest siguen clasificándose como antes (no se rompe ningún mapeo existente).

## 2. Cliente: reconciliar el conflicto en `SyncUserData`

- [x] 2.1 En `_syncSources` (`lib/features/sync/domain/usecases/sync_user_data.dart`), ordenar las filas a subir para que las que tienen `deleted_at` vayan antes que las activas.
- [x] 2.2 Si el `upsert` del lote lanza `CloudSyncException` con `duplicateSource`, reintentar fuente por fuente para identificar las conflictivas; las demás se suben normalmente. Cualquier otra excepción se propaga igual que hoy.
- [x] 2.3 Reconciliar cada fuente conflictiva: `purge` de la fuente local, `deleteArticlesBySource(id, keepFavorites: false)` de sus artículos locales, y bajada completa de `sources` (`fetchChangedSince(_sourcesTable, null)`) aplicada con `applyRemote`; continuar con artículos, resúmenes, uso de IA y preferencias en el mismo ciclo.
- [x] 2.4 Tests unitarios (mocktail) en `test/unit/features/sync/domain/usecases/`: orden de subida (borradas antes que activas, incluido borrar y re-agregar el mismo feed); conflicto en una fuente de un lote con otras sin conflicto (las demás se suben, la conflictiva se purga junto con sus artículos locales y se adopta la remota); otro error de subida no se trata como conflicto; tras la reconciliación el ciclo llega a sincronizar artículos y preferencias.

## 3. Cliente: verificación previa contra la nube al agregar

- [x] 3.1 Crear en `lib/core/sync/` la abstracción `RemoteSourceChecker` (`Future<bool> existsActive(String feedUrl)`) y su implementación `SupabaseRemoteSourceChecker`: consulta `sources` por `feed_url` con `deleted_at is null` (limit 1, con un timeout propio de 5 s, más corto que el de sincronización porque bloquea el botón de agregar) y devuelve `false` ante cualquier error o sin sesión. Registrarla en `lib/core/di/injection.dart` (único punto de `get_it`).
- [x] 3.2 Inyectar `RemoteSourceChecker` en `AddSource` por constructor y consultarlo tras la verificación local y antes de crear la fuente; si devuelve `true`, lanzar `DuplicateSourceException`. Actualizar el registro de `AddSource` en `injection.dart`.
- [x] 3.3 Tests unitarios de `AddSource` (mocktail): duplicado solo en la nube lanza `DuplicateSourceException`; el checker devolviendo `false` agrega la fuente; un checker que falla/devuelve `false` por error no impide agregar; el duplicado local sigue ganando sin consultar la nube; la fuente borrada solo en la nube no cuenta como duplicado.
- [x] 3.4 Actualizar los tests existentes de `AddSource` y de los Cubits que construyan `AddSource` para la nueva dependencia, sin cambiar sus aserciones.

## 4. Servidor: migración de deduplicación e índice único

- [x] 4.1 Crear `supabase/migrations/20261005000000_unique_source_feed_url.sql` con, en este orden y en una sola transacción: (a) deduplicación de artículos repetidos entre la fuente conservada (la de menor `added_at`, desempate por `id`) y las sobrantes, fusionando `is_read`/`is_favorite`/`is_archived` (OR), `read_at` y `saved_as_favorite_at` (el más temprano no nulo) y `updated_at = now()`, y marcando como borrado el artículo de la sobrante; (b) traslado de los artículos de la sobrante sin equivalente por `article_url` (cualquier fila, incluso borrada) a la conservada, actualizando `source_id`, `source_name`, `source_icon_url` y `updated_at`; (c) baja de la fuente sobrante (`deleted_at`, `updated_at = now()`); (d) `create unique index sources_user_id_feed_url_active_key on sources (user_id, feed_url) where deleted_at is null`.
- [x] 4.2 Verificar la migración en `reevo-dev` dentro de `begin ... rollback` con fixtures: grupo duplicado con estados de lectura distintos (se fusionan), artículo solo en la sobrante (se traslada), artículo favorito en la sobrante (no se pierde), un usuario sin duplicados (sin cambios) y dos usuarios con el mismo feed (sin conflicto entre ellos); y comprobar que tras el índice un segundo `insert` activo del mismo `(user_id, feed_url)` falla con `23505`, pero uno con la fuente anterior borrada sí funciona. (Verificado en `reevo-dev` el 2026-10-05 con un script `DO` que inserta fixtures, ejecuta la migración y termina con una excepción para revertir todo; dev quedó sin cambios. Matices: el SQL ejecutado omitió los comentarios del archivo, con la misma lógica; y la idempotencia de una segunda corrida no se probó en esa ejecución, aunque `create unique index if not exists` y un `loop` sin duplicados no hacen nada. Resultados: la más antigua queda activa y la otra borrada; el artículo repetido se fusiona leído+favorito con la fecha de lectura más temprana y el de la sobrante se da de baja; el artículo solo de la sobrante se mueve con favorito/archivado/leído intactos y el nombre de la conservada; el otro usuario y la fuente sin duplicado no cambian; con el índice, un segundo insert activo falla con `23505` y volver a agregar tras borrar funciona.)
- [x] 4.3 Documentar en el cuerpo del PR el procedimiento de aplicación y de rollback (`drop index`), y la consulta de captura previa de las filas afectadas.

## 5. Verificación

- [x] 5.1 Correr `flutter analyze` y dejarlo sin warnings.
- [x] 5.2 Correr `flutter test` completo en verde.
- [x] 5.3 Razonar (sin lanzar el simulador, ver CLAUDE.md) que no se toca ninguna pantalla ni el árbol de widgets, por lo que el layout adaptativo de iPad (rail, master-detail, selección persistente) no cambia; dejarlo anotado al cerrar el change.
- [x] 5.4 Confirmar que no se agregó ningún texto visible al usuario y que no hay cambios en los `.arb`.

## 6. Despliegue y cierre

- [ ] 6.1 Abrir PR contra `main`, esperar el check `analyze-and-test` en verde, mergear y confirmar que Codemagic publicó el build con el cliente nuevo. **No aplicar la migración antes de este paso** (ver design, Decisión 5).
- [ ] 6.2 Confirmar con el usuario a cuál(es) proyecto(s) de Supabase aplicar la migración (`reevo` prod / `reevo-dev` / ambos) y verificar la adopción del build nuevo; no asumir que solo uno basta.
- [ ] 6.3 Guardar la captura previa de las filas afectadas (fuentes y artículos de los ids duplicados de prod), aplicar primero en dev y, tras verificar, en prod.
- [ ] 6.4 Verificar en el/los proyecto(s) elegido(s): ninguna combinación `(user_id, feed_url)` activa repetida, el índice existe, y el Inbox del usuario afectado en prod ya no muestra artículos de Error500 duplicados.
- [ ] 6.5 Archivar el change (`/opsx:archive`) una vez verificado el despliegue, en un PR aparte si la verificación en producción lo requiere, y luego volver a `main`, actualizarla y borrar las ramas mergeadas.
