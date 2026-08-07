import 'package:flutter_test/flutter_test.dart';
import 'package:newsreader/core/feed/html_feed_link_extractor.dart';

void main() {
  group('HtmlFeedLinkExtractor', () {
    test('href relativo se resuelve contra la baseUri (caso simonwillison.net)',
        () {
      const html = '''
        <html><head>
          <link rel="alternate" type="application/atom+xml" title="Atom" href="/atom/everything/">
        </head><body></body></html>
      ''';

      final result = HtmlFeedLinkExtractor.extract(
        html,
        Uri.parse('https://simonwillison.net'),
      );

      expect(result, 'https://simonwillison.net/atom/everything/');
    });

    test('href absoluto se devuelve tal cual', () {
      const html = '''
        <html><head>
          <link rel="alternate" type="application/rss+xml" href="https://otro-dominio.com/feed.xml">
        </head></html>
      ''';

      final result = HtmlFeedLinkExtractor.extract(
        html,
        Uri.parse('https://simonwillison.net'),
      );

      expect(result, 'https://otro-dominio.com/feed.xml');
    });

    test('sin ningún link declarado devuelve null', () {
      const html = '<html><head><title>Sin feed</title></head></html>';

      final result =
          HtmlFeedLinkExtractor.extract(html, Uri.parse('https://x.com'));

      expect(result, isNull);
    });

    test('con varios links, toma el primero que matchee RSS o Atom', () {
      const html = '''
        <html><head>
          <link rel="stylesheet" href="/style.css">
          <link rel="alternate" type="application/rss+xml" href="/rss-primero.xml">
          <link rel="alternate" type="application/atom+xml" href="/atom-segundo.xml">
        </head></html>
      ''';

      final result =
          HtmlFeedLinkExtractor.extract(html, Uri.parse('https://x.com'));

      expect(result, 'https://x.com/rss-primero.xml');
    });

    test('atributos en distinto orden y mayúsculas/minúsculas', () {
      const html = '''
        <html><head>
          <link href="/feed.xml" TYPE="Application/RSS+XML" REL="Alternate">
        </head></html>
      ''';

      final result =
          HtmlFeedLinkExtractor.extract(html, Uri.parse('https://x.com'));

      expect(result, 'https://x.com/feed.xml');
    });

    test('HTML sin <head> ni estructura no lanza excepción, devuelve null', () {
      const html = 'esto ni siquiera es HTML válido <<<>>>';

      expect(
        () => HtmlFeedLinkExtractor.extract(html, Uri.parse('https://x.com')),
        returnsNormally,
      );
      expect(
        HtmlFeedLinkExtractor.extract(html, Uri.parse('https://x.com')),
        isNull,
      );
    });

    test('link con rel="alternate" pero sin type no matchea', () {
      const html = '''
        <html><head>
          <link rel="alternate" href="/no-tiene-type.xml">
        </head></html>
      ''';

      final result =
          HtmlFeedLinkExtractor.extract(html, Uri.parse('https://x.com'));

      expect(result, isNull);
    });

    test('link con type de feed pero sin rel="alternate" no matchea', () {
      const html = '''
        <html><head>
          <link type="application/rss+xml" href="/tampoco.xml">
        </head></html>
      ''';

      final result =
          HtmlFeedLinkExtractor.extract(html, Uri.parse('https://x.com'));

      expect(result, isNull);
    });
  });
}
