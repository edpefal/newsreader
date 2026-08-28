final _scriptOrStyleBlock = RegExp(
  r'<(script|style)\b[^>]*>.*?</\1>',
  caseSensitive: false,
  dotAll: true,
);

final _anchorTag = RegExp(
  r'''<a\b[^>]*?href\s*=\s*(["'])(.*?)\1[^>]*>(.*?)</a>''',
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

/// Convierte HTML a texto plano igual que `HtmlToPlainText`, pero preserva
/// cada `<a href="url">texto</a>` como `[texto](url)` en vez de perder el
/// link -- necesario para que `summarize-article` pueda detectar menciones
/// de tipo artículo (ver capability `article-mentions`). No reemplaza a
/// `HtmlToPlainText`: `daily-summaries` sigue usando esa, sin links.
class HtmlToLinkedText {
  const HtmlToLinkedText._();

  /// [baseUrl] resuelve los `href` relativos (ej. `/p/algo`) a URLs
  /// absolutas, usando el mismo criterio que `Uri.resolve`. Un `href`
  /// vacío o inválido se trata como si el link no existiera: se conserva
  /// el texto del anchor, sin envolverlo en sintaxis markdown.
  static String convert(String html, {required String baseUrl}) {
    var text = html.replaceAll(_scriptOrStyleBlock, '');

    final base = Uri.tryParse(baseUrl);
    text = text.replaceAllMapped(_anchorTag, (match) {
      final rawUrl = match.group(2)!.trim();
      final innerText = match.group(3)!;
      if (rawUrl.isEmpty) return innerText;
      final resolved = _resolve(base, rawUrl);
      if (resolved == null) return innerText;
      return '[$innerText]($resolved)';
    });

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
      if (codePoint >= 0xD800 && codePoint <= 0xDFFF) return '';
      return String.fromCharCode(codePoint);
    });

    text = text.replaceAll(_trailingSpaces, '\n');
    text = text.replaceAll(_repeatedSpaces, ' ');
    text = text.replaceAll(_blankLines, '\n\n');

    return text.trim();
  }

  static String? _resolve(Uri? base, String rawUrl) {
    try {
      final url = Uri.parse(rawUrl);
      if (base == null) return url.toString();
      return base.resolveUri(url).toString();
    } catch (_) {
      return null;
    }
  }
}
