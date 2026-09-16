-- Reintroduce un cron para `sync-feeds`, en modo "background" (ver
-- openspec/changes/add-automatic-daily-summary/design.md, Decisión 1). A
-- diferencia del cron removido en `20260727230000_remove_sync_feeds_cron.sql`
-- (una invocación por usuario, con todas sus fuentes -- el diseño que causó
-- WORKER_RESOURCE_LIMIT en `centralize-feed-fetching`), esta vez es una
-- única invocación por corrida, acotada al mismo tope de 20 fuentes que ya
-- protege el modo on-demand, tomadas de TODA la tabla `sources` (no de un
-- usuario en particular) ordenadas por `last_synced_at` ascendente. El
-- sistema converge a "todo fresco" con el tiempo sin arriesgar el resource
-- limit de una invocación individual.
--
-- Cada pocos minutos (cada 5): con lotes de 20 fuentes, alcanza para que la
-- base se ponga al día varias veces por hora sin sumar invocaciones
-- innecesarias.
--
-- Los secretos `project_url`/`service_role_key` de Vault se borraron en
-- `20260727230000_remove_sync_feeds_cron.sql` al sacar el cron anterior.
-- Antes de que este cron (y el de `generate-daily-summaries`, que reusa los
-- mismos secretos) funcione hay que volver a crearlos una sola vez (dashboard
-- o SQL editor, nunca en una migración versionada):
--   select vault.create_secret('https://<project-ref>.supabase.co', 'project_url');
--   select vault.create_secret('<service_role_key>', 'service_role_key');
create extension if not exists pg_net with schema extensions;

select cron.schedule(
  'sync-feeds-background',
  '*/5 * * * *',
  $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url')
      || '/functions/v1/sync-feeds',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (
        select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key'
      )
    ),
    body := jsonb_build_object('mode', 'background'),
    timeout_milliseconds := 60000
  );
  $$
);
