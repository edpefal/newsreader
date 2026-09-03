-- Asocia cada feed generado al usuario que lo creó, necesario para que el
-- rate limit de creación de feeds (`MAX_FEEDS_PER_HOUR` en create-feed) sea
-- por usuario en vez de global -- sin esto, un solo usuario podía agotar la
-- cuota horaria compartida por todos (ver change
-- harden-security-vulnerabilities).
--
-- Nullable: las filas existentes de `generated_feeds` no tienen forma de
-- atribuirse retroactivamente a un usuario (la tabla nunca guardó esa
-- relación). El conteo del rate limit en `create-feed` filtra por
-- `user_id = auth.uid()`, así que las filas históricas con `user_id` nulo
-- simplemente no cuentan para el límite de ningún usuario -- no requieren
-- backfill.
alter table generated_feeds
  add column user_id uuid references auth.users(id) on delete cascade;

create index generated_feeds_user_id_created_at_idx
  on generated_feeds (user_id, created_at);
