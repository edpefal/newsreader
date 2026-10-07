## Context

Ver `proposal.md` (Why) para el síntoma. Estado actual relevante:

- **Solo el cliente crea filas en `sources`**, vía el `upsert` por `id` de `SyncUserData._syncSources`. `create-feed` inserta en otra tabla (feeds de email) y `sync-feeds` solo lee y actualiza `sources`.
- **La verificación de duplicado es local**: `AddSource.execute` llama a `SourceRepository.sourceExists`, que revisa la caja Hive (`_live.any(feedUrl == ...)`, excluye borradas).
- **`sources` solo tiene la PK y un índice `(user_id, updated_at)`.** `articles` ya tiene `unique(source_id, article_url)`.
- **`SyncUserData` sincroniza `sources` primero** y escribe el cursor solo si todo el ciclo termina: un error en `sources` aborta el ciclo completo y se repite idéntico en el siguiente.
- Existe el trigger `sources_cascade_delete_articles` (AFTER UPDATE): al marcar una fuente como borrada marca como borrados sus artículos, **excepto los favoritos**.
- El cliente interpreta los errores de Postgrest en `_throwClassified` (`supabase_cloud_sync_client.dart`), que ya mapea timeouts de gateway y errores de red a `AppErrorCode`.
- Datos hoy: prod tiene 1 grupo duplicado (2 fuentes de un mismo usuario, agregadas el 20 de julio y el 6 de agosto; 3 y 1 artículos leídos, ninguno favorito ni archivado); dev no tiene duplicados.

## Goals / Non-Goals

**Goals:**
- Imposibilitar duplicados activos por `(user_id, feed_url)` en el servidor, sin depender del cliente.
- Que un conflicto de unicidad nunca deje atascada la sincronización de un usuario.
- Evitar el duplicado en el caso más común (otro dispositivo, sesión nueva) con el mismo mensaje que ya existe.
- Conservar el trabajo del usuario (leído/favorito/archivado) al deduplicar los datos existentes.

**Non-Goals:**
- Normalizar `feed_url` (barra final, mayúsculas, `http` vs `https`): se compara por igualdad exacta, igual que hoy; dos URLs distintas del mismo sitio siguen contando como fuentes distintas.
- Agrupar el resumen diario por `source_id` en vez de por nombre (change aparte).
- Cambiar pantallas, textos o claves de i18n.

## Decisions

**1. Índice único parcial, no `unique` completo ni trigger.**
`create unique index sources_user_id_feed_url_active_key on sources (user_id, feed_url) where deleted_at is null`. La condición parcial deja fuera las borradas, así que eliminar y volver a agregar un feed sigue funcionando y coincide con `sourceExists` (que ignora las borradas). Un `unique (user_id, feed_url)` completo bloquearía volver a agregar un feed eliminado, porque el soft-delete conserva la fila.
- *Alternativa descartada — trigger `BEFORE INSERT` que ignore el duplicado en silencio:* el cliente creería que subió su fila, conservaría su `id` local huérfano para siempre y nunca recibiría artículos para él (el servidor solo fetchea la fuente original). Un error explícito es más seguro que un éxito falso.
- *Alternativa descartada — `on conflict (user_id, feed_url)` en el upsert del cliente:* PostgREST solo arbitra una restricción por `onConflict`, y la actual es la PK `id`; habría que cambiar el contrato del sync para todas las tablas.

**2. La migración deduplica antes de crear el índice, en una sola transacción, conservando la fuente más antigua.**
Dentro de la misma migración, en este orden:
1. Calcular por `(user_id, feed_url)` entre las activas la que se conserva (`order by added_at, id`) y las sobrantes.
2. Para cada artículo de una sobrante con la misma `article_url` que uno de la conservada (cualquiera, incluso borrado, por la restricción `unique (source_id, article_url)`): si el de la conservada no está borrado, fusionar en él el estado (`is_read` / `is_favorite` / `is_archived` con OR; `read_at` y `saved_as_favorite_at` el más temprano no nulo; `updated_at = now()`), y marcar el de la sobrante como borrado.
3. Para los artículos de la sobrante sin equivalente en la conservada: mover (`source_id`, `source_name`, `source_icon_url` de la conservada, `updated_at = now()`), con todo su estado intacto.
4. Marcar la sobrante como borrada (`deleted_at`, `updated_at = now()`); el trigger de cascada ya no encuentra artículos activos que arrastrar, así que no hay que reimplementar nada, y los favoritos que el trigger no tocaría ya fueron movidos o fusionados en los pasos 2-3.
5. Crear el índice.

Todo `updated_at` se actualiza con `now()` para que cualquier dispositivo, con su cursor actual, descargue el cambio y purgue o actualice lo suyo. Se elige conservar la más antigua por ser la que probablemente tenga más historial de lectura; en los datos de prod, la de julio.
- *Alternativa descartada — borrar físicamente los duplicados:* el borrado físico no se propaga a los dispositivos (nadie recibe un tombstone), y los dejaría con la fuente huérfana.
- *Alternativa descartada — no deduplicar y crear el índice como `NOT VALID`:* PostgreSQL no admite índices únicos parciales `NOT VALID`; fallaría o no protegería nada.

**3. El cliente reconcilia el `23505` en `_syncSources` y no pierde el resto del ciclo.**
`_throwClassified` mapea una `PostgrestException` con código `23505` sobre `sources` a `AppErrorCode.duplicateSource` (ya existe, con su mensaje en los 3 idiomas; no se agrega ningún `AppErrorCode` nuevo, ver CLAUDE.md). En `_syncSources`:
1. **Orden de subida:** las filas con `deleted_at` primero, luego las activas. Esto evita el falso conflicto de "borré el feed y lo volví a agregar antes de sincronizar": con el lote en orden inverso el `INSERT` nuevo chocaría con la fila vieja que aún figura activa en el servidor.
2. **Reintento aislado:** si el `upsert` del lote lanza `duplicateSource`, se reintenta fuente por fuente para identificar cuáles chocan; las demás se suben normalmente.
3. **Reconciliación de cada fuente conflictiva:** se eliminan del dispositivo la fuente local y sus artículos (`purge` y `deleteArticlesBySource(keepFavorites: false)`; una fuente recién creada que nunca llegó al servidor no tiene artículos legítimos), y se hace una bajada completa de `sources` (`fetchChangedSince(..., null)`, son pocas filas) aplicándola con `applyRemote` para garantizar que la fuente remota existente quede en el dispositivo aunque su `updated_at` esté por debajo del cursor.
4. El ciclo continúa con artículos, resúmenes, uso de IA y preferencias.
- *Alternativa descartada — dejar que el error aborte el ciclo:* es el estado actual de cualquier error; con el índice, un duplicado creado localmente haría fallar la sincronización completa en cada ciclo indefinidamente.
- *Alternativa descartada — reasignar los artículos locales de la duplicada a la remota:* la duplicada nunca llegó al servidor, así que no tiene artículos que valga la pena conservar; reasignar exige mapear estado por URL sin aportar nada real.

**4. Verificación previa contra la nube al agregar (best-effort).**
Una abstracción nueva en `core/sync/`, `RemoteSourceChecker` (`Future<bool> existsActive(String feedUrl)`), con la implementación `SupabaseRemoteSourceChecker` que consulta `sources` por `feed_url` y `deleted_at is null` (RLS limita al usuario) y devuelve `false` ante cualquier error o sin sesión; se registra en `core/di/injection.dart`. `AddSource` la recibe por constructor y, tras la verificación local, la invoca antes de crear la fuente; si devuelve `true` lanza el mismo `DuplicateSourceException`. Es una mejora de experiencia, no una garantía: la garantía es el índice y la reconciliación.
- *Alternativa descartada — ampliar `CloudSyncClient` con una consulta genérica por columna:* ensancha una abstracción pensada para sincronización por `updated_at` para un uso puntual de un solo feature.

**5. Orden de despliegue: primero el cliente, después la migración.**
Un cliente anterior a este change que agregue un feed duplicado y suba su fila **después** de aplicada la migración recibe `23505`, no sabe reconciliar y deja su sincronización fallando en cada ciclo mientras la fuente duplicada local exista. Por eso: (1) mergear y publicar el cliente nuevo; (2) esperar a que los usuarios activos lo tengan (hoy son pocos, ver adopción de versión); (3) aplicar la migración en dev y después en prod. El escenario que dispara el conflicto es poco frecuente (1 caso en prod hasta hoy), lo que acota el riesgo residual con builds viejos.

## Risks / Trade-offs

- [Un cliente viejo choca con el índice] → Orden de despliegue de la Decisión 5; riesgo residual acotado a quien agregue el mismo feed desde un build viejo después de la migración. Rollback inmediato: `drop index sources_user_id_feed_url_active_key`.
- [La deduplicación mueve o borra datos de un usuario real en prod] → Antes de aplicar, guardar el resultado de una consulta con las filas afectadas (fuentes y artículos de los dos ids de prod); probar la migración primero en dev con fixtures dentro de una transacción con `rollback`; la baja es lógica (`deleted_at`), no física.
- [`feed_url` con variantes (barra final, `http`/`https`) sigue permitiendo duplicados "lógicos"] → Fuera de alcance; se documenta como límite conocido y se puede abordar con normalización en un change posterior.
- [La pantalla de detalle de una fuente recién agregada puede quedar apuntando a una fuente local que la reconciliación purga] → Se mitiga con la verificación previa de la Decisión 4, que evita crear el duplicado en el caso común; el caso restante (sin red al agregar) deja la pantalla sin contenido hasta que el usuario sale, sin error.
- [Una fuente remota por debajo del cursor no baja sola] → La reconciliación hace una bajada completa de `sources` (Decisión 3, paso 3).

## Migration Plan

1. Implementar y probar cliente (Flutter) y migración (SQL) en la rama; `flutter analyze` y `flutter test` en verde.
2. Probar la migración en `reevo-dev` con fixtures dentro de `begin ... rollback`: grupo duplicado con estados de lectura distintos, artículo solo en la sobrante, artículo favorito en la sobrante, y un usuario sin duplicados.
3. Mergear el cliente y publicar el build (Codemagic). **No** aplicar la migración todavía.
4. Confirmar con el usuario a cuál(es) proyecto(s) (`reevo` prod / `reevo-dev` / ambos) se aplica la migración; aplicarla primero en dev y, tras verificar, en prod.
5. Verificar: ningún grupo `(user_id, feed_url)` activo repetido y el Inbox del usuario afectado sin artículos duplicados de Error500.
6. Rollback: `drop index` (no restaura los datos fusionados, que son una limpieza deliberada; los ids y estados originales quedan en la captura previa).
