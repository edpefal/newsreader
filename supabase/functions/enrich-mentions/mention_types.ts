// Tipos compartidos por request/response de enrich-mentions. Mismos 3 tipos
// soportados que summarize-article/mentions.ts (libros/podcasts/música) --
// "productos" queda fuera de scope, ver proposal.md.
export const MENTION_TYPES = ["book", "podcast", "music"] as const;
export type MentionType = (typeof MENTION_TYPES)[number];

export interface RawMention {
  type: MentionType;
  name: string;
}

export interface EnrichedMention extends RawMention {
  imageUrl?: string;
  link?: string;
}

export function isValidRawMention(value: unknown): value is RawMention {
  if (typeof value !== "object" || value === null) return false;
  const record = value as Record<string, unknown>;
  return typeof record.name === "string" &&
    (MENTION_TYPES as readonly string[]).includes(record.type as string);
}
