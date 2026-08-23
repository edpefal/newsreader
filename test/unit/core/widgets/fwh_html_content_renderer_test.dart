import 'package:flutter_test/flutter_test.dart';

import 'package:newsreader/core/widgets/fwh_html_content_renderer.dart';

void main() {
  group('normalizeYoutubeUrl', () {
    test('quita el parámetro origin de una URL /embed/<id>', () {
      final result = normalizeYoutubeUrl(
        'https://www.youtube.com/embed/VIDEO_ID?origin=https://sitio-original.com',
      );

      expect(result, 'https://www.youtube.com/embed/VIDEO_ID');
    });

    test('convierte el formato deprecado /v/<id> a /embed/<id>', () {
      final result = normalizeYoutubeUrl(
        'https://www.youtube.com/v/VIDEO_ID',
      );

      expect(result, 'https://www.youtube.com/embed/VIDEO_ID');
    });

    test('convierte un link corto youtu.be/<id> a /embed/<id>', () {
      final result = normalizeYoutubeUrl('https://youtu.be/VIDEO_ID');

      expect(result, 'https://www.youtube.com/embed/VIDEO_ID');
    });

    test('conserva otros parámetros de query que no sean origin', () {
      final result = normalizeYoutubeUrl(
        'https://www.youtube.com/embed/VIDEO_ID?origin=https://x.com&autoplay=1',
      );

      expect(result, 'https://www.youtube.com/embed/VIDEO_ID?autoplay=1');
    });

    test('retorna null para una URL de un dominio que no es YouTube', () {
      final result = normalizeYoutubeUrl(
        'https://open.spotify.com/embed/episode/abc123',
      );

      expect(result, isNull);
    });

    test('retorna null para una URL de YouTube sin videoId reconocible', () {
      final result = normalizeYoutubeUrl('https://www.youtube.com/');

      expect(result, isNull);
    });
  });

  group('stripInlineTextColors', () {
    test('quita la declaración color de un style inline en un link', () {
      final result = stripInlineTextColors(
        '<a href="https://x.com" style="color:#1a73e8; font-weight:bold">x</a>',
      );

      expect(result, contains('font-weight:bold'));
      expect(result, isNot(contains('color:#1a73e8')));
      expect(result, isNot(contains('color: #1a73e8')));
    });

    test('quita el atributo color deprecado', () {
      final result = stripInlineTextColors(
        '<a href="https://x.com" color="blue">x</a>',
      );

      expect(result, isNot(contains('color="blue"')));
    });

    test('remueve el atributo style por completo si solo tenía color', () {
      final result = stripInlineTextColors(
        '<a href="https://x.com" style="color:blue">x</a>',
      );

      expect(result, isNot(contains('style=')));
    });

    test('no toca links sin estilo inline', () {
      final result = stripInlineTextColors('<a href="https://x.com">x</a>');

      expect(result, contains('href="https://x.com"'));
    });

    test('quita el color inline de elementos que no son links', () {
      final result = stripInlineTextColors(
        '<p style="color:#666666">descripción</p>',
      );

      expect(result, isNot(contains('color:#666666')));
    });

    test('conserva background-color al quitar color', () {
      final result = stripInlineTextColors(
        '<span style="color:red; background-color:yellow">x</span>',
      );

      expect(result, contains('background-color:yellow'));
      expect(result, isNot(contains('color:red')));
    });

    test('no altera la estructura ni los atributos de dimensión de un iframe', () {
      const html =
          '<p>texto</p><iframe width="560" height="315" src="https://www.youtube.com/embed/x"></iframe><p style="color:blue">otro</p>';

      final result = stripInlineTextColors(html);

      // El espacio sobrante donde estaba `style=` es válido en HTML
      // (`<p >`) y no afecta el parseo -- lo que importa es que el
      // <iframe> y sus atributos de dimensión queden intactos, byte a
      // byte, sin pasar por un roundtrip de parseo/re-serializado.
      expect(
        result,
        '<p>texto</p><iframe width="560" height="315" src="https://www.youtube.com/embed/x"></iframe><p >otro</p>',
      );
    });
  });
}
