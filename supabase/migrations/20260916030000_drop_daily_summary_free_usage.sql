-- Elimina el cupo gratis semanal consumible a demanda (ver capability
-- `ai-usage-budget`, requirement removido "Límite semanal gratis de resumen
-- diario por usuario"): la elegibilidad gratis pasa a derivarse
-- directamente del día de la semana (lunes) en `generate-daily-summaries`,
-- sin necesitar un contador persistido aparte. Sin backfill: no hay ningún
-- valor de `daily_summary_free_usage` que tenga sentido conservar una vez
-- eliminado el flujo manual que lo consultaba.
drop function if exists check_and_record_daily_summary_free_usage();
drop function if exists get_daily_summary_free_usage_status();
drop table if exists daily_summary_free_usage;
