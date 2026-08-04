-- Al borrar una fuente (soft-delete vía `sources.deleted_at`), sus
-- artículos quedaban huérfanos en Supabase si el cliente no llegaba a
-- propagar el estado de cada artículo individualmente (updatePartial hacía
-- un UPDATE por fila, sin retry -- un solo fallo a mitad de camino dejaba
-- el resto vivo para siempre). Este trigger hace que el borrado de la
-- fuente cascade atómicamente a sus artículos del lado del servidor, sin
-- depender de que el cliente complete ningún push adicional. Respeta el
-- mismo criterio que ya usa el cliente (`keepFavorites: true`): los
-- artículos favoritos nunca se tocan.
--
-- Corre con los privilegios de quien dispara el UPDATE sobre `sources`
-- (sin SECURITY DEFINER): como el UPDATE que el trigger ejecuta sobre
-- `articles` sigue filtrando por el mismo `user_id`, la policy
-- `articles_update_own` ya lo permite -- no hace falta elevar privilegios.
create function cascade_delete_source_articles() returns trigger as $$
begin
  if new.deleted_at is not null and old.deleted_at is null then
    update articles
    set deleted_at = new.deleted_at,
        updated_at = new.deleted_at
    where source_id = new.id
      and user_id = new.user_id
      and deleted_at is null
      and is_favorite = false;
  end if;
  return new;
end;
$$ language plpgsql;

create trigger sources_cascade_delete_articles
  after update on sources
  for each row
  execute function cascade_delete_source_articles();

-- Backfill de una sola vez: repara los artículos que ya quedaron huérfanos
-- en producción antes de que existiera este trigger (ej. Hacker News).
update articles
set deleted_at = now(),
    updated_at = now()
where deleted_at is null
  and is_favorite = false
  and source_id in (select id from sources where deleted_at is not null);
