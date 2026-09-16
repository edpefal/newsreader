// Agrupación por fuente de los artículos incluidos en un `DailySummary`,
// persistida junto al resumen (columna `source_blocks`, jsonb) -- ver
// capability `daily-summaries`. Las claves del JSON son camelCase
// (`sourceId`/`sourceName`/`articleIds`) a propósito: es el mismo shape que
// ya produce el cliente Flutter (`DailySummaryModel._sourceBlocksToMaps`) y
// que `SyncUserData` espera poder deserializar de vuelta
// (`_sourceBlocksFromRow`), sin importar si la fila la escribió el cliente
// o este proceso del servidor.
export interface SourceBlockArticle {
  id: string;
  source_id: string;
  source_name: string;
}

export interface SourceBlock {
  sourceId: string;
  sourceName: string;
  articleIds: string[];
}

/** Agrupa por fuente, preservando el orden de primera aparición. */
export function buildSourceBlocks(
  articles: SourceBlockArticle[],
): SourceBlock[] {
  const bySourceId = new Map<string, SourceBlock>();
  for (const article of articles) {
    const existing = bySourceId.get(article.source_id);
    if (existing) {
      existing.articleIds.push(article.id);
    } else {
      bySourceId.set(article.source_id, {
        sourceId: article.source_id,
        sourceName: article.source_name,
        articleIds: [article.id],
      });
    }
  }
  return Array.from(bySourceId.values());
}
