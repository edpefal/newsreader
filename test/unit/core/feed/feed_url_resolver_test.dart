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
        'https://stratechery.com/rss.xml',
        'https://stratechery.com/feed.xml',
        'https://stratechery.com/index.xml',
        'https://www.stratechery.com/feed',
        'https://www.stratechery.com/feed/',
        'https://www.stratechery.com/rss/',
        'https://www.stratechery.com/atom.xml',
        'https://www.stratechery.com/rss.xml',
        'https://www.stratechery.com/feed.xml',
        'https://www.stratechery.com/index.xml',
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
        'https://stratechery.com/rss.xml',
        'https://stratechery.com/feed.xml',
        'https://stratechery.com/index.xml',
        'https://www.stratechery.com/feed',
        'https://www.stratechery.com/feed/',
        'https://www.stratechery.com/rss/',
        'https://www.stratechery.com/atom.xml',
        'https://www.stratechery.com/rss.xml',
        'https://www.stratechery.com/feed.xml',
        'https://www.stratechery.com/index.xml',
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
        'http://stratechery.com/rss.xml',
        'http://stratechery.com/feed.xml',
        'http://stratechery.com/index.xml',
        'http://www.stratechery.com/feed',
        'http://www.stratechery.com/feed/',
        'http://www.stratechery.com/rss/',
        'http://www.stratechery.com/atom.xml',
        'http://www.stratechery.com/rss.xml',
        'http://www.stratechery.com/feed.xml',
        'http://www.stratechery.com/index.xml',
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
        'https://autor.substack.com/rss.xml',
        'https://autor.substack.com/feed.xml',
        'https://autor.substack.com/index.xml',
        'https://www.autor.substack.com/feed',
        'https://www.autor.substack.com/feed/',
        'https://www.autor.substack.com/rss/',
        'https://www.autor.substack.com/atom.xml',
        'https://www.autor.substack.com/rss.xml',
        'https://www.autor.substack.com/feed.xml',
        'https://www.autor.substack.com/index.xml',
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
        'https://stratechery.com/rss.xml',
        'https://stratechery.com/feed.xml',
        'https://stratechery.com/index.xml',
        'https://www.stratechery.com/feed',
        'https://www.stratechery.com/feed/',
        'https://www.stratechery.com/rss/',
        'https://www.stratechery.com/atom.xml',
        'https://www.stratechery.com/rss.xml',
        'https://www.stratechery.com/feed.xml',
        'https://www.stratechery.com/index.xml',
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
        'https://blog.miempresa.com/rss.xml',
        'https://blog.miempresa.com/feed.xml',
        'https://blog.miempresa.com/index.xml',
        'https://www.blog.miempresa.com/feed',
        'https://www.blog.miempresa.com/feed/',
        'https://www.blog.miempresa.com/rss/',
        'https://www.blog.miempresa.com/atom.xml',
        'https://www.blog.miempresa.com/rss.xml',
        'https://www.blog.miempresa.com/feed.xml',
        'https://www.blog.miempresa.com/index.xml',
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
        'https://autor.beehiiv.com/rss.xml',
        'https://autor.beehiiv.com/feed.xml',
        'https://autor.beehiiv.com/index.xml',
        'https://www.autor.beehiiv.com/feed',
        'https://www.autor.beehiiv.com/feed/',
        'https://www.autor.beehiiv.com/rss/',
        'https://www.autor.beehiiv.com/atom.xml',
        'https://www.autor.beehiiv.com/rss.xml',
        'https://www.autor.beehiiv.com/feed.xml',
        'https://www.autor.beehiiv.com/index.xml',
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
        'https://www.readtangle.com/rss.xml',
        'https://www.readtangle.com/feed.xml',
        'https://www.readtangle.com/index.xml',
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
        'https://autor.substack.com/rss.xml',
        'https://autor.substack.com/feed.xml',
        'https://autor.substack.com/index.xml',
        'https://www.autor.substack.com/feed',
        'https://www.autor.substack.com/feed/',
        'https://www.autor.substack.com/rss/',
        'https://www.autor.substack.com/atom.xml',
        'https://www.autor.substack.com/rss.xml',
        'https://www.autor.substack.com/feed.xml',
        'https://www.autor.substack.com/index.xml',
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
        'https://substack.com/rss.xml',
        'https://substack.com/feed.xml',
        'https://substack.com/index.xml',
        'https://www.substack.com/feed',
        'https://www.substack.com/feed/',
        'https://www.substack.com/rss/',
        'https://www.substack.com/atom.xml',
        'https://www.substack.com/rss.xml',
        'https://www.substack.com/feed.xml',
        'https://www.substack.com/index.xml',
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
        'https://www.substack.com/rss.xml',
        'https://www.substack.com/feed.xml',
        'https://www.substack.com/index.xml',
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
        'https://substack.com/rss.xml',
        'https://substack.com/feed.xml',
        'https://substack.com/index.xml',
        'https://www.substack.com/feed',
        'https://www.substack.com/feed/',
        'https://www.substack.com/rss/',
        'https://www.substack.com/atom.xml',
        'https://www.substack.com/rss.xml',
        'https://www.substack.com/feed.xml',
        'https://www.substack.com/index.xml',
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
        'https://medium.com/rss.xml',
        'https://medium.com/feed.xml',
        'https://medium.com/index.xml',
        'https://www.medium.com/feed',
        'https://www.medium.com/feed/',
        'https://www.medium.com/rss/',
        'https://www.medium.com/atom.xml',
        'https://www.medium.com/rss.xml',
        'https://www.medium.com/feed.xml',
        'https://www.medium.com/index.xml',
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
        'https://medium.com/rss.xml',
        'https://medium.com/feed.xml',
        'https://medium.com/index.xml',
        'https://www.medium.com/feed',
        'https://www.medium.com/feed/',
        'https://www.medium.com/rss/',
        'https://www.medium.com/atom.xml',
        'https://www.medium.com/rss.xml',
        'https://www.medium.com/feed.xml',
        'https://www.medium.com/index.xml',
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
        'https://ederperez.medium.com/rss.xml',
        'https://ederperez.medium.com/feed.xml',
        'https://ederperez.medium.com/index.xml',
        'https://www.ederperez.medium.com/feed',
        'https://www.ederperez.medium.com/feed/',
        'https://www.ederperez.medium.com/rss/',
        'https://www.ederperez.medium.com/atom.xml',
        'https://www.ederperez.medium.com/rss.xml',
        'https://www.ederperez.medium.com/feed.xml',
        'https://www.ederperez.medium.com/index.xml',
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
        'https://medium.com/rss.xml',
        'https://medium.com/feed.xml',
        'https://medium.com/index.xml',
        'https://www.medium.com/feed',
        'https://www.medium.com/feed/',
        'https://www.medium.com/rss/',
        'https://www.medium.com/atom.xml',
        'https://www.medium.com/rss.xml',
        'https://www.medium.com/feed.xml',
        'https://www.medium.com/index.xml',
      ]);
    });

    test('dominio apex que solo redirige a www en la raíz: agrega candidatos www',
        () {
      final candidates = resolver.candidatesFor('https://notboring.co');

      expect(candidates, [
        'https://notboring.co',
        'https://notboring.co/feed',
        'https://notboring.co/feed/',
        'https://notboring.co/rss/',
        'https://notboring.co/atom.xml',
        'https://notboring.co/rss.xml',
        'https://notboring.co/feed.xml',
        'https://notboring.co/index.xml',
        'https://www.notboring.co/feed',
        'https://www.notboring.co/feed/',
        'https://www.notboring.co/rss/',
        'https://www.notboring.co/atom.xml',
        'https://www.notboring.co/rss.xml',
        'https://www.notboring.co/feed.xml',
        'https://www.notboring.co/index.xml',
      ]);
    });

    test('host que ya empieza con www no genera un candidato www.www duplicado',
        () {
      final candidates = resolver.candidatesFor('https://www.notboring.co');

      expect(candidates, [
        'https://www.notboring.co',
        'https://www.notboring.co/feed',
        'https://www.notboring.co/feed/',
        'https://www.notboring.co/rss/',
        'https://www.notboring.co/atom.xml',
        'https://www.notboring.co/rss.xml',
        'https://www.notboring.co/feed.xml',
        'https://www.notboring.co/index.xml',
      ]);
      expect(
        candidates.any((c) => c.contains('www.www.')),
        isFalse,
      );
    });

    test(
        'sufijos nuevos (/rss.xml, /feed.xml, /index.xml) se prueban en host original y www',
        () {
      final candidates = resolver.candidatesFor('https://androidweekly.net');

      expect(candidates, [
        'https://androidweekly.net',
        'https://androidweekly.net/feed',
        'https://androidweekly.net/feed/',
        'https://androidweekly.net/rss/',
        'https://androidweekly.net/atom.xml',
        'https://androidweekly.net/rss.xml',
        'https://androidweekly.net/feed.xml',
        'https://androidweekly.net/index.xml',
        'https://www.androidweekly.net/feed',
        'https://www.androidweekly.net/feed/',
        'https://www.androidweekly.net/rss/',
        'https://www.androidweekly.net/atom.xml',
        'https://www.androidweekly.net/rss.xml',
        'https://www.androidweekly.net/feed.xml',
        'https://www.androidweekly.net/index.xml',
      ]);
    });

    test('los candidatos www quedan después de todos los del host original',
        () {
      final candidates = resolver.candidatesFor('https://notboring.co');

      final originalHostCandidates =
          candidates.where((c) => Uri.parse(c).host == 'notboring.co');
      final wwwHostCandidates =
          candidates.where((c) => Uri.parse(c).host == 'www.notboring.co');

      final lastOriginalIndex = candidates.lastIndexOf(
        originalHostCandidates.last,
      );
      final firstWwwIndex = candidates.indexOf(wwwHostCandidates.first);

      expect(firstWwwIndex, greaterThan(lastOriginalIndex));
    });
  });
}
