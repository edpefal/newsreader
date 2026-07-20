final _scriptOrStyleBlock = RegExp(
  r'<(script|style)\b[^>]*>.*?</\1>',
  caseSensitive: false,
  dotAll: true,
);

final _blockTagEnd = RegExp(
  r'<(br\s*/?|/p|/div|/tr|/li|/h[1-6]|/table|/section|/article)\s*>',
  caseSensitive: false,
);

final _anyTag = RegExp(r'<[^>]*>');

final _numericEntity = RegExp(r'&#(\d+);');

final _blankLines = RegExp(r'\n[ \t]*\n[ \t]*(\n[ \t]*)*');

final _trailingSpaces = RegExp(r'[ \t]+\n');

final _repeatedSpaces = RegExp(r'[ \t]{2,}');

const _namedEntities = {
  '&amp;': '&',
  '&nbsp;': ' ',
  '&lt;': '<',
  '&gt;': '>',
  '&quot;': '"',
  '&#39;': "'",
  '&apos;': "'",
};

class HtmlToPlainText {
  const HtmlToPlainText._();

  /// Convierte [html] a texto plano: remueve `<script>`/`<style>`, reemplaza
  /// tags de bloque por saltos de línea, remueve el resto del markup, y
  /// decodifica entidades HTML comunes.
  static String convert(String html) {
    var text = html.replaceAll(_scriptOrStyleBlock, '');
    text = text.replaceAll(_blockTagEnd, '\n');
    text = text.replaceAll(_anyTag, '');

    for (final entry in _namedEntities.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }
    text = text.replaceAllMapped(_numericEntity, (match) {
      final codePoint = int.tryParse(match.group(1)!);
      if (codePoint == null || codePoint < 0 || codePoint > 0x10FFFF) {
        return '';
      }
      // Surrogates aislados (0xD800-0xDFFF) no son un scalar value válido por
      // sí solos: algunos feeds mal codificados los emiten como dos
      // entidades numéricas separadas para un mismo emoji. Descartarlos
      // evita producir un string mal formado en UTF-16 que rompe al
      // serializar el request más adelante.
      if (codePoint >= 0xD800 && codePoint <= 0xDFFF) return '';
      return String.fromCharCode(codePoint);
    });

    text = text.replaceAll(_trailingSpaces, '\n');
    text = text.replaceAll(_repeatedSpaces, ' ');
    text = text.replaceAll(_blankLines, '\n\n');

    return text.trim();
  }
}
