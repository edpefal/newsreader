/// Un bloque parseado de `DailySummary.content`: [title] es el nombre de
/// fuente (línea inicial del bloque) cuando se pudo identificar, `null` si
/// el bloque no sigue el formato esperado (fallback sin negrita).
class ParsedSummaryBlock {
  final String? title;
  final String text;

  const ParsedSummaryBlock({this.title, required this.text});
}

List<ParsedSummaryBlock> parseSummaryBlocks(String content) {
  final rawBlocks = content
      .trim()
      .split(RegExp(r'\n\s*\n'))
      .map((b) => b.trim())
      .where((b) => b.isNotEmpty)
      .toList();

  return rawBlocks.map((raw) {
    final newlineIndex = raw.indexOf('\n');
    if (newlineIndex == -1) return ParsedSummaryBlock(text: raw);

    final title = raw.substring(0, newlineIndex).trim();
    final rest = raw.substring(newlineIndex + 1).trim();
    if (title.isEmpty || rest.isEmpty) return ParsedSummaryBlock(text: raw);

    return ParsedSummaryBlock(title: title, text: rest);
  }).toList();
}
