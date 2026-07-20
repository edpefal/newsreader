import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:newsreader/core/utils/html_to_plain_text.dart';

void main() {
  group('HtmlToPlainText.convert', () {
    test('extrae texto de párrafos simples con saltos de línea', () {
      const html = '<p>Primer párrafo.</p><p>Segundo párrafo.</p>';
      final result = HtmlToPlainText.convert(html);
      expect(result, 'Primer párrafo.\nSegundo párrafo.');
    });

    test('remueve bloques <script> y <style> completos', () {
      const html = '''
        <style>body { color: red; }</style>
        <p>Contenido visible.</p>
        <script>console.log("no visible");</script>
      ''';
      final result = HtmlToPlainText.convert(html);
      expect(result, 'Contenido visible.');
    });

    test('decodifica entidades HTML comunes', () {
      const html = '<p>Tom &amp; Jerry &lt;3 &quot;caf&#233;&quot;</p>';
      final result = HtmlToPlainText.convert(html);
      expect(result, 'Tom & Jerry <3 "café"');
    });

    test('decodifica un code point astral válido (emoji fuera del BMP)', () {
      const html = '<p>Lanzamiento &#128640;</p>'; // U+1F680 ROCKET
      final result = HtmlToPlainText.convert(html);
      expect(result, 'Lanzamiento 🚀');
      expect(() => result.codeUnits, returnsNormally);
    });

    test(
        'descarta entidades numéricas de surrogates aislados sin producir un '
        'string mal formado en UTF-16', () {
      // &#55357; es un high surrogate (0xD83D) aislado: un feed mal
      // codificado puede emitirlo suelto en vez de un code point astral
      // válido. Debe descartarse, no crashear.
      const html = '<p>Roto &#55357; texto</p>';
      expect(() => HtmlToPlainText.convert(html), returnsNormally);
      final result = HtmlToPlainText.convert(html);
      expect(() => utf8.encode(result), returnsNormally);
    });

    test('tolera tags anidados o mal cerrados sin lanzar excepción', () {
      const html = '<div><p>Texto <b>en negrita<i> y cursiva</p></div>';
      expect(() => HtmlToPlainText.convert(html), returnsNormally);
      final result = HtmlToPlainText.convert(html);
      expect(result, 'Texto en negrita y cursiva');
    });

    test('string vacío devuelve string vacío', () {
      expect(HtmlToPlainText.convert(''), '');
    });

    test('HTML sin tags devuelve el texto tal cual', () {
      const html = 'Texto plano sin ningún tag HTML.';
      expect(HtmlToPlainText.convert(html), html);
    });

    test('extrae texto de una estructura de tabla, similar a un newsletter real', () {
      const html = '''
        <table width="100%" cellspacing="0" cellpadding="0">
          <tr>
            <td>
              <p>Bienvenido al newsletter!</p>
            </td>
          </tr>
          <tr>
            <td align="center">
              <a href="https://track.example.com/confirm?id=123">Confirmar</a>
            </td>
          </tr>
        </table>
        <img src="https://track.example.com/open.gif" width="1" height="1" />
      ''';
      final result = HtmlToPlainText.convert(html);
      expect(result, contains('Bienvenido al newsletter!'));
      expect(result, contains('Confirmar'));
      expect(result, isNot(contains('<')));
      expect(result, isNot(contains('track.example.com')));
    });
  });
}
