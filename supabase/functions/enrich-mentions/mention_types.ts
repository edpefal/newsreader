// Tipos compartidos por request/response de enrich-mentions. Mismos 4 tipos
// soportados que summarize-article/mentions.ts (libros/podcasts/música y,
// desde add-article-mentioned-links, artículos citados vía URL) --
// "productos" queda fuera de scope, ver proposal.md de
// add-article-summary-mentions.
export const MENTION_TYPES = ["book", "podcast", "music", "article"] as const;
export type MentionType = (typeof MENTION_TYPES)[number];

export interface RawMention {
  type: MentionType;
  name: string;
  // Solo presente (y requerida) cuando type === "article".
  url?: string;
}

export interface EnrichedMention extends RawMention {
  imageUrl?: string;
  link?: string;
}

export function isValidRawMention(value: unknown): value is RawMention {
  if (typeof value !== "object" || value === null) return false;
  const record = value as Record<string, unknown>;
  if (
    typeof record.name !== "string" ||
    !(MENTION_TYPES as readonly string[]).includes(record.type as string)
  ) {
    return false;
  }
  if (record.type === "article") {
    return typeof record.url === "string" && record.url.trim().length > 0;
  }
  return true;
}
