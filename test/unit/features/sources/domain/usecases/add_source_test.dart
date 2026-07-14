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
