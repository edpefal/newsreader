-- La agrupación por fuente (sourceBlocks) que la app persiste junto a cada
-- DailySummary no viajaba en la sincronización: la tabla no tenía columna
-- para guardarla, así que se perdía en el primer sync posterior a generar
-- el resumen y los chips de "artículos de origen" dejaban de mostrarse
-- (ver fix-daily-summary-sourceblocks-sync). Columna aditiva y nullable:
-- los resúmenes existentes quedan en null, mismo comportamiento ya
-- contemplado por la app para "resumen sin agrupación persistida".
alter table daily_summaries
  add column if not exists source_blocks jsonb;
