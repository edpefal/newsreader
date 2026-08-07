import 'package:html/parser.dart' as html_parser;

/// Extrae la URL de feed que un sitio declara en su propio HTML vía
/// `<link rel="alternate" type="application/rss+xml|atom+xml">` — el
/// mecanismo estándar de auto-descubrimiento de feeds. Usado como último
/// recurso cuando ningún sufijo genérico ni caso de inserción de plataforma
/// resultó en un feed válido (ver `FeedUrlResolver`).
class HtmlFeedLinkExtractor {
  static const _feedTypes = {'application/rss+xml', 'application/atom+xml'};

  /// Devuelve la URL de feed declarada en [html] (resuelta contra
  /// [baseUri] si es relativa), o `null` si no encuentra ningún
  /// `<link rel="alternate">` de tipo RSS/Atom. `package:html` es
  /// tolerante a HTML malformado o incompleto -- nunca lanza excepción,
  /// en el peor caso no encuentra ningún link.
  static String? extract(String html, Uri baseUri) {
    final document = html_parser.parse(html);
    final links = document.querySelectorAll('link');

    for (final link in links) {
      final rel = link.attributes['rel']?.trim().toLowerCase();
      final type = link.attributes['type']?.trim().toLowerCase();
      final href = link.attributes['href'];

      if (rel != 'alternate') continue;
      if (type == null || !_feedTypes.contains(type)) continue;
      if (href == null || href.isEmpty) continue;

      return baseUri.resolve(href).toString();
    }

    return null;
  }
}
