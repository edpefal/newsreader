-- Instante en que el usuario abrió o descartó el resumen diario en el Inbox
-- (ver capability `inbox-daily-summary-card`). Es nullable y sin default: un
-- cliente anterior que no conoce la columna sube filas sin ella y el upsert
-- plano de PostgREST no la toca, así que es retrocompatible.
--
-- Orden de despliegue: aplicar ANTES de publicar el cliente que la envía; si
-- no, el upsert/updatePartial de `daily_summaries` falla por columna
-- inexistente.
--
-- Rollback: `alter table daily_summaries drop column dismissed_at;`

alter table daily_summaries
  add column if not exists dismissed_at timestamptz;
