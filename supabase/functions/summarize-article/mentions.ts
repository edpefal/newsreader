// Parseo y validación de la lista de menciones devuelta por Gemini,
// extraído a una función pura y testeable (mismo patrón que
// entitlement.ts/language.ts/word_count.ts en esta carpeta). No confía en
// que el `responseSchema` haya sido respetado al pie de la letra: si algún
// item no matchea el shape esperado, se trata toda la respuesta como
// inválida en vez de devolver una lista parcialmente corrupta.
export const MENTION_TYPES = ["book", "podcast", "music", "article"] as const;
export type MentionType = (typeof MENTION_TYPES)[number];

export interface RawMention {
  type: MentionType;
  name: string;
  // Solo presente (y requerida) cuando type === "article": la URL del
  // artículo mencionado, detectada por el modelo a partir de los links
  // `[texto](url)` preservados en el contenido -- ver
  // add-article-mentioned-links/design.md.
  url?: string;
}

export function parseMentions(value: unknown): RawMention[] | null {
  if (!Array.isArray(value)) return null;
  const mentions: RawMention[] = [];
  for (const item of value) {
    if (typeof item !== "object" || item === null) return null;
    const record = item as Record<string, unknown>;
    if (
      typeof record.name !== "string" ||
      !(MENTION_TYPES as readonly string[]).includes(record.type as string)
    ) {
      return null;
    }
    if (record.type === "article") {
      if (typeof record.url !== "string" || record.url.trim().length === 0) {
        return null;
      }
      mentions.push({ type: "article", name: record.name, url: record.url });
      continue;
    }
    mentions.push({
      type: record.type as MentionType,
      name: record.name,
    });
  }
  return mentions;
}
