-- Cron que invoca la nueva Edge Function `generate-daily-summaries` cada
-- hora (ver openspec/changes/add-automatic-daily-summary/design.md,
-- Decisión 3). Mismo mecanismo de `net.http_post` + Vault que el cron de
-- `sync-feeds` en modo background (ver
-- `20260916010000_sync_feeds_background_cron.sql`) -- reusa los mismos
-- secretos `project_url`/`service_role_key`, que deben existir en Vault
-- antes de que este cron pueda invocar la función con éxito.
select cron.schedule(
  'generate-daily-summaries-hourly',
  '0 * * * *',
  $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url')
      || '/functions/v1/generate-daily-summaries',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (
        select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key'
      )
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 60000
  );
  $$
);
