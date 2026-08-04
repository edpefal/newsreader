-- Imagen destacada del artículo, extraída del feed de origen por
-- `sync-feeds` (Media RSS, enclosure, itunes:image o <img> embebido en el
-- HTML). Nullable: no todos los artículos tienen imagen disponible. Sin
-- backfill -- artículos ya sincronizados no se re-procesan.
alter table articles add column image_url text null;
