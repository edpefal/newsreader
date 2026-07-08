import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/core/domain/repositories/source_repository.dart';
import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/feed/feed_data.dart';
import 'package:newsreader/core/feed/feed_parser.dart';
import 'package:newsreader/core/network/http_client.dart';
import 'package:newsreader/core/opml/opml_parser.dart';
import 'package:newsreader/core/utils/id_generator.dart';
import 'package:newsreader/features/sources/domain/usecases/import_opml.dart';

class MockOPMLParser extends Mock implements OPMLParser {}
class MockHttpClient extends Mock implements HttpClient {}
class MockFeedParser extends Mock implements FeedParser {}
class MockSourceRepository extends Mock implements SourceRepository {}
class MockIdGenerator extends Mock implements IdGenerator {}

final _tSource = NewsSource(
  id: 'id-1',
  name: 'Feed A',
  feedUrl: 'https://a.com/feed',
  addedAt: DateTime(2024),
);

const _tFeedData = FeedData(title: 'Feed A', items: []);

void main() {
  setUpAll(() {
    registerFallbackValue(_tSource);
  });

  late MockOPMLParser mockParser;
  late MockHttpClient mockHttp;
  late MockFeedParser mockFeedParser;
  late MockSourceRepository mockRepo;
  late MockIdGenerator mockId;
  late ImportOpml sut;

  setUp(() {
    mockParser = MockOPMLParser();
    mockHttp = MockHttpClient();
    mockFeedParser = MockFeedParser();
    mockRepo = MockSourceRepository();
    mockId = MockIdGenerator();
    sut = ImportOpml(mockParser, mockHttp, mockFeedParser, mockRepo, mockId);
  });

  group('parseUrls', () {
    test('delega al OPMLParser y retorna las URLs', () {
      when(() => mockParser.parse(any()))
          .thenReturn(['https://a.com/feed', 'https://b.com/feed']);

      final result = sut.parseUrls('<opml/>');

      expect(result, ['https://a.com/feed', 'https://b.com/feed']);
    });
  });

  group('validateFeeds', () {
    test('llama onResult con valid para feed nuevo y accesible', () async {
      when(() => mockRepo.sourceExists(any())).thenAnswer((_) async => false);
      when(() => mockHttp.get(any())).thenAnswer((_) async => '<xml/>');
      when(() => mockFeedParser.parse(any())).thenReturn(_tFeedData);

      final results = <OpmlFeedValidation>[];
      await sut.validateFeeds(['https://a.com/feed'], onResult: results.add);

      expect(results.first.status, OpmlFeedValidationStatus.valid);
      expect(results.first.name, 'Feed A');
    });

    test('llama onResult con duplicate para URL ya existente', () async {
      when(() => mockRepo.sourceExists('https://a.com/feed'))
          .thenAnswer((_) async => true);

      final results = <OpmlFeedValidation>[];
      await sut.validateFeeds(['https://a.com/feed'], onResult: results.add);

      expect(results.first.status, OpmlFeedValidationStatus.duplicate);
    });

    test('llama onResult con error cuando el HTTP falla', () async {
      when(() => mockRepo.sourceExists(any())).thenAnswer((_) async => false);
      when(() => mockHttp.get(any()))
          .thenThrow(const NetworkException('Sin conexión'));

      final results = <OpmlFeedValidation>[];
      await sut.validateFeeds(['https://a.com/feed'], onResult: results.add);

      expect(results.first.status, OpmlFeedValidationStatus.error);
      expect(results.first.errorMessage, 'Sin conexión');
    });

    test('clasifica correctamente una combinación de feeds mixtos', () async {
      when(() => mockRepo.sourceExists('https://a.com/feed'))
          .thenAnswer((_) async => false);
      when(() => mockRepo.sourceExists('https://b.com/feed'))
          .thenAnswer((_) async => true);
      when(() => mockRepo.sourceExists('https://c.com/feed'))
          .thenAnswer((_) async => false);
      when(() => mockHttp.get('https://a.com/feed'))
          .thenAnswer((_) async => '<xml/>');
      when(() => mockFeedParser.parse('<xml/>')).thenReturn(_tFeedData);
      when(() => mockHttp.get('https://c.com/feed'))
          .thenThrow(const TimeoutException());

      final results = <OpmlFeedValidation>[];
      await sut.validateFeeds(
        ['https://a.com/feed', 'https://b.com/feed', 'https://c.com/feed'],
        onResult: results.add,
      );

      expect(
        results.firstWhere((r) => r.url == 'https://a.com/feed').status,
        OpmlFeedValidationStatus.valid,
      );
      expect(
        results.firstWhere((r) => r.url == 'https://b.com/feed').status,
        OpmlFeedValidationStatus.duplicate,
      );
      expect(
        results.firstWhere((r) => r.url == 'https://c.com/feed').status,
        OpmlFeedValidationStatus.error,
      );
    });
  });

  group('execute', () {
    setUp(() {
      when(() => mockId.generate()).thenReturn('new-id');
      when(() => mockRepo.addSource(any())).thenAnswer((_) async => _tSource);
      when(() => mockHttp.get(any())).thenAnswer((_) async => '<xml/>');
      when(() => mockFeedParser.parse(any())).thenReturn(_tFeedData);
    });

    test('importa feeds seleccionados y retorna resultado con imported', () async {
      final result = await sut.execute(['https://a.com/feed']);

      expect(result.imported.length, 1);
      expect(result.skippedDuplicates, isEmpty);
      expect(result.failed, isEmpty);
    });

    test('clasifica duplicados en skippedDuplicates', () async {
      when(() => mockRepo.addSource(any()))
          .thenThrow(const DuplicateSourceException());

      final result = await sut.execute(['https://a.com/feed']);

      expect(result.imported, isEmpty);
      expect(result.skippedDuplicates, ['https://a.com/feed']);
    });

    test('clasifica errores de red en failed', () async {
      when(() => mockHttp.get(any()))
          .thenThrow(const NetworkException());

      final result = await sut.execute(['https://a.com/feed']);

      expect(result.imported, isEmpty);
      expect(result.failed, ['https://a.com/feed']);
    });
  });
}
