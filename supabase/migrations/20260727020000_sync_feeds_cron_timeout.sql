-- pg_net usa un timeout por defecto de 5s en net.http_post, muy corto para
-- `sync-feeds` (puede tardar 20-30s en fuentes lentas). Sin esto, la
-- request queda "pendiente" para siempre en net._http_response (confirmado
-- en despliegue). Se sube a 60s explícitamente.
select cron.unschedule('sync-feeds-hourly');

select cron.schedule(
  'sync-feeds-hourly',
  '0 * * * *',
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
    body := jsonb_build_object('user_id', s.user_id),
    timeout_milliseconds := 60000
  )
  from (select distinct user_id from sources) s;
  $$
);
