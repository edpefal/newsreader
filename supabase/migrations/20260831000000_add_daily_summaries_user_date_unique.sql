-- Constraint de integridad para reforzar "como máximo un DailySummary por
-- (usuario, fecha)" a nivel de base de datos, no solo en el cliente (ver
-- limit-daily-summary-to-once-per-day). Defensivo: en el flujo normal el
-- `id` de cada fila ya es determinístico por fecha del lado del cliente, así
-- que esta constraint no debería dispararse en uso normal, pero cierra la
-- puerta a que una sincronización con datos inconsistentes deje dos filas
-- para el mismo (user_id, date).
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'daily_summaries_user_id_date_key'
  ) then
    alter table daily_summaries
      add constraint daily_summaries_user_id_date_key unique (user_id, date);
  end if;
end $$;
