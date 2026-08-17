import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/core/domain/repositories/source_repository.dart';
import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/feed/feed_data.dart';
import 'package:newsreader/core/feed/feed_parser.dart';
import 'package:newsreader/core/feed/feed_url_resolver.dart';
import 'package:newsreader/core/network/http_client.dart';
import 'package:newsreader/core/utils/id_generator.dart';
import 'package:newsreader/features/sources/domain/usecases/add_source.dart';

class MockSourceRepository extends Mock implements SourceRepository {}
class MockHttpClient extends Mock implements HttpClient {}
class MockFeedParser extends Mock implements FeedParser {}
class MockIdGenerator extends Mock implements IdGenerator {}
class MockFeedUrlResolver extends Mock implements FeedUrlResolver {}

final _tSource = NewsSource(
  id: 'new-id',
  name: 'Feed A',
  feedUrl: 'https://autor.substack.com/feed',
  addedAt: DateTime(2024),
);

const _tFeedData = FeedData(title: 'Feed A', items: []);

void main() {
  setUpAll(() {
    registerFallbackValue(_tSource);
  });

  late MockSourceRepository mockRepo;
  late MockHttpClient mockHttp;
  late MockFeedParser mockFeedParser;
  late MockIdGenerator mockId;
  late MockFeedUrlResolver mockResolver;
  late AddSource sut;

  setUp(() {
    mockRepo = MockSourceRepository();
    mockHttp = MockHttpClient();
    mockFeedParser = MockFeedParser();
    mockId = MockIdGenerator();
    mockResolver = MockFeedUrlResolver();
    sut = AddSource(mockRepo, mockHttp, mockFeedParser, mockId, mockResolver);

    when(() => mockId.generate()).thenReturn('new-id');
    when(() => mockRepo.addSource(any())).thenAnswer((_) async => _tSource);
  });

  group('execute', () {
    test('URL exacta de feed sigue funcionando igual que hoy', () async {
      when(() => mockResolver.candidatesFor('https://autor.substack.com/feed'))
          .thenReturn(['https://autor.substack.com/feed']);
      when(() => mockRepo.sourceExists('https://autor.substack.com/feed'))
          .thenAnswer((_) async => false);
      when(() => mockHttp.get('https://autor.substack.com/feed'))
          .thenAnswer((_) async => '<xml/>');
      when(() => mockFeedParser.parse('<xml/>')).thenReturn(_tFeedData);

      final result = await sut.execute('https://autor.substack.com/feed');

      expect(result.feedUrl, 'https://autor.substack.com/feed');
      verify(() => mockHttp.get('https://autor.substack.com/feed')).called(1);
    });

    test('URL humana de plataforma soportada se resuelve vía candidato heurístico',
        () async {
      when(() => mockResolver.candidatesFor('https://autor.substack.com/p/x'))
          .thenReturn([
        'https://autor.substack.com/p/x',
        'https://autor.substack.com/feed',
      ]);
      when(() => mockHttp.get('https://autor.substack.com/p/x'))
          .thenAnswer((_) async => '<html></html>');
      when(() => mockFeedParser.parse('<html></html>'))
          .thenThrow(const ParseException());
      when(() => mockHttp.get('https://autor.substack.com/feed'))
          .thenAnswer((_) async => '<xml/>');
      when(() => mockFeedParser.parse('<xml/>')).thenReturn(_tFeedData);
      when(() => mockRepo.sourceExists('https://autor.substack.com/feed'))
          .thenAnswer((_) async => false);

      final result = await sut.execute('https://autor.substack.com/p/x');

      expect(result.feedUrl, 'https://autor.substack.com/feed');
      verify(() => mockHttp.get('https://autor.substack.com/p/x')).called(1);
      verify(() => mockHttp.get('https://autor.substack.com/feed')).called(1);
    });

    test(
        'host no reconocido y candidato heurístico fallido lanzan FeedDiscoveryException',
        () async {
      when(() => mockResolver.candidatesFor('https://sitio-desconocido.com'))
          .thenReturn(['https://sitio-desconocido.com']);
      when(() => mockHttp.get('https://sitio-desconocido.com'))
          .thenAnswer((_) async => '<html></html>');
      when(() => mockFeedParser.parse('<html></html>'))
          .thenThrow(const ParseException());

      expect(
        () => sut.execute('https://sitio-desconocido.com'),
        throwsA(isA<FeedDiscoveryException>()),
      );
    });

    test(
        'extrae el link declarado en el HTML de la etapa 1 y lo usa cuando ningún otro candidato resuelve',
        () async {
      when(() => mockResolver.candidatesFor('https://simonwillison.net'))
          .thenReturn([
        'https://simonwillison.net',
        'https://simonwillison.net/feed',
      ]);
      when(() => mockHttp.get('https://simonwillison.net')).thenAnswer(
        (_) async => '<html><head>'
            '<link rel="alternate" type="application/atom+xml" '
            'href="/atom/everything/">'
            '</head></html>',
      );
      when(() => mockFeedParser.parse(any(that: contains('<html>'))))
          .thenThrow(const ParseException());
      when(() => mockHttp.get('https://simonwillison.net/feed'))
          .thenThrow(const NetworkException());
      when(() => mockHttp.get('https://simonwillison.net/atom/everything/'))
          .thenAnswer((_) async => '<xml/>');
      when(() => mockFeedParser.parse('<xml/>')).thenReturn(_tFeedData);
      when(() =>
              mockRepo.sourceExists('https://simonwillison.net/atom/everything/'))
          .thenAnswer((_) async => false);

      await sut.execute('https://simonwillison.net');

      verify(() =>
              mockRepo.sourceExists('https://simonwillison.net/atom/everything/'))
          .called(1);
    });

    test(
        'si el HTML de la etapa 1 no declara ningún link, falla igual que hoy',
        () async {
      when(() => mockResolver.candidatesFor('https://sin-feed-ni-link.com'))
          .thenReturn(['https://sin-feed-ni-link.com']);
      when(() => mockHttp.get('https://sin-feed-ni-link.com'))
          .thenAnswer((_) async => '<html><head></head></html>');
      when(() => mockFeedParser.parse('<html><head></head></html>'))
          .thenThrow(const ParseException());

      expect(
        () => sut.execute('https://sin-feed-ni-link.com'),
        throwsA(isA<FeedDiscoveryException>()),
      );
    });

    test(
        'auto-descubrimiento no se intenta si la etapa 1 falla por red (no hay HTML retenido)',
        () async {
      when(() => mockResolver.candidatesFor('https://timeout.com'))
          .thenReturn(['https://timeout.com']);
      when(() => mockHttp.get('https://timeout.com'))
          .thenThrow(const NetworkException());

      expect(
        () => sut.execute('https://timeout.com'),
        throwsA(isA<NetworkException>()),
      );
      // Ningún otro request más allá del único intento de la etapa 1.
      verify(() => mockHttp.get('https://timeout.com')).called(1);
    });

    test('error de red en el primer intento se propaga sin probar el candidato heurístico',
        () async {
      when(() => mockResolver.candidatesFor('https://autor.substack.com/p/x'))
          .thenReturn([
        'https://autor.substack.com/p/x',
        'https://autor.substack.com/feed',
      ]);
      when(() => mockHttp.get('https://autor.substack.com/p/x'))
          .thenThrow(const NetworkException());

      expect(
        () => sut.execute('https://autor.substack.com/p/x'),
        throwsA(isA<NetworkException>()),
      );
      verifyNever(() => mockHttp.get('https://autor.substack.com/feed'));
    });

    test(
        'gana el candidato de mayor prioridad aunque otro de menor prioridad responda antes',
        () async {
      when(() => mockResolver.candidatesFor('https://autor.substack.com/p/x'))
          .thenReturn([
        'https://autor.substack.com/p/x',
        'https://autor.substack.com/feed', // prioridad 1
        'https://autor.substack.com/rss/', // prioridad 2
      ]);
      when(() => mockHttp.get('https://autor.substack.com/p/x'))
          .thenAnswer((_) async => '<html></html>');
      when(() => mockFeedParser.parse('<html></html>'))
          .thenThrow(const ParseException());

      // El candidato de menor prioridad resuelve más rápido...
      when(() => mockHttp.get('https://autor.substack.com/rss/'))
          .thenAnswer((_) async => '<xml-rss/>');
      when(() => mockFeedParser.parse('<xml-rss/>')).thenReturn(_tFeedData);

      // ...pero el de mayor prioridad tarda más en responder.
      when(() => mockHttp.get('https://autor.substack.com/feed')).thenAnswer(
        (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return '<xml-feed/>';
        },
      );
      when(() => mockFeedParser.parse('<xml-feed/>')).thenReturn(_tFeedData);

      when(() => mockRepo.sourceExists('https://autor.substack.com/feed'))
          .thenAnswer((_) async => false);

      await sut.execute('https://autor.substack.com/p/x');

      // La corroboración real de cuál candidato ganó pasa por qué URL se usó
      // para chequear duplicados, no por el valor de retorno (el mock de
      // `addSource` devuelve siempre el mismo `_tSource` fijo).
      verify(() => mockRepo.sourceExists('https://autor.substack.com/feed'))
          .called(1);
      verifyNever(() => mockRepo.sourceExists('https://autor.substack.com/rss/'));
    });

    test(
        'el candidato de auto-descubrimiento gana sobre un candidato heurístico que también resuelve',
        () async {
      when(() => mockResolver.candidatesFor('https://simonwillison.net'))
          .thenReturn([
        'https://simonwillison.net',
        'https://simonwillison.net/feed',
      ]);
      when(() => mockHttp.get('https://simonwillison.net')).thenAnswer(
        (_) async => '<html><head>'
            '<link rel="alternate" type="application/atom+xml" '
            'href="/atom/everything/">'
            '</head></html>',
      );
      when(() => mockFeedParser.parse(any(that: contains('<html>'))))
          .thenThrow(const ParseException());

      // Ambos candidatos resuelven: el heurístico (/feed) y el descubierto
      // por <link rel="alternate">. Debe ganar el descubierto por tener
      // mayor prioridad, sin importar cuál responda primero.
      when(() => mockHttp.get('https://simonwillison.net/feed'))
          .thenAnswer((_) async => '<xml-feed/>');
      when(() => mockFeedParser.parse('<xml-feed/>')).thenReturn(_tFeedData);
      when(() => mockHttp.get('https://simonwillison.net/atom/everything/'))
          .thenAnswer((_) async => '<xml-atom/>');
      when(() => mockFeedParser.parse('<xml-atom/>')).thenReturn(_tFeedData);

      when(() =>
              mockRepo.sourceExists('https://simonwillison.net/atom/everything/'))
          .thenAnswer((_) async => false);

      await sut.execute('https://simonwillison.net');

      verify(() =>
              mockRepo.sourceExists('https://simonwillison.net/atom/everything/'))
          .called(1);
      verifyNever(() => mockRepo.sourceExists('https://simonwillison.net/feed'));
    });

    test(
        'un error de red en un candidato de la etapa 2 no aborta si otro candidato en vuelo es válido',
        () async {
      when(() => mockResolver.candidatesFor('https://autor.substack.com/p/x'))
          .thenReturn([
        'https://autor.substack.com/p/x',
        'https://autor.substack.com/feed',
        'https://autor.substack.com/rss/',
      ]);
      when(() => mockHttp.get('https://autor.substack.com/p/x'))
          .thenAnswer((_) async => '<html></html>');
      when(() => mockFeedParser.parse('<html></html>'))
          .thenThrow(const ParseException());

      when(() => mockHttp.get('https://autor.substack.com/feed'))
          .thenThrow(const NetworkException());

      when(() => mockHttp.get('https://autor.substack.com/rss/'))
          .thenAnswer((_) async => '<xml/>');
      when(() => mockFeedParser.parse('<xml/>')).thenReturn(_tFeedData);
      when(() => mockRepo.sourceExists('https://autor.substack.com/rss/'))
          .thenAnswer((_) async => false);

      await sut.execute('https://autor.substack.com/p/x');

      verify(() => mockRepo.sourceExists('https://autor.substack.com/rss/'))
          .called(1);
    });

    test(
        'onHeuristicStageStarted se invoca solo al pasar a la etapa de candidatos heurísticos',
        () async {
      when(() => mockResolver.candidatesFor('https://autor.substack.com/p/x'))
          .thenReturn([
        'https://autor.substack.com/p/x',
        'https://autor.substack.com/feed',
      ]);
      when(() => mockHttp.get('https://autor.substack.com/p/x'))
          .thenAnswer((_) async => '<html></html>');
      when(() => mockFeedParser.parse('<html></html>'))
          .thenThrow(const ParseException());
      when(() => mockHttp.get('https://autor.substack.com/feed'))
          .thenAnswer((_) async => '<xml/>');
      when(() => mockFeedParser.parse('<xml/>')).thenReturn(_tFeedData);
      when(() => mockRepo.sourceExists('https://autor.substack.com/feed'))
          .thenAnswer((_) async => false);

      var stageStartedCalls = 0;
      await sut.execute(
        'https://autor.substack.com/p/x',
        onHeuristicStageStarted: () => stageStartedCalls++,
      );

      expect(stageStartedCalls, 1);
    });

    test(
        'onHeuristicStageStarted no se invoca cuando la URL exacta ya es un feed válido',
        () async {
      when(() => mockResolver.candidatesFor('https://autor.substack.com/feed'))
          .thenReturn(['https://autor.substack.com/feed']);
      when(() => mockRepo.sourceExists('https://autor.substack.com/feed'))
          .thenAnswer((_) async => false);
      when(() => mockHttp.get('https://autor.substack.com/feed'))
          .thenAnswer((_) async => '<xml/>');
      when(() => mockFeedParser.parse('<xml/>')).thenReturn(_tFeedData);

      var stageStartedCalls = 0;
      await sut.execute(
        'https://autor.substack.com/feed',
        onHeuristicStageStarted: () => stageStartedCalls++,
      );

      expect(stageStartedCalls, 0);
    });

    test('duplicado se detecta sobre la feed URL final resuelta', () async {
      when(() => mockResolver.candidatesFor('https://autor.substack.com/p/x'))
          .thenReturn([
        'https://autor.substack.com/p/x',
        'https://autor.substack.com/feed',
      ]);
      when(() => mockHttp.get('https://autor.substack.com/p/x'))
          .thenAnswer((_) async => '<html></html>');
      when(() => mockFeedParser.parse('<html></html>'))
          .thenThrow(const ParseException());
      when(() => mockHttp.get('https://autor.substack.com/feed'))
          .thenAnswer((_) async => '<xml/>');
      when(() => mockFeedParser.parse('<xml/>')).thenReturn(_tFeedData);
      when(() => mockRepo.sourceExists('https://autor.substack.com/feed'))
          .thenAnswer((_) async => true);

      expect(
        () => sut.execute('https://autor.substack.com/p/x'),
        throwsA(isA<DuplicateSourceException>()),
      );
      verifyNever(() => mockRepo.sourceExists('https://autor.substack.com/p/x'));
    });
  });
}
