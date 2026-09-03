-- Cupo gratis semanal de resumen diario para usuarios sin suscripción
-- activa (ver openspec/changes/add-daily-summary-free-tier). Tabla separada
-- de `ai_usage_daily`: el período de reset es semanal (lunes), no diario, y
-- el límite es fijo en 1 (no configurable como sí lo es el límite diario de
-- `article-summaries`), así que `used boolean` alcanza en vez de un
-- contador entero.
create table daily_summary_free_usage (
  user_id uuid primary key references auth.users (id) on delete cascade,
  week_start date not null default date_trunc('week', current_date)::date,
  used boolean not null default false,
  updated_at timestamptz not null default now()
);

alter table daily_summary_free_usage enable row level security;

-- Mismo patrón que `ai_usage_daily_select_own`: el usuario solo lee su
-- propia fila; nunca la escribe directo, solo a través de las funciones
-- `security definer` de abajo.
create policy daily_summary_free_usage_select_own on daily_summary_free_usage
  for select
  using (user_id = auth.uid());

-- Marca el cupo gratis semanal como usado. A diferencia de
-- `check_and_record_ai_usage` (que chequea-e-incrementa ANTES de invocar a
-- la API de IA), esta función se llama DESPUÉS de persistir el
-- `DailySummary` exitosamente -- su contrato es "marcar usado", no
-- "chequear y permitir": `summarize-articles` ya decidió generar (vía
-- `get_daily_summary_free_usage_status`) antes de invocar a Gemini, así que
-- acá no hace falta volver a chequear disponibilidad, solo persistir el
-- consumo. Resetea `week_start`/`used` si cambió la semana calendario
-- (lunes, día de servidor) desde el último uso registrado.
create function check_and_record_daily_summary_free_usage()
returns table (allowed boolean, used boolean)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_current_week date := date_trunc('week', current_date)::date;
begin
  insert into daily_summary_free_usage (user_id, week_start, used)
  values (v_user_id, v_current_week, false)
  on conflict (user_id) do nothing;

  -- `for update` toma un lock de fila, mismo patrón que
  -- `check_and_record_ai_usage`, para que dos llamadas concurrentes del
  -- mismo usuario no puedan pisarse.
  perform 1
    from daily_summary_free_usage
    where user_id = v_user_id
    for update;

  update daily_summary_free_usage
  set week_start = v_current_week, used = true, updated_at = now()
  where user_id = v_user_id;

  return query select true, true;
end;
$$;

revoke all on function check_and_record_daily_summary_free_usage() from public;
grant execute on function check_and_record_daily_summary_free_usage() to authenticated;

-- Consulta de solo lectura del cupo gratis semanal, para que
-- `summarize-articles` decida si hay cupo disponible ANTES de invocar a
-- Gemini, y para que el cliente refleje el estado sin depender de que una
-- solicitud falle primero (ver capability `ai-usage-budget`, requirement
-- "Consulta de estado del cupo gratis semanal"). No escribe: si la semana
-- guardada quedó vieja, devuelve el estado reseteado calculado al vuelo, sin
-- persistirlo -- la próxima llamada a `check_and_record_daily_summary_free_usage`
-- es quien efectivamente persiste el reset.
create function get_daily_summary_free_usage_status()
returns table (week_start date, used boolean)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_current_week date := date_trunc('week', current_date)::date;
  v_row daily_summary_free_usage;
begin
  select * into v_row from daily_summary_free_usage where user_id = v_user_id;

  if v_row is null or v_row.week_start <> v_current_week then
    return query select v_current_week, false;
  end if;

  return query select v_row.week_start, v_row.used;
end;
$$;

revoke all on function get_daily_summary_free_usage_status() from public;
grant execute on function get_daily_summary_free_usage_status() to authenticated;
