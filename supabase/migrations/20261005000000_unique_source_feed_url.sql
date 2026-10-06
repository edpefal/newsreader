-- Una fuente activa es única por usuario y feed URL (ver capability
-- `cloud-sync`, requirement "Una fuente activa es única por usuario y feed
-- URL en el servidor"). Hasta ahora solo el cliente verificaba el duplicado
-- contra su caja local, así que agregar el mismo feed desde un dispositivo
-- que aún no había sincronizado la otra fuente creaba dos filas activas.
--
-- Orden de despliegue: aplicar DESPUÉS de publicar el cliente que reconcilia
-- el error de unicidad (23505) al subir una fuente; un cliente anterior que
-- suba un duplicado vería fallar su sincronización completa mientras esa
-- fuente local exista.
--
-- Rollback: `drop index sources_user_id_feed_url_active_key;` (no restaura la
-- fusión de duplicados, que es una limpieza deliberada).

-- 1. Deduplicar los datos existentes. Por cada (user_id, feed_url) con más de
--    una fuente activa se conserva la más antigua (menor `added_at`,
--    desempate por `id`) y se preserva el trabajo del usuario sobre las
--    demás. Todo `updated_at` se actualiza con `now()` para que cada
--    dispositivo, con su cursor actual, descargue el cambio.
do $$
declare
  d record;
begin
  for d in
    select s.id as dup_id, k.keep_id, s.user_id
    from sources s
    join (
      select distinct on (user_id, feed_url) user_id, feed_url, id as keep_id
      from sources
      where deleted_at is null
      order by user_id, feed_url, added_at, id
    ) k
      on k.user_id = s.user_id
     and k.feed_url = s.feed_url
     and k.keep_id <> s.id
    where s.deleted_at is null
  loop
    -- a) Artículos que existen en ambas fuentes (misma URL): el de la
    --    conservada se queda con el estado más "avanzado" de los dos.
    update articles k
    set is_read = k.is_read or dup.is_read,
        is_favorite = k.is_favorite or dup.is_favorite,
        is_archived = k.is_archived or dup.is_archived,
        read_at = least(k.read_at, dup.read_at),
        saved_as_favorite_at = least(k.saved_as_favorite_at, dup.saved_as_favorite_at),
        updated_at = now()
    from articles dup
    where k.source_id = d.keep_id
      and dup.source_id = d.dup_id
      and k.user_id = d.user_id
      and dup.user_id = d.user_id
      and dup.article_url = k.article_url
      and k.deleted_at is null
      and dup.deleted_at is null;

    -- b) Los artículos de la sobrante que ya tienen equivalente en la
    --    conservada (cualquier fila, incluso borrada: respeta la restricción
    --    única (source_id, article_url)) se dan de baja.
    update articles dup
    set deleted_at = now(),
        updated_at = now()
    where dup.source_id = d.dup_id
      and dup.user_id = d.user_id
      and dup.deleted_at is null
      and exists (
        select 1
        from articles k
        where k.source_id = d.keep_id
          and k.article_url = dup.article_url
      );

    -- c) Los que solo existían en la sobrante pasan a la conservada, con su
    --    estado intacto (incluidos favoritos, que el trigger de cascada no
    --    tocaría al dar de baja la fuente).
    update articles dup
    set source_id = d.keep_id,
        source_name = ks.name,
        source_icon_url = ks.icon_url,
        updated_at = now()
    from sources ks
    where ks.id = d.keep_id
      and dup.source_id = d.dup_id
      and dup.user_id = d.user_id
      and dup.deleted_at is null;

    -- d) Baja de la fuente sobrante. El trigger `sources_cascade_delete_articles`
    --    ya no encuentra artículos activos de esta fuente que arrastrar.
    update sources
    set deleted_at = now(),
        updated_at = now()
    where id = d.dup_id;
  end loop;
end;
$$;

-- 2. Unicidad de las fuentes activas por usuario y feed URL. Parcial: las
--    borradas (soft-delete) quedan fuera, así que volver a agregar un feed
--    eliminado sigue siendo posible.
create unique index if not exists sources_user_id_feed_url_active_key
  on sources (user_id, feed_url)
  where deleted_at is null;
