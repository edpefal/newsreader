-- Reemplaza el presupuesto diario de palabras de `ai_usage_daily` por un
-- límite contable de resúmenes generados (ver change
-- limit-article-summaries-by-count): la unidad deja de ser palabras de
-- input y pasa a ser "resúmenes de artículo generados hoy", mucho más
-- predecible para el usuario. Sin backfill: el consumo es por-día y se
-- resetea diariamente de todos modos, así que no hay valor histórico que
-- preservar entre `words_used` y `summaries_used`.

alter table ai_usage_daily
  add column summaries_used integer not null default 0;

alter table ai_usage_daily
  drop column words_used;

drop function check_and_record_ai_usage(integer, integer);

-- Mismo patrón que la función original (lock de fila + reset por cambio de
-- `day` + chequeo-e-incremento atómico en un único bloque bajo el lock),
-- pero incrementando `summaries_used` de a 1 en vez de sumar palabras.
create function check_and_record_ai_usage(
  p_daily_limit integer
)
returns table (allowed boolean, summaries_used integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_day date;
  v_summaries_used integer;
  v_effective_summaries integer;
  v_new_summaries integer;
  v_allowed boolean;
begin
  insert into ai_usage_daily (user_id, day, summaries_used)
  values (v_user_id, current_date, 0)
  on conflict (user_id) do nothing;

  select ai_usage_daily.day, ai_usage_daily.summaries_used
    into v_day, v_summaries_used
    from ai_usage_daily
    where user_id = v_user_id
    for update;

  v_effective_summaries := case when v_day <> current_date then 0 else v_summaries_used end;
  v_allowed := v_effective_summaries + 1 <= p_daily_limit;
  v_new_summaries := case when v_allowed then v_effective_summaries + 1 else v_effective_summaries end;

  update ai_usage_daily
  set day = current_date, summaries_used = v_new_summaries, updated_at = now()
  where user_id = v_user_id;

  return query select v_allowed, v_new_summaries;
end;
$$;

revoke all on function check_and_record_ai_usage(integer) from public;
grant execute on function check_and_record_ai_usage(integer) to authenticated;
