// Parseo y validación de la lista de menciones devuelta por Gemini,
// extraído a una función pura y testeable (mismo patrón que
// entitlement.ts/language.ts/word_count.ts en esta carpeta). No confía en
// que el `responseSchema` haya sido respetado al pie de la letra: si algún
// item no matchea el shape esperado, se trata toda la respuesta como
// inválida en vez de devolver una lista parcialmente corrupta.
export const MENTION_TYPES = ["book", "podcast", "music"] as const;
export type MentionType = (typeof MENTION_TYPES)[number];

export interface RawMention {
  type: MentionType;
  name: string;
}

export function parseMentions(value: unknown): RawMention[] | null {
  if (!Array.isArray(value)) return null;
  const mentions: RawMention[] = [];
  for (const item of value) {
    if (
      typeof item !== "object" || item === null ||
      typeof (item as Record<string, unknown>).name !== "string" ||
      !(MENTION_TYPES as readonly string[]).includes(
        (item as Record<string, unknown>).type as string,
      )
    ) {
      return null;
    }
    mentions.push({
      type: (item as Record<string, unknown>).type as MentionType,
      name: (item as Record<string, unknown>).name as string,
    });
  }
  return mentions;
}
