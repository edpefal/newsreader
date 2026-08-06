import 'package:xml/xml.dart';

import 'package:newsreader/features/sources/domain/usecases/get_sources.dart';

/// Genera un OPML válido con las fuentes suscritas del usuario, para que
/// pueda conservarlas o migrarlas independientemente de la app (ver
/// capability `data-export`). Se apoya en `xml` para el escape correcto de
/// caracteres especiales en nombre y URL, la misma librería ya usada para
/// parsear OPML en el flujo de import.
class ExportSourcesOpml {
  final GetSources _getSources;

  const ExportSourcesOpml(this._getSources);

  Future<String> execute() async {
    final sources = await _getSources.execute();

    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('opml', attributes: {'version': '2.0'}, nest: () {
      builder.element('head', nest: () {
        builder.element('title', nest: 'Fuentes exportadas de Reevo');
      });
      builder.element('body', nest: () {
        for (final source in sources) {
          builder.element('outline', attributes: {
            'type': 'rss',
            'text': source.name,
            'title': source.name,
            'xmlUrl': source.feedUrl,
          });
        }
      });
    });

    return builder.buildDocument().toXmlString(pretty: true);
  }
}
