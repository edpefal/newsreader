import 'package:flutter_test/flutter_test.dart';
import 'package:newsreader/core/feed/feed_url_resolver.dart';

void main() {
  late FeedUrlResolver resolver;

  setUp(() {
    resolver = FeedUrlResolver();
  });

  group('FeedUrlResolver', () {
    test('Substack: URL de home agrega candidato /feed', () {
      final candidates = resolver.candidatesFor('https://autor.substack.com');

      expect(candidates, [
        'https://autor.substack.com',
        'https://autor.substack.com/feed',
      ]);
    });

    test('Substack: URL de artículo agrega candidato /feed sobre el origin', () {
      final candidates =
          resolver.candidatesFor('https://autor.substack.com/p/mi-articulo');

      expect(candidates, [
        'https://autor.substack.com/p/mi-articulo',
        'https://autor.substack.com/feed',
      ]);
    });

    test('Beehiiv: no genera candidato heurístico (feed sin ruta fija)', () {
      final candidates = resolver.candidatesFor('https://autor.beehiiv.com');

      expect(candidates, ['https://autor.beehiiv.com']);
    });

    test('WordPress.com: URL de home agrega candidato /feed/', () {
      final candidates =
          resolver.candidatesFor('https://autor.wordpress.com');

      expect(candidates, [
        'https://autor.wordpress.com',
        'https://autor.wordpress.com/feed/',
      ]);
    });

    test('WordPress.com: URL de post agrega candidato /feed/ sobre el origin',
        () {
      final candidates = resolver
          .candidatesFor('https://autor.wordpress.com/2024/01/01/algun-post');

      expect(candidates, [
        'https://autor.wordpress.com/2024/01/01/algun-post',
        'https://autor.wordpress.com/feed/',
      ]);
    });

    test('Ghost Pro: URL de home agrega candidato /rss/', () {
      final candidates = resolver.candidatesFor('https://autor.ghost.io');

      expect(candidates, [
        'https://autor.ghost.io',
        'https://autor.ghost.io/rss/',
      ]);
    });

    test('Ghost Pro: URL de artículo agrega candidato /rss/ sobre el origin',
        () {
      final candidates =
          resolver.candidatesFor('https://autor.ghost.io/algun-articulo');

      expect(candidates, [
        'https://autor.ghost.io/algun-articulo',
        'https://autor.ghost.io/rss/',
      ]);
    });

    test('host no reconocido devuelve únicamente la URL original', () {
      final candidates =
          resolver.candidatesFor('https://www.readtangle.com/algun-post');

      expect(candidates, ['https://www.readtangle.com/algun-post']);
    });

    test('URL que ya es un feed exacto sigue siendo el primer candidato', () {
      final candidates =
          resolver.candidatesFor('https://autor.substack.com/feed');

      expect(candidates, [
        'https://autor.substack.com/feed',
      ]);
    });

    test('Substack: perfil substack.com/@usuario agrega candidato de subdominio',
        () {
      final candidates =
          resolver.candidatesFor('https://substack.com/@ederperez');

      expect(candidates, [
        'https://substack.com/@ederperez',
        'https://ederperez.substack.com/feed',
      ]);
    });

    test('Substack: perfil con www.substack.com también se reconoce', () {
      final candidates =
          resolver.candidatesFor('https://www.substack.com/@ederperez');

      expect(candidates, [
        'https://www.substack.com/@ederperez',
        'https://ederperez.substack.com/feed',
      ]);
    });

    test('substack.com sin @usuario en el path no genera candidato', () {
      final candidates = resolver.candidatesFor('https://substack.com/discover');

      expect(candidates, ['https://substack.com/discover']);
    });
  });
}
