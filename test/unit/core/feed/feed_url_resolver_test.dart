import 'package:flutter_test/flutter_test.dart';
import 'package:newsreader/core/feed/feed_url_resolver.dart';

void main() {
  late FeedUrlResolver resolver;

  setUp(() {
    resolver = FeedUrlResolver();
  });

  group('FeedUrlResolver', () {
    test('URL sin esquema se normaliza agregando https://', () {
      final candidates = resolver.candidatesFor('stratechery.com');

      expect(candidates, [
        'https://stratechery.com',
        'https://stratechery.com/feed',
        'https://stratechery.com/feed/',
        'https://stratechery.com/rss/',
        'https://stratechery.com/atom.xml',
      ]);
    });

    test('URL sin esquema con path se normaliza preservando el path', () {
      final candidates = resolver.candidatesFor('stratechery.com/algun-post');

      expect(candidates, [
        'https://stratechery.com/algun-post',
        'https://stratechery.com/feed',
        'https://stratechery.com/feed/',
        'https://stratechery.com/rss/',
        'https://stratechery.com/atom.xml',
      ]);
    });

    test('URL con esquema http:// no se modifica', () {
      final candidates = resolver.candidatesFor('http://stratechery.com');

      expect(candidates, [
        'http://stratechery.com',
        'http://stratechery.com/feed',
        'http://stratechery.com/feed/',
        'http://stratechery.com/rss/',
        'http://stratechery.com/atom.xml',
      ]);
    });

    test('Substack en subdominio propio: agrega los sufijos genéricos', () {
      final candidates = resolver.candidatesFor('https://autor.substack.com');

      expect(candidates, [
        'https://autor.substack.com',
        'https://autor.substack.com/feed',
        'https://autor.substack.com/feed/',
        'https://autor.substack.com/rss/',
        'https://autor.substack.com/atom.xml',
      ]);
    });

    test('Substack en dominio propio: agrega los sufijos genéricos igual', () {
      final candidates =
          resolver.candidatesFor('https://stratechery.com/2024/algun-articulo');

      expect(candidates, [
        'https://stratechery.com/2024/algun-articulo',
        'https://stratechery.com/feed',
        'https://stratechery.com/feed/',
        'https://stratechery.com/rss/',
        'https://stratechery.com/atom.xml',
      ]);
    });

    test('Ghost en dominio propio: agrega los sufijos genéricos', () {
      final candidates =
          resolver.candidatesFor('https://blog.miempresa.com/algun-post');

      expect(candidates, [
        'https://blog.miempresa.com/algun-post',
        'https://blog.miempresa.com/feed',
        'https://blog.miempresa.com/feed/',
        'https://blog.miempresa.com/rss/',
        'https://blog.miempresa.com/atom.xml',
      ]);
    });

    test('Beehiiv: no genera candidato de inserción, pero sí sufijos genéricos',
        () {
      final candidates = resolver.candidatesFor('https://autor.beehiiv.com');

      expect(candidates, [
        'https://autor.beehiiv.com',
        'https://autor.beehiiv.com/feed',
        'https://autor.beehiiv.com/feed/',
        'https://autor.beehiiv.com/rss/',
        'https://autor.beehiiv.com/atom.xml',
      ]);
    });

    test('host no reconocido igual recibe los sufijos genéricos', () {
      final candidates =
          resolver.candidatesFor('https://www.readtangle.com/algun-post');

      expect(candidates, [
        'https://www.readtangle.com/algun-post',
        'https://www.readtangle.com/feed',
        'https://www.readtangle.com/feed/',
        'https://www.readtangle.com/rss/',
        'https://www.readtangle.com/atom.xml',
      ]);
    });

    test('URL que ya es un feed exacto no duplica ese mismo candidato', () {
      final candidates =
          resolver.candidatesFor('https://autor.substack.com/feed');

      expect(candidates, [
        'https://autor.substack.com/feed',
        'https://autor.substack.com/feed/',
        'https://autor.substack.com/rss/',
        'https://autor.substack.com/atom.xml',
      ]);
    });

    test('Substack: perfil substack.com/@usuario agrega candidato de subdominio',
        () {
      final candidates =
          resolver.candidatesFor('https://substack.com/@ederperez');

      expect(candidates, [
        'https://substack.com/@ederperez',
        'https://ederperez.substack.com/feed',
        'https://substack.com/feed',
        'https://substack.com/feed/',
        'https://substack.com/rss/',
        'https://substack.com/atom.xml',
      ]);
    });

    test('Substack: perfil con www.substack.com también se reconoce', () {
      final candidates =
          resolver.candidatesFor('https://www.substack.com/@ederperez');

      expect(candidates, [
        'https://www.substack.com/@ederperez',
        'https://ederperez.substack.com/feed',
        'https://www.substack.com/feed',
        'https://www.substack.com/feed/',
        'https://www.substack.com/rss/',
        'https://www.substack.com/atom.xml',
      ]);
    });

    test('substack.com sin @usuario en el path no genera candidato de inserción',
        () {
      final candidates = resolver.candidatesFor('https://substack.com/discover');

      expect(candidates, [
        'https://substack.com/discover',
        'https://substack.com/feed',
        'https://substack.com/feed/',
        'https://substack.com/rss/',
        'https://substack.com/atom.xml',
      ]);
    });

    test('Medium: perfil medium.com/@usuario inserta /feed antes del path',
        () {
      final candidates =
          resolver.candidatesFor('https://medium.com/@ederperez');

      expect(candidates, [
        'https://medium.com/@ederperez',
        'https://medium.com/feed/@ederperez',
        'https://medium.com/feed',
        'https://medium.com/feed/',
        'https://medium.com/rss/',
        'https://medium.com/atom.xml',
      ]);
    });

    test('Medium: publicación medium.com/<slug> inserta /feed antes del path',
        () {
      final candidates = resolver
          .candidatesFor('https://medium.com/una-publicacion/algun-articulo');

      expect(candidates, [
        'https://medium.com/una-publicacion/algun-articulo',
        'https://medium.com/feed/una-publicacion',
        'https://medium.com/feed',
        'https://medium.com/feed/',
        'https://medium.com/rss/',
        'https://medium.com/atom.xml',
      ]);
    });

    test('Medium: subdominio propio no necesita inserción, sufijo genérico alcanza',
        () {
      final candidates = resolver.candidatesFor('https://ederperez.medium.com');

      expect(candidates, [
        'https://ederperez.medium.com',
        'https://ederperez.medium.com/feed',
        'https://ederperez.medium.com/feed/',
        'https://ederperez.medium.com/rss/',
        'https://ederperez.medium.com/atom.xml',
      ]);
    });

    test('medium.com sin path no genera candidato de inserción', () {
      final candidates = resolver.candidatesFor('https://medium.com');

      expect(candidates, [
        'https://medium.com',
        'https://medium.com/feed',
        'https://medium.com/feed/',
        'https://medium.com/rss/',
        'https://medium.com/atom.xml',
      ]);
    });
  });
}
