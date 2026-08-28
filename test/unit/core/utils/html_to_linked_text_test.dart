import 'package:flutter_test/flutter_test.dart';
import 'package:newsreader/core/utils/html_to_linked_text.dart';

void main() {
  group('HtmlToLinkedText.convert', () {
    const baseUrl = 'https://newsletter.example.com/p/current-article';

    test('preserva un link absoluto como markdown', () {
      const html = '<p>Mirá <a href="https://other.example.com/post">este artículo</a>.</p>';
      final result = HtmlToLinkedText.convert(html, baseUrl: baseUrl);
      expect(result, 'Mirá [este artículo](https://other.example.com/post).');
    });

    test('resuelve un link relativo contra baseUrl', () {
      const html = '<p>Ver <a href="/p/otro-articulo">la nota anterior</a>.</p>';
      final result = HtmlToLinkedText.convert(html, baseUrl: baseUrl);
      expect(
        result,
        'Ver [la nota anterior](https://newsletter.example.com/p/otro-articulo).',
      );
    });

    test('un href vacío deja el texto plano, sin sintaxis markdown', () {
      const html = '<p>Un <a href="">link roto</a> en el medio.</p>';
      final result = HtmlToLinkedText.convert(html, baseUrl: baseUrl);
      expect(result, 'Un link roto en el medio.');
    });

    test('preserva varios links distintos en el mismo artículo', () {
      const html =
          '<p><a href="https://a.example.com">A</a> y <a href="https://b.example.com">B</a></p>';
      final result = HtmlToLinkedText.convert(html, baseUrl: baseUrl);
      expect(result, '[A](https://a.example.com) y [B](https://b.example.com)');
    });

    test('un link con tags anidados adentro conserva solo el texto', () {
      const html = '<a href="https://other.example.com/post"><strong>Título</strong></a>';
      final result = HtmlToLinkedText.convert(html, baseUrl: baseUrl);
      expect(result, '[Título](https://other.example.com/post)');
    });

    test('artículo sin ningún link se comporta igual que HtmlToPlainText', () {
      const html = '<p>Primer párrafo.</p><p>Segundo párrafo.</p>';
      final result = HtmlToLinkedText.convert(html, baseUrl: baseUrl);
      expect(result, 'Primer párrafo.\nSegundo párrafo.');
    });

    test('remueve bloques <script> y <style> completos', () {
      const html = '''
        <style>body { color: red; }</style>
        <p>Contenido visible.</p>
        <script>console.log("no visible");</script>
      ''';
      final result = HtmlToLinkedText.convert(html, baseUrl: baseUrl);
      expect(result, 'Contenido visible.');
    });

    test('string vacío devuelve string vacío', () {
      expect(HtmlToLinkedText.convert('', baseUrl: baseUrl), '');
    });
  });
}
