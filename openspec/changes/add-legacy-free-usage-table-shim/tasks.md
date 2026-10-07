## 1. Migración

- [x] 1.1 Crear `supabase/migrations/20261006000000_legacy_free_usage_table_shim.sql` que recree `daily_summary_free_usage` con el esquema original (`user_id uuid primary key references auth.users (id) on delete cascade`, `week_start date not null default date_trunc('week', current_date)::date`, `used boolean not null default false`, `updated_at timestamptz not null default now()`), con `enable row level security` y la política `daily_summary_free_usage_select_own` (`for select using (user_id = auth.uid())`), sin políticas de escritura, y con `revoke insert, update, delete` sobre la tabla a `anon` y `authenticated`. No recrear las funciones `check_and_record_daily_summary_free_usage()` ni `get_daily_summary_free_usage_status()`, y no insertar filas.
- [x] 1.2 Abrir la migración con un comentario que diga que es una excepción temporal para clientes `1.8.x`, por qué existe (la tabla se retiró antes de que la `1.9.0` estuviera pública), que la tabla está vacía a propósito, y el criterio de retiro (ver tarea 7.1) con el rollback (`drop table daily_summary_free_usage`).

## 2. Verificación en dev (sin dejar cambios)

- [x] 2.1 Verificar el SQL exacto de la migración en `reevo-dev` con un bloque `DO` que termine siempre con una excepción para revertir todo: tras ejecutarlo, comprobar que la tabla existe, que RLS está activo y que existe la política de lectura.
- [x] 2.2 En el mismo bloque, simular a un usuario autenticado (`set local role authenticated` con `request.jwt.claim.sub` de un usuario real de dev) y comprobar que una consulta equivalente a la del cliente `1.8.x` (filtro `updated_at >` un cursor, `order by updated_at`, límite de página) devuelve cero filas sin error; y que `insert`, `update` y `delete` fallan. (Verificado en `reevo-dev` el 2026-10-06 con un `DO` que revierte siempre. Con el rol `authenticated` y un `sub` de un usuario real: la consulta equivalente a la del cliente devolvió 0 filas sin error; `insert`, `update` y `delete` fallaron con `42501`. Estructura: tabla existe, RLS activo, política `daily_summary_free_usage_select_own:SELECT`, columnas `user_id uuid, week_start date, used boolean, updated_at timestamptz`, 0 filas; `authenticated` solo tiene `select` y `anon` no puede insertar. Matiz: el SQL ejecutado omitió los comentarios del archivo, con las mismas sentencias.)
- [x] 2.3 Confirmar después, con una consulta aparte, que dev quedó sin la tabla (la verificación no dejó nada).

## 3. Cliente actual

- [x] 3.1 Añadir en `test/unit/features/sync/domain/usecases/sync_user_data_test.dart` un test que fije que `SyncUserData.execute()` no consulta `daily_summary_free_usage` (`fetchChangedSince` no se invoca con ese nombre de tabla), para que nadie la reintroduzca sin ver que depende de esta compatibilidad.

## 4. Verificación general

- [x] 4.1 Correr `flutter analyze` y dejarlo sin warnings.
- [x] 4.2 Correr `flutter test` completo en verde.
- [x] 4.3 Razonar (sin lanzar el simulador, ver CLAUDE.md) que no se toca ninguna pantalla, por lo que el layout adaptativo de iPad no cambia; dejarlo anotado al cerrar el change. (Este change solo añade una migración y un test: no toca `lib/`, ninguna pantalla ni el árbol de widgets, por lo que rail, master-detail y selección persistente de iPad no cambian.)
- [x] 4.4 Confirmar que no se agregó texto visible ni cambios en los `.arb`. (Sin cambios en `lib/` ni en los `.arb`.)

## 5. Despliegue en prod

- [x] 5.1 Confirmar con el usuario a cuál(es) proyecto(s) de Supabase aplicar la migración (propuesto: solo `reevo` prod, porque dev no tiene instalaciones `1.8.x`); no asumir. (Confirmado por el usuario: solo `reevo` prod.)
- [x] 5.2 Aplicar la migración en el/los proyecto(s) confirmado(s) con `apply_migration` (no `supabase db push`, por el desajuste de versiones de las migraciones del 16 de septiembre). (Aplicada en prod el 2026-10-06 con `apply_migration`, nombre `legacy_free_usage_table_shim`. Dev no se toca.)
- [x] 5.3 Verificar en el/los proyecto(s): la tabla existe, RLS activo con la política de lectura, 0 filas, y una consulta como la del cliente `1.8.x` (filtro y orden por `updated_at`) devuelve vacío sin error. (Verificado en prod: tabla existente, RLS activo, política `daily_summary_free_usage_select_own:SELECT`, 0 filas; `authenticated` solo con `select`, `anon` sin `insert`. Simulando al usuario afectado con el rol `authenticated`, la consulta del cliente devolvió 0 filas sin error e `insert` falló con `42501`. Se recargó la caché de PostgREST (`notify pgrst, 'reload schema'`) y la API REST responde HTTP 200 con `[]` para la misma consulta (filtro y orden por `updated_at`), mientras que una tabla inexistente de control devuelve `PGRST205`.)
- [ ] 5.4 Abrir PR contra `main` con el archivo de migración (ya aplicado), esperar el check `analyze-and-test` en verde y mergear; volver a `main`, actualizarla y borrar la rama.

## 6. Monitoreo

- [ ] 6.1 Tras la siguiente sincronización de los usuarios afectados, revisar Sentry: `REEVO-PROD-A`, `-B` y `-G` sin eventos nuevos. Marcarlos como resueltos solo cuando dejen de llegar, y avisar al usuario afectado que reabra la app (con el login pendiente, su Inbox debería completar la carga).

## 7. Retiro (posterior)

- [x] 7.1 Dejar registrada, en el cuerpo del PR y en la migración, la consulta de PostHog que evalúa el criterio de retiro: usuarios con sesión iniciada con `screen_view` en `$app_version` `1.8.x` en los últimos 14 días (definir con precisión "sesión iniciada", p. ej. personas con `login_completed` o `$identify` en el periodo), junto con la consulta a Sentry de eventos `PGRST205` sobre la tabla. (Registrada aquí y en el cuerpo del PR, no en el comentario de la migración, para que el archivo siga idéntico a lo aplicado en prod. PostHog: personas distintas con `$app_version` que empieza con `1.8` y algún evento de `login_completed`, `$identify` o `sync_triggered` en los últimos 14 días; deben ser 0. `$identify` y `login_completed` solo ocurren al iniciar sesión y `sync_triggered` al hacer pull-to-refresh, así que un usuario que solo abre y lee sin refrescar no se detecta: por eso se complementa con Sentry, `sentry issue list --query "PGRST205"`, que debe quedar sin eventos nuevos tras el retiro, y la tabla se puede recrear en minutos con la misma migración. Consulta de PostHog: `SELECT uniq(person_id) FROM events WHERE event IN ('login_completed', '$identify', 'sync_triggered') AND startsWith(properties.$app_version, '1.8') AND timestamp >= now() - INTERVAL 14 DAY`.)
- [ ] 7.2 Cuando se cumpla el criterio, crear una migración que elimine `daily_summary_free_usage`, aplicarla con confirmación del usuario, verificar que no aparecen eventos `PGRST205` nuevos y archivar el change.
- [ ] 7.3 Proponer al usuario añadir a `CLAUDE.md` una regla de orden de despliegue: un recurso del servidor que consultan clientes publicados se elimina solo después de que la versión sin esa dependencia esté disponible en la App Store y adoptada (no solo en TestFlight). Solo se edita `CLAUDE.md` si el usuario lo aprueba.
