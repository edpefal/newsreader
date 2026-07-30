## Context

Hoy `NewsSourceModel` (typeId 0), `ArticleModel` (typeId 1) y `DailySummaryModel` (typeId 2) viven exclusivamente en Hive, sin ningún campo de auditoría (`updatedAt`) ni de borrado lógico. Los repositorios (`SourceRepositoryImpl`, `ArticleRepositoryImpl`, `SummaryRepositoryImpl`) son wrappers finos 1:1 sobre sus datasources Hive — sin ninguna lógica de red.

`SyncSources` (existente) es un nombre ya usado para algo completamente distinto: fetch de feeds RSS/Atom. El nuevo use case de este change se llama `SyncUserData` para no confundirse, y ambos van a correr en secuencia al arrancar la app.

Desde `add-auth-foundation`, el proyecto ya tiene `supabase_flutter` como dependencia (justificado ahí por la complejidad de manejar sesiones/tokens a mano) y ya hay una sesión de usuario real (`auth.uid()`) disponible en cualquier punto de la app vía `AuthClient`.

## Goals / Non-Goals

**Goals:**
- Sincronización bidireccional (push de cambios locales + pull de cambios remotos) de `sources`, `articles` y `daily_summaries`, disparada al abrir la app — sin tiempo real.
- Detección de cambios locales vía `updatedAt`, estampado a nivel de datasource, sin tocar ningún use case existente.
- Soft-delete (`deletedAt`) para que los borrados se propaguen correctamente entre dispositivos.
- Primer login con datos locales preexistentes: se suben como estado inicial, sin pasos especiales adicionales (ver Decisión 4).
- RLS por `user_id = auth.uid()` en las tablas nuevas.

**Non-Goals:**
- No hay sincronización en tiempo real (Supabase Realtime) — queda fuera de alcance, se puede evaluar en un change futuro si se vuelve necesario.
- No se resuelven conflictos más allá de last-write-wins — no se implementa ningún merge tipo CRDT.
- No se sincroniza contenido de fuentes en sí (eso lo sigue haciendo `SyncSources` contra los feeds RSS) — este change sincroniza el *estado del usuario* sobre esos artículos (leído/favorito/archivado) y la lista de fuentes/resúmenes.
- No se migra el paywall/cuota de resúmenes (change futuro separado, consume `user_id` pero no esta sincronización).

## Decisions

### Nuevos campos en modelos Hive: `updatedAt` en los 3, `deletedAt` en Source y Article
- `NewsSourceModel`: `@HiveField(8) DateTime updatedAt`, `@HiveField(9) DateTime? deletedAt`.
- `ArticleModel`: `@HiveField(15) DateTime updatedAt`, `@HiveField(16) DateTime? deletedAt`.
- `DailySummaryModel`: `@HiveField(5) DateTime updatedAt` (sin `deletedAt`: no existe ningún flujo que borre un resumen individual, solo se sobrescribe por fecha).

Los mismos campos se agregan a las entidades de dominio correspondientes (`NewsSource`, `Article`, `DailySummary`), siguiendo el patrón ya existente en el proyecto de exponer timestamps de auditoría a nivel de entidad (`readAt`, `savedAsFavoriteAt`, `lastSyncedAt` ya viven ahí, no solo en los modelos).

Requiere `dart run build_runner build --delete-conflicting-outputs` para regenerar los TypeAdapters, y agregar los `HiveField` nuevos sin reordenar ni reusar los índices existentes (regla de Hive: los índices ya asignados no se tocan).

### `updatedAt` se estampa en el datasource local, no en cada use case
Cada método de escritura de `HiveArticleDatasource`, `HiveSourceDatasource` y `HiveSummaryDatasource` (`saveArticle`, `updateArticle`, `saveSource`, `updateSource`, etc.) setea `updatedAt = DateTime.now()` antes de persistir, sin importar qué use case lo llamó. Esto evita tocar `MarkArticleAsRead`, `ToggleFavorite`, `AddSource`, etc. — quedan exactamente igual que hoy.

**Alternativa considerada**: que cada use case sea responsable de setear `updatedAt` explícitamente. Se descarta: es fácil de olvidar en un use case nuevo futuro, y el datasource es el único lugar que ve *todas* las escrituras sin excepción.

### `SyncUserData`: flujo de una sola pasada, push-then-pull
1. Lee el cursor `lastSyncedAt` (guardado en el mismo Hive box de settings que ya usa `ThemeCubit`; `null` si es la primera vez que este dispositivo sincroniza para este usuario).
2. **Push**: para cada tabla, busca localmente los registros con `updatedAt > lastSyncedAt` (o *todos* si `lastSyncedAt` es `null`) y hace `upsert` a la tabla de Postgres correspondiente, vía el cliente de `supabase_flutter` (que ya adjunta el JWT del usuario automáticamente — las policies de RLS hacen el resto).
3. **Pull**: busca en Postgres los registros de ese usuario con `updated_at > lastSyncedAt` (mismo `null` = todo) que no se acaban de subir en el paso anterior, y hace upsert local. Si un registro remoto trae `deletedAt` seteado, se borra físicamente el registro local (el tombstone ya cumplió su función en el otro dispositivo).
4. Actualiza el cursor `lastSyncedAt` al timestamp de inicio de esta sincronización.

**Primer login con datos locales preexistentes**: no requiere ningún caso especial — al ser la primera sincronización de ese dispositivo, `lastSyncedAt` es `null`, así que el paso de Push sube *todos* los registros locales existentes tal cual, sin necesitar lógica adicional.

### Cliente Postgres: `supabase_flutter` directo, detrás de una nueva abstracción `CloudSyncClient`
Se usa el cliente de Postgres de `supabase_flutter` (`Supabase.instance.client.from('sources')...`) en vez de HTTP plano vía `HttpClient` — a diferencia de las edge functions (donde el contrato es un endpoint HTTP simple), acá se necesita `upsert`, filtros por `updated_at`, y que el JWT de sesión viaje automático para que RLS funcione; reimplementar eso a mano contra la REST API de PostgREST sería reinventar lo que el SDK ya da gratis. Se abstrae detrás de `core/sync/CloudSyncClient` para que `SyncUserData` no importe `supabase_flutter` directamente, siguiendo el mismo principio ya aplicado a `AuthClient`.

### Esquema de Postgres
Tres tablas nuevas, cada una con `user_id uuid references auth.users(id)` y RLS `user_id = auth.uid()` para `select`/`insert`/`update` (sin `delete` real vía policy, ya que el borrado es lógico vía `deleted_at`):
- `sources`: espejo de `NewsSourceModel` + `user_id`.
- `articles`: espejo de `ArticleModel` + `user_id`. `content_html` puede ser pesado (ver change `daily-summary-full-content`) — se acepta el mismo trade-off ya aceptado ahí (sin límite de tamaño).
- `daily_summaries`: espejo de `DailySummaryModel` + `user_id`.

**Alternativa considerada**: una tabla genérica tipo `key-value`/JSON blob por usuario en vez de 3 tablas relacionales. Se descarta: pierde la capacidad de hacer `upsert`/filtros por `updated_at` de forma eficiente y tipada, y no aprovecha RLS por fila.

## Risks / Trade-offs

- **[Riesgo] `content_html` completo en `articles` puede hacer pesado el pull inicial si hay muchos artículos con contenido completo** → Mitigación: ninguna automática por ahora (mismo criterio que `daily-summary-full-content`); si se vuelve un problema real medido, es un change futuro acotado.
- **[Riesgo] Reloj del dispositivo desincronizado puede generar comparaciones de `updatedAt` incorrectas** (ej. un teléfono con la fecha mal configurada podría "perder" cambios recientes o sobreescribir cambios más nuevos) → Mitigación: se acepta como riesgo conocido, de bajo impacto real (afecta a muy pocos dispositivos, y el peor caso es perder un toggle de favorito, no datos críticos). Se puede migrar a timestamps del servidor (`now()` de Postgres al momento del upsert) en una iteración futura si se detecta que es un problema real.
- **[Riesgo] Conflicto en `ToggleFavorite` con last-write-wins puede "perder" un toggle si dos dispositivos lo tocan offline casi al mismo tiempo** → Aceptado explícitamente (ver proposal): bajo impacto, no justifica la complejidad de un merge especial.
- **[Trade-off] `supabase_flutter` para Postgres además de para Auth** → Refuerza la dependencia ya aceptada en `add-auth-foundation`; se acepta porque el caso de uso (upsert + filtros + RLS automático) es exactamente lo que el SDK resuelve bien.

## Migration Plan

1. Migración de Hive: agregar los campos nuevos a los 3 modelos, regenerar TypeAdapters, verificar que abrir una base Hive existente (de una versión anterior sin estos campos) no rompe — Hive CE maneja campos nuevos como opcionales/nullable por defecto si se agregan al final, así que instalaciones existentes cargan con `updatedAt` faltante inicialmente y hay que decidir un valor por defecto sensato (`DateTime.now()` al leer, para que el primer sync los trate como "recién cambiados" y los suba).
2. Migración de Postgres: nueva migración SQL con las 3 tablas + RLS policies + índices por `(user_id, updated_at)`.
3. Deploy del código cliente (`SyncUserData`, `CloudSyncClient`, cambios en datasources).
4. Verificación manual: login en dos dispositivos con la misma cuenta, marcar un artículo como leído en uno, confirmar que aparece leído en el otro tras abrir/refrescar la app.

Sin plan de rollback de datos complejo: si hay que revertir, el peor caso es que los datos sincronizados en Postgres queden huérfanos (sin código que los lea), pero Hive local sigue siendo la fuente de verdad para la app tal como funciona hoy sin este change.

## Open Questions

- ¿El `lastSyncedAt` cursor es único por usuario+dispositivo, o se podría simplificar a uno solo por instalación de la app (asumiendo que un dispositivo físico rara vez tiene más de una cuenta logueada a la vez)? Se asume lo segundo para la primera versión (un cursor por dispositivo, no por combinación usuario-dispositivo), pero vale revisarlo si en el futuro se permite cambiar de cuenta sin reinstalar.
