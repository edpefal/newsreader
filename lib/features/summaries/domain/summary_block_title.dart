/// Etiquetas que el modelo de IA a veces antepone al nombre de la fuente en
/// la primera línea de cada bloque de un `DailySummary` (copia el rótulo
/// `Fuente: <nombre>` con el que se agrupan las entradas del prompt). Cubre
/// `Fuente:` (es), `Source:` (en) y `Source :` (fr, con espacio antes de los
/// dos puntos). Mantener en sincronía con
/// `supabase/functions/generate-daily-summaries/strip_source_label.ts`.
final _sourceLabelPrefix = RegExp(
  r'^(?:fuente|source)\s*:\s*',
  caseSensitive: false,
);

/// Devuelve el nombre de fuente de [title] sin una etiqueta `Fuente:` /
/// `Source:` al inicio. Si [title] no empieza con esa etiqueta, o si al
/// quitarla no quedaría nada, devuelve [title] sin espacios sobrantes.
String normalizeSummaryBlockTitle(String title) {
  final trimmed = title.trim();
  final rest = trimmed.replaceFirst(_sourceLabelPrefix, '').trim();
  return rest.isEmpty ? trimmed : rest;
}
