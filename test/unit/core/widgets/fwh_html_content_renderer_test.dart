import 'dart:io';

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

  group('looksLikeRawEmailHtml', () {
    test('detecta el fixture real de email crudo (Morning Brew)', () {
      final html = File(
        'test/fixtures/newsletter_nested_tables.html',
      ).readAsStringSync();

      expect(looksLikeRawEmailHtml(html), isTrue);
    });

    test('detecta el namespace VML de Outlook por sí solo', () {
      const html =
          '<html xmlns:v="urn:schemas-microsoft-com:vml"><body>x</body></html>';

      expect(looksLikeRawEmailHtml(html), isTrue);
    });

    test('detecta el namespace de Office por sí solo', () {
      const html =
          '<html xmlns:o="urn:schemas-microsoft-com:office:office"><body>x</body></html>';

      expect(looksLikeRawEmailHtml(html), isTrue);
    });

    test('no detecta HTML de blog/web típico', () {
      const html =
          '<div><h2>Título</h2><p>Un párrafo con <a href="https://x.com">un link</a>.</p></div>';

      expect(looksLikeRawEmailHtml(html), isFalse);
    });

    test('no detecta HTML vacío', () {
      expect(looksLikeRawEmailHtml(''), isFalse);
    });

    test(
      'detecta anidamiento profundo de tablas sin marcas VML/Office '
      '(caso Daily Stoic: mismo crash, otro ESP)',
      () {
        final nested = '${'<table>' * 5}x${'</table>' * 5}';

        expect(looksLikeRawEmailHtml(nested), isTrue);
      },
    );

    test('no marca tablas de datos con poco anidamiento como email crudo', () {
      const html = '<table><tr><td>'
          '<table><tr><td>celda anidada</td></tr></table>'
          '</td></tr></table>';

      expect(looksLikeRawEmailHtml(html), isFalse);
    });
  });

  group('maxTableNestingDepth', () {
    test('retorna 0 sin tablas', () {
      expect(maxTableNestingDepth('<p>sin tablas</p>'), 0);
    });

    test('cuenta la profundidad máxima de tablas anidadas', () {
      final nested = '${'<table>' * 3}x${'</table>' * 3}';

      expect(maxTableNestingDepth(nested), 3);
    });

    test('no se confunde con tablas hermanas (no anidadas)', () {
      const html = '<table></table><table></table>';

      expect(maxTableNestingDepth(html), 1);
    });

    test('ignora cierres de más sin romper (HTML mal formado)', () {
      const html = '</table><table>x</table>';

      expect(maxTableNestingDepth(html), 1);
    });
  });

  group('ensureViewportMeta', () {
    test('inserta la etiqueta viewport justo después de <head>', () {
      const html = '<html><head><title>x</title></head><body>x</body></html>';

      final result = ensureViewportMeta(html);

      expect(
        result,
        '<html><head>'
        '<meta name="viewport" content="width=device-width, initial-scale=1.0">'
        '<title>x</title></head><body>x</body></html>',
      );
    });

    test('antepone la etiqueta viewport si no hay <head>', () {
      const html = '<body>x</body>';

      final result = ensureViewportMeta(html);

      expect(
        result,
        '<meta name="viewport" content="width=device-width, initial-scale=1.0">'
        '<body>x</body>',
      );
    });

    test('no toca el HTML si ya trae su propia etiqueta viewport', () {
      const html = '<html><head>'
          '<meta name="viewport" content="width=600">'
          '</head><body>x</body></html>';

      expect(ensureViewportMeta(html), html);
    });

    test('detecta la etiqueta viewport con comillas simples', () {
      const html = "<head><meta name='viewport' content='width=600'></head>";

      expect(ensureViewportMeta(html), html);
    });
  });

  group('stripScriptExecutionVectors', () {
    test('quita un bloque <script>...</script> completo', () {
      const html = '<p>antes</p><script>alert(1)</script><p>después</p>';

      expect(
        stripScriptExecutionVectors(html),
        '<p>antes</p><p>después</p>',
      );
    });

    test('quita un <script> con atributos (src, type, etc.)', () {
      const html = '<script type="text/javascript" src="evil.js"></script>'
          '<p>hola</p>';

      expect(stripScriptExecutionVectors(html), '<p>hola</p>');
    });

    test('quita un <script> multilínea', () {
      const html = '<script>\n  alert(1);\n  alert(2);\n</script><p>x</p>';

      expect(stripScriptExecutionVectors(html), '<p>x</p>');
    });

    test('detecta <script> sin importar mayúsculas/minúsculas', () {
      const html = '<SCRIPT>alert(1)</SCRIPT><p>x</p>';

      expect(stripScriptExecutionVectors(html), '<p>x</p>');
    });

    test('un <script> sin cerrar descarta todo lo que sigue, igual que un '
        'parser HTML real', () {
      const html = '<p>antes</p><script>alert(1)';

      expect(stripScriptExecutionVectors(html), '<p>antes</p>');
    });

    test('quita atributos onclick/onload/onerror con comillas dobles', () {
      const html = '<img src="x.png" onerror="alert(1)">'
          '<button onclick="alert(2)">x</button>'
          '<body onload="alert(3)">';

      final result = stripScriptExecutionVectors(html);

      expect(result, isNot(contains('onerror')));
      expect(result, isNot(contains('onclick')));
      expect(result, isNot(contains('onload')));
      expect(result, contains('<img src="x.png">'));
    });

    test('quita atributos de evento con comillas simples y sin comillas', () {
      const html = "<div onmouseover='alert(1)'>x</div>"
          '<div onfocus=alert(2)>y</div>';

      final result = stripScriptExecutionVectors(html);

      expect(result, isNot(contains('onmouseover')));
      expect(result, isNot(contains('onfocus')));
    });

    test('neutraliza el esquema javascript: en href', () {
      const html = '<a href="javascript:alert(1)">click</a>';

      final result = stripScriptExecutionVectors(html);

      expect(result, isNot(contains('javascript:')));
      expect(result, contains('href="'));
    });

    test('neutraliza el esquema vbscript: en src', () {
      const html = '<img src="vbscript:msgbox(1)">';

      expect(stripScriptExecutionVectors(html), isNot(contains('vbscript:')));
    });

    test('no toca HTML/CSS/atributos normales de un newsletter real', () {
      const html = '<table width="600" style="color:#000">'
          '<tr><td><img src="https://x.com/logo.png" alt="Logo"></td></tr>'
          '<tr><td><a href="https://x.com/articulo">Leer más</a></td></tr>'
          '</table>';

      expect(stripScriptExecutionVectors(html), html);
    });
  });
}
