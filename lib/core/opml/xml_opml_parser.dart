import 'package:xml/xml.dart';

import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/opml/opml_parser.dart';

class XmlOpmlParser implements OPMLParser {
  const XmlOpmlParser();

  @override
  List<String> parse(String xmlContent) {
    try {
      final document = XmlDocument.parse(xmlContent);
      final urls = <String>[];
      _collectUrls(document.rootElement, urls);
      return urls;
    } on XmlException catch (e) {
      throw ParseException('El archivo no es un OPML válido: ${e.message}');
    } catch (_) {
      throw const ParseException('El archivo no es un OPML válido');
    }
  }

  void _collectUrls(XmlElement element, List<String> urls) {
    for (final child in element.childElements) {
      final xmlUrl = child.getAttribute('xmlUrl');
      if (xmlUrl != null && xmlUrl.isNotEmpty) {
        urls.add(xmlUrl.trim());
      }
      _collectUrls(child, urls);
    }
  }
}
