-- Sincronización de datos de usuario entre dispositivos (fuentes, artículos,
-- resúmenes diarios). Ver openspec/changes/archive/*-sync-user-data-to-cloud/
-- design.md para el diseño completo.
--
-- Los `id` son los mismos UUID generados del lado del cliente (IdGenerator),
-- no se regeneran en Postgres. `updated_at`/`deleted_at` son la base del
-- mecanismo de sincronización incremental (push/pull comparando timestamps).

create table sources (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  feed_url text not null,
  author text,
  icon_url text,
  added_at timestamptz not null,
  last_synced_at timestamptz,
  has_error boolean not null default false,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index sources_user_id_updated_at_idx on sources (user_id, updated_at);

create table articles (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  source_id text not null,
  source_name text not null,
  source_icon_url text,
  title text not null,
  author text,
  published_at timestamptz not null,
  content_html text,
  excerpt text,
  article_url text not null,
  is_read boolean not null default false,
  is_favorite boolean not null default false,
  is_archived boolean not null default false,
  read_at timestamptz,
  saved_as_favorite_at timestamptz,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index articles_user_id_updated_at_idx on articles (user_id, updated_at);

create table daily_summaries (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  date timestamptz not null,
  content text not null,
  article_count integer not null,
  created_at timestamptz not null,
  updated_at timestamptz not null default now()
);

create index daily_summaries_user_id_updated_at_idx on daily_summaries (user_id, updated_at);

-- RLS: cada usuario solo ve/escribe sus propias filas. Sin policy de delete
-- física — el borrado es lógico vía deleted_at (ver Requirement "Borrados
-- propagados vía soft-delete" en specs/cloud-sync/spec.md).

alter table sources enable row level security;
alter table articles enable row level security;
alter table daily_summaries enable row level security;

create policy "sources_select_own" on sources
  for select using (user_id = auth.uid());
create policy "sources_insert_own" on sources
  for insert with check (user_id = auth.uid());
create policy "sources_update_own" on sources
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "articles_select_own" on articles
  for select using (user_id = auth.uid());
create policy "articles_insert_own" on articles
  for insert with check (user_id = auth.uid());
create policy "articles_update_own" on articles
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "daily_summaries_select_own" on daily_summaries
  for select using (user_id = auth.uid());
create policy "daily_summaries_insert_own" on daily_summaries
  for insert with check (user_id = auth.uid());
create policy "daily_summaries_update_own" on daily_summaries
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());
