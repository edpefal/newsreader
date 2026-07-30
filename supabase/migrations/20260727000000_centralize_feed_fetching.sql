-- Fetch centralizado de feeds RSS del lado del servidor.
-- Ver openspec/changes/centralize-feed-fetching/design.md para el diseño completo.

-- 1.1: dedupe garantizado a nivel de base de datos, no solo por chequeo
-- previo del lado de la aplicación (necesario para que el fetch on-demand y
-- el cron puedan solaparse sin crear duplicados).
alter table articles
  add constraint articles_source_id_article_url_key unique (source_id, article_url);

-- El id de artículo pasa a generarse en el servidor (antes lo generaba el
-- cliente). La columna sigue siendo `text` (no se migra a `uuid` para no
-- tocar el resto del esquema/RLS), pero el default ya genera un UUID.
alter table articles alter column id set default gen_random_uuid()::text;

-- 1.3: `service_role` bypassea RLS por defecto en Postgres/Supabase, así que
-- la Edge Function `sync-feeds` (que siempre usa `service_role` para
-- escribir, incluso en modo on-demand) no necesita una policy adicional
-- para insertar/actualizar artículos de cualquier usuario.

-- 3.1: cron baseline que invoca la Edge Function `sync-feeds` cada 1 hora,
-- en modo "todos los usuarios" (sin body). Mismo patrón de pg_net usado
-- para invocar Edge Functions desde pg_cron.
--
-- La URL del proyecto y la service_role key NO se hardcodean acá (esta
-- migración se commitea a git) — se leen de Supabase Vault. Antes de que
-- este cron funcione hay que crear los secretos una sola vez (dashboard o
-- SQL editor, nunca en una migración versionada):
--   select vault.create_secret('https://avyaxzhdilhufyimrzzb.supabase.co', 'project_url');
--   select vault.create_secret('<service_role_key>', 'service_role_key');
create extension if not exists pg_net with schema extensions;

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
    body := '{}'::jsonb
  );
  $$
);

-- 1.2: borrón y cuenta nueva del historial de artículos (decisión explícita,
-- ver design.md Decisión 5) — a partir de acá los ids son generados por el
-- servidor y el contenido nace vía `sync-feeds`, nunca subido por el
-- cliente. Va al final: si algo de lo anterior falla, no se pierden datos.
truncate table articles;
