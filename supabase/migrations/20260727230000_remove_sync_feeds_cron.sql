-- Se saca el cron baseline de `sync-feeds`: el fetch on-demand disparado
-- por pull-to-refresh alcanza para el uso real de la app (newsletters, no
-- contenido en vivo), y evita la complejidad de pg_cron/pg_net/Vault y los
-- ajustes de resource-limit que hicieron falta para sostenerlo.
select cron.unschedule('sync-feeds-hourly');

-- Los secretos de Vault ya no tienen otro consumidor -- se limpian.
delete from vault.secrets where name in ('project_url', 'service_role_key');
