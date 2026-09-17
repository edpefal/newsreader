-- Nueva capability `user-preferences` (ver
-- openspec/changes/add-automatic-daily-summary): persiste el locale activo
-- y el offset horario UTC del dispositivo de cada usuario, para que procesos
-- del servidor sin sesión en vivo (la generación automática del resumen
-- diario) sepan en qué idioma y a qué hora local generar contenido.
--
-- A diferencia de `entitlements` (donde solo `service_role` escribe), acá el
-- propio cliente hace upsert de su fila en cada ciclo de `SyncUserData`, así
-- que sí necesita policies de insert/update para el usuario dueño de la
-- fila, mismo patrón que `sources`/`articles`.
create table user_preferences (
  user_id uuid primary key references auth.users (id) on delete cascade,
  locale text,
  utc_offset_minutes integer,
  updated_at timestamptz not null default now()
);

-- Consultado por `generate-daily-summaries` filtrando por lote de
-- `user_id` (ver `in(...)`) -- no hace falta paginar por `updated_at` como
-- sources/articles: es una sola fila chica por usuario y `SyncUserData` la
-- reescribe siempre completa (upsert incondicional, no "changed since"), así
-- que un índice por `updated_at` no aporta acá.
alter table user_preferences enable row level security;

create policy "user_preferences_select_own" on user_preferences
  for select using (user_id = auth.uid());
create policy "user_preferences_insert_own" on user_preferences
  for insert with check (user_id = auth.uid());
create policy "user_preferences_update_own" on user_preferences
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Sin policy de delete física: no hace falta borrar preferencias fuera del
-- cascade de `on delete cascade` cuando se borra la cuenta.
