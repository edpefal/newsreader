-- Presupuesto diario de palabras de input consumidas por features de IA
-- (ver openspec/changes/add-daily-summary-word-budget). Una sola fila por
-- usuario (no una fila por día): se resetea in-place cuando cambia `day`,
-- evitando tener que purgar filas viejas.
create table ai_usage_daily (
  user_id uuid primary key references auth.users (id) on delete cascade,
  day date not null default current_date,
  words_used integer not null default 0,
  updated_at timestamptz not null default now()
);

alter table ai_usage_daily enable row level security;

-- El usuario solo puede leer su propia fila (mismo patrón que
-- `entitlements_select_own`). El cliente Flutter la lee vía
-- `CloudSyncClient.fetchChangedSince('ai_usage_daily', null)` para armar el
-- medidor visible; nunca la escribe directamente.
create policy ai_usage_daily_select_own on ai_usage_daily
  for select
  using (user_id = auth.uid());

-- Sin policy de insert/update para roles no privilegiados: la única forma de
-- escribir esta tabla es a través de `check_and_record_ai_usage`
-- (`security definer`), nunca directo desde el cliente con el
-- anon/authenticated key.

-- Chequea el presupuesto disponible e incrementa el consumo registrado como
-- una única operación atómica: usa `auth.uid()` internamente (nunca un
-- `user_id` que mande el caller), resetea `words_used` a 0 si `day` no es el
-- día actual, y hace el chequeo-e-incremento en un único
-- `UPDATE ... RETURNING`, atómico por el locking de fila de Postgres.
-- `summarize-articles` (y cualquier futura feature de IA) llama a esta
-- función ANTES de invocar a la API de IA.
create function check_and_record_ai_usage(
  p_words integer,
  p_daily_limit integer
)
returns table (allowed boolean, words_used integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_day date;
  v_words_used integer;
  v_effective_words integer;
  v_new_words integer;
  v_allowed boolean;
begin
  -- Crea la fila del usuario si es la primera vez que consume presupuesto de
  -- IA.
  insert into ai_usage_daily (user_id, day, words_used)
  values (v_user_id, current_date, 0)
  on conflict (user_id) do nothing;

  -- `for update` toma un lock de fila: una segunda llamada concurrente para
  -- el mismo usuario queda bloqueada acá hasta que esta transacción termine,
  -- así que no hay ventana de carrera entre leer el consumo y escribirlo.
  select ai_usage_daily.day, ai_usage_daily.words_used
    into v_day, v_words_used
    from ai_usage_daily
    where user_id = v_user_id
    for update;

  -- Si cambió el día, el consumo previo no cuenta -- se resetea antes de
  -- aplicar el chequeo, sin importar si esta solicitud en particular termina
  -- permitida o rechazada.
  v_effective_words := case when v_day <> current_date then 0 else v_words_used end;
  v_allowed := v_effective_words + p_words <= p_daily_limit;
  v_new_words := case when v_allowed then v_effective_words + p_words else v_effective_words end;

  update ai_usage_daily
  set day = current_date, words_used = v_new_words, updated_at = now()
  where user_id = v_user_id;

  return query select v_allowed, v_new_words;
end;
$$;

-- Solo usuarios autenticados (nunca el anon key) pueden invocarla -- mismo
-- criterio que ya aplica `summarize-articles` exigiendo una sesión real.
revoke all on function check_and_record_ai_usage(integer, integer) from public;
grant execute on function check_and_record_ai_usage(integer, integer) to authenticated;
