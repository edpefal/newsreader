-- Feeds RSS generados por email (kill-the-newsletter-style).
-- Ver openspec/changes/email-to-rss-generated-feeds/design.md para el diseño completo.

create extension if not exists pg_cron with schema extensions;

create table generated_feeds (
  id uuid primary key default gen_random_uuid(),
  label text,
  created_at timestamptz not null default now()
);

create table feed_items (
  id uuid primary key default gen_random_uuid(),
  feed_id uuid not null references generated_feeds(id) on delete cascade,
  title text not null,
  content_html text not null,
  from_address text,
  received_at timestamptz not null,
  message_id text not null,
  unique (feed_id, message_id)
);

create index feed_items_feed_id_received_at_idx
  on feed_items (feed_id, received_at desc);

-- Limpieza diaria de items con más de 30 días (ver Decisión 6 del design.md:
-- el dedupe por URL del lado del cliente ya evita pérdida de datos real).
select cron.schedule(
  'delete-old-feed-items',
  '0 3 * * *',
  $$ delete from feed_items where received_at < now() - interval '30 days' $$
);
