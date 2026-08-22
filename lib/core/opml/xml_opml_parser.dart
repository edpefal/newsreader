import 'package:xml/xml.dart';

import 'package:newsreader/core/errors/app_error_code.dart';
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
    } catch (_) {
      // No se reporta a observabilidad a propósito: un OPML mal formado es
      // input del usuario, no un bug (ver design.md de
      // add-observability-provider, sección 4).
      throw const ParseException(AppErrorCode.invalidOpmlFile);
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
