-- Corrige el cron de `sync-feeds`: invocar la función una sola vez en modo
-- "todos los usuarios" agota el presupuesto de CPU del Edge Function no
-- bien hay unas pocas decenas de fuentes en total (confirmado en despliegue:
-- WORKER_RESOURCE_LIMIT con 89 fuentes entre 2 cuentas). Se reemplaza por
-- una invocación separada por usuario, cada una acotada a sus propias
-- fuentes -- ver `sync-feeds/index.ts`, que ahora exige `user_id` en el
-- body cuando el caller es `service_role`.
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
    body := jsonb_build_object('user_id', s.user_id)
  )
  from (select distinct user_id from sources) s;
  $$
);
