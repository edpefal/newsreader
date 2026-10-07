-- EXCEPCIÓN TEMPORAL: tabla de compatibilidad para clientes 1.8.x (ver
-- capability `legacy-client-compatibility`).
--
-- Por qué existe: la migración 20260916030000 eliminó `daily_summary_free_usage`
-- (el resumen diario automático quitó el flujo manual que la usaba), y se
-- aplicó el 2 de octubre, ANTES de que la versión 1.9.0, que ya no la
-- consulta, estuviera pública en la App Store (salió el 6 de octubre). El
-- cliente 1.8.0 (build 18) la sincroniza como último paso de cada ciclo, y sin
-- la tabla Postgrest devuelve PGRST205: la sincronización falla en cada ciclo
-- y, como ese build espera la sincronización de login sin manejar errores, el
-- Inbox se queda cargando indefinidamente tras iniciar sesión.
--
-- Qué hace: recrea la tabla con el esquema original, VACÍA a propósito. El
-- cliente 1.8.x solo la lee (nunca la escribe), así que una tabla sin filas
-- hace que su consulta devuelva [] y la sincronización complete. No se
-- recrean las funciones `security definer` que la escribían: la generación
-- manual de resumen diario en 1.8.x sigue sin funcionar, y eso es aceptado.
--
-- Cuándo retirarla: cuando ya no haya usuarios con sesión iniciada en 1.8.x
-- durante 14 días consecutivos (PostHog: `screen_view`, `$app_version`) y no
-- haya eventos nuevos de PGRST205 sobre esta tabla en ese periodo (Sentry).
-- Rollback / retiro: `drop table daily_summary_free_usage;`
create table if not exists daily_summary_free_usage (
  user_id uuid primary key references auth.users (id) on delete cascade,
  week_start date not null default date_trunc('week', current_date)::date,
  used boolean not null default false,
  updated_at timestamptz not null default now()
);

alter table daily_summary_free_usage enable row level security;

-- Igual que el original: el usuario solo lee su propia fila.
drop policy if exists daily_summary_free_usage_select_own on daily_summary_free_usage;
create policy daily_summary_free_usage_select_own on daily_summary_free_usage
  for select
  using (user_id = auth.uid());

-- Defensa en profundidad: sin políticas de escritura RLS ya las rechaza, pero
-- una tabla de compatibilidad no debe poder poblarse ni por un cambio
-- accidental de políticas.
revoke insert, update, delete on daily_summary_free_usage from anon, authenticated;
