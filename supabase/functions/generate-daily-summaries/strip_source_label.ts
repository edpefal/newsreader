// Gemini a veces copia al texto generado el rótulo `Fuente: <nombre>` con el
// que `buildPrompt` agrupa las entradas, aunque la instrucción de salida le
// pide escribir solo el nombre. El cliente identifica a qué fuente pertenece
// cada bloque por la primera línea del texto (ver capability
// `daily-summaries`, "El encabezado de cada fuente en el texto generado es
// solo el nombre de la fuente"), así que con la etiqueta delante no hay
// emparejamiento y se pierden los links a los artículos.
//
// Cubre `Fuente:` (es), `Source:` (en) y `Source :` (fr). Mantener en
// sincronía con `lib/features/summaries/domain/summary_block_title.dart`.
const SOURCE_LABEL_PREFIX = /^\s*(?:fuente|source)\s*:\s*/i;

/**
 * Quita la etiqueta de la primera línea de cada bloque (separados por línea
 * en blanco) solo cuando lo que queda es exactamente el nombre de una de
 * [knownSourceNames]. No toca nada más: ni párrafos, ni bloques sin etiqueta,
 * ni una fuente cuyo nombre real ya empieza con la etiqueta.
 */
export function stripSourceLabels(
  text: string,
  knownSourceNames: string[],
): string {
  if (knownSourceNames.length === 0) return text;
  const known = new Set(knownSourceNames.map((n) => n.trim()));

  // El grupo de captura conserva los separadores (índices impares) para
  // reconstruir el texto con la misma separación que traía.
  const parts = text.split(/(\n\s*\n)/);
  return parts
    .map((part, i) => (i % 2 === 1 ? part : stripBlock(part, known)))
    .join("");
}

function stripBlock(block: string, known: Set<string>): string {
  const newlineIndex = block.indexOf("\n");
  const firstLine = newlineIndex === -1 ? block : block.slice(0, newlineIndex);
  const rest = newlineIndex === -1 ? "" : block.slice(newlineIndex);

  if (!SOURCE_LABEL_PREFIX.test(firstLine)) return block;
  if (known.has(firstLine.trim())) return block;

  const name = firstLine.replace(SOURCE_LABEL_PREFIX, "").trim();
  if (name.length === 0 || !known.has(name)) return block;

  return name + rest;
}
