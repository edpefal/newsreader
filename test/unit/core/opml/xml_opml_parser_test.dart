import 'package:flutter_test/flutter_test.dart';
import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/opml/xml_opml_parser.dart';

void main() {
  const parser = XmlOpmlParser();

  group('XmlOpmlParser', () {
    test('extrae xmlUrl de feeds directos en el body', () {
      const opml = '''
<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <head><title>Test</title></head>
  <body>
    <outline type="rss" text="Feed A" xmlUrl="https://a.com/feed"/>
    <outline type="rss" text="Feed B" xmlUrl="https://b.com/feed"/>
  </body>
</opml>''';

      final urls = parser.parse(opml);

      expect(urls, ['https://a.com/feed', 'https://b.com/feed']);
    });

    test('extrae xmlUrl de feeds anidados en carpetas', () {
      const opml = '''
<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <head><title>Test</title></head>
  <body>
    <outline text="Tech">
      <outline type="rss" text="TechCrunch" xmlUrl="https://techcrunch.com/feed/"/>
      <outline type="rss" text="Hacker News" xmlUrl="https://news.ycombinator.com/rss"/>
    </outline>
    <outline type="rss" text="Direct" xmlUrl="https://direct.com/feed"/>
  </body>
</opml>''';

      final urls = parser.parse(opml);

      expect(urls, [
        'https://techcrunch.com/feed/',
        'https://news.ycombinator.com/rss',
        'https://direct.com/feed',
      ]);
    });

    test('retorna lista vacía si no hay outlines con xmlUrl', () {
      const opml = '''
<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <head><title>Empty</title></head>
  <body>
    <outline text="Folder with no feeds"/>
  </body>
</opml>''';

      final urls = parser.parse(opml);

      expect(urls, isEmpty);
    });

    test('lanza ParseException con XML inválido', () {
      expect(
        () => parser.parse('esto no es xml válido <<<'),
        throwsA(isA<ParseException>()),
      );
    });

    test('ignora outlines sin xmlUrl y extrae los que sí tienen', () {
      const opml = '''
<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <body>
    <outline text="Folder"/>
    <outline type="rss" text="Valid" xmlUrl="https://valid.com/feed"/>
    <outline type="rss" text="NoUrl"/>
  </body>
</opml>''';

      final urls = parser.parse(opml);

      expect(urls, ['https://valid.com/feed']);
    });
  });
}
