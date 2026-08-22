import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/ai/summary_generator.dart';
import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/domain/repositories/article_repository.dart';
import 'package:newsreader/core/domain/repositories/summary_repository.dart';
import 'package:newsreader/core/utils/date_key.dart';
import 'package:newsreader/features/summaries/domain/usecases/generate_daily_summary.dart';

class MockArticleRepository extends Mock implements ArticleRepository {}

class MockSummaryGenerator extends Mock implements SummaryGenerator {}

class MockSummaryRepository extends Mock implements SummaryRepository {}

Article _article({
  required String id,
  required DateTime publishedAt,
  String? excerpt,
  String? contentHtml,
  String sourceId = 's1',
  String sourceName = 'Newsletter A',
}) =>
    Article(
      id: id,
      sourceId: sourceId,
      sourceName: sourceName,
      title: 'Título $id',
      publishedAt: publishedAt,
      excerpt: excerpt,
      contentHtml: contentHtml,
      articleUrl: 'https://example.com/$id',
    );

void main() {
  late MockArticleRepository mockArticleRepository;
  late MockSummaryGenerator mockSummaryGenerator;
  late MockSummaryRepository mockSummaryRepository;
  late GenerateDailySummary sut;

  setUpAll(() {
    registerFallbackValue(<ArticleExcerpt>[]);
    registerFallbackValue(
      DailySummary(
        id: 'fallback',
        date: DateTime(2000),
        content: '',
        articleCount: 0,
        createdAt: DateTime(2000),
      ),
    );
  });

  setUp(() {
    mockArticleRepository = MockArticleRepository();
    mockSummaryGenerator = MockSummaryGenerator();
    mockSummaryRepository = MockSummaryRepository();
    sut = GenerateDailySummary(
      mockArticleRepository,
      mockSummaryGenerator,
      mockSummaryRepository,
    );
  });

  group('sin artículos del inbox de hoy', () {
    test('lanza NoArticlesTodayException y no invoca al generador', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      when(() => mockArticleRepository.getInboxArticles()).thenAnswer(
        (_) async => [_article(id: 'a1', publishedAt: yesterday)],
      );

      expect(sut.execute(language: 'es'), throwsA(isA<NoArticlesTodayException>()));
      verifyNever(() => mockSummaryGenerator.summarize(any(), language: any(named: 'language')));
    });

    test('countTodayArticles() devuelve 0', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      when(() => mockArticleRepository.getInboxArticles()).thenAnswer(
        (_) async => [_article(id: 'a1', publishedAt: yesterday)],
      );

      expect(await sut.countTodayArticles(), 0);
    });
  });

  group('con artículos del inbox de hoy', () {
    test('genera y guarda el DailySummary del día actual con una sola llamada', () async {
      final now = DateTime.now();
      final todayArticles = [
        _article(id: 'a1', publishedAt: now, excerpt: 'Extracto 1'),
        _article(id: 'a2', publishedAt: now, excerpt: 'Extracto 2'),
      ];
      when(() => mockArticleRepository.getInboxArticles())
          .thenAnswer((_) async => todayArticles);
      when(() => mockSummaryGenerator.summarize(any(), language: any(named: 'language')))
          .thenAnswer((_) async => 'Texto del resumen');
      when(() => mockSummaryRepository.save(any()))
          .thenAnswer((_) async {});

      final result = await sut.execute(language: 'es');

      expect(result.id, dateKey(now));
      expect(result.content, 'Texto del resumen');
      expect(result.articleCount, 2);
      verify(() => mockSummaryGenerator.summarize(any(), language: any(named: 'language'))).called(1);
      verify(() => mockSummaryRepository.save(result)).called(1);
    });

    test('threadea el language recibido hacia SummaryGenerator.summarize', () async {
      final now = DateTime.now();
      when(() => mockArticleRepository.getInboxArticles()).thenAnswer(
        (_) async => [_article(id: 'a1', publishedAt: now)],
      );
      when(() => mockSummaryGenerator.summarize(any(), language: any(named: 'language')))
          .thenAnswer((_) async => 'Resumen');
      when(() => mockSummaryRepository.save(any())).thenAnswer((_) async {});

      await sut.execute(language: 'fr');

      final captured = verify(
        () => mockSummaryGenerator.summarize(
          any(),
          language: captureAny(named: 'language'),
        ),
      ).captured.single as String;

      expect(captured, 'fr');
    });

    test('incluye el sourceName de cada artículo al invocar al generador', () async {
      final now = DateTime.now();
      final todayArticles = [
        _article(
          id: 'a1',
          publishedAt: now,
          sourceName: 'Newsletter A',
          excerpt: 'Extracto A',
        ),
        _article(
          id: 'a2',
          publishedAt: now,
          sourceName: 'Newsletter B',
          excerpt: 'Extracto B',
        ),
      ];
      when(() => mockArticleRepository.getInboxArticles())
          .thenAnswer((_) async => todayArticles);
      when(() => mockSummaryGenerator.summarize(any(), language: any(named: 'language')))
          .thenAnswer((_) async => 'Resumen combinado');
      when(() => mockSummaryRepository.save(any())).thenAnswer((_) async {});

      await sut.execute(language: 'es');

      final captured = verify(
        () => mockSummaryGenerator.summarize(captureAny(), language: any(named: 'language')),
      ).captured.single as List<ArticleExcerpt>;

      expect(captured, [
        (title: 'Título a1', excerpt: 'Extracto A', sourceName: 'Newsletter A'),
        (title: 'Título a2', excerpt: 'Extracto B', sourceName: 'Newsletter B'),
      ]);
    });

    test('sobrescribe el resumen existente reutilizando el mismo id', () async {
      final now = DateTime.now();
      when(() => mockArticleRepository.getInboxArticles()).thenAnswer(
        (_) async => [_article(id: 'a1', publishedAt: now)],
      );
      when(() => mockSummaryGenerator.summarize(any(), language: any(named: 'language')))
          .thenAnswer((_) async => 'Nuevo texto');
      when(() => mockSummaryRepository.save(any())).thenAnswer((_) async {});

      final first = await sut.execute(language: 'es');
      final second = await sut.execute(language: 'es');

      expect(first.id, second.id);
      verify(() => mockSummaryRepository.save(any())).called(2);
    });

    test('persiste sourceBlocks agrupando articleIds por sourceId', () async {
      final now = DateTime.now();
      final todayArticles = [
        _article(
          id: 'a1',
          publishedAt: now,
          sourceId: 's1',
          sourceName: 'Newsletter A',
        ),
        _article(
          id: 'a2',
          publishedAt: now,
          sourceId: 's1',
          sourceName: 'Newsletter A',
        ),
        _article(
          id: 'a3',
          publishedAt: now,
          sourceId: 's2',
          sourceName: 'Newsletter B',
        ),
      ];
      when(() => mockArticleRepository.getInboxArticles())
          .thenAnswer((_) async => todayArticles);
      when(() => mockSummaryGenerator.summarize(any(), language: any(named: 'language')))
          .thenAnswer((_) async => 'Resumen');
      when(() => mockSummaryRepository.save(any())).thenAnswer((_) async {});

      final result = await sut.execute(language: 'es');

      expect(result.sourceBlocks, hasLength(2));
      final blockA = result.sourceBlocks!.firstWhere((b) => b.sourceId == 's1');
      expect(blockA.sourceName, 'Newsletter A');
      expect(blockA.articleIds, ['a1', 'a2']);
      final blockB = result.sourceBlocks!.firstWhere((b) => b.sourceId == 's2');
      expect(blockB.sourceName, 'Newsletter B');
      expect(blockB.articleIds, ['a3']);
    });

    test('countTodayArticles() cuenta solo los de hoy', () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      when(() => mockArticleRepository.getInboxArticles()).thenAnswer(
        (_) async => [
          _article(id: 'a1', publishedAt: now),
          _article(id: 'a2', publishedAt: yesterday),
        ],
      );

      expect(await sut.countTodayArticles(), 1);
    });
  });

  group('contenido enviado al generador por artículo', () {
    test('artículo con contentHtml completo usa el texto extraído, no el excerpt', () async {
      final now = DateTime.now();
      final longHtml = '<p>${'Contenido completo real. ' * 30}</p>';
      when(() => mockArticleRepository.getInboxArticles()).thenAnswer(
        (_) async => [
          _article(
            id: 'a1',
            publishedAt: now,
            excerpt: 'Extracto corto',
            contentHtml: longHtml,
          ),
        ],
      );
      when(() => mockSummaryGenerator.summarize(any(), language: any(named: 'language')))
          .thenAnswer((_) async => 'Resumen');
      when(() => mockSummaryRepository.save(any())).thenAnswer((_) async {});

      await sut.execute(language: 'es');

      final captured = verify(
        () => mockSummaryGenerator.summarize(captureAny(), language: any(named: 'language')),
      ).captured.single as List<ArticleExcerpt>;

      expect(captured.single.excerpt, contains('Contenido completo real.'));
      expect(captured.single.excerpt, isNot('Extracto corto'));
      expect(captured.single.excerpt, isNot(contains('<p>')));
    });

    test('artículo con contentHtml truncado usa excerpt como fallback', () async {
      final now = DateTime.now();
      when(() => mockArticleRepository.getInboxArticles()).thenAnswer(
        (_) async => [
          _article(
            id: 'a1',
            publishedAt: now,
            excerpt: 'Extracto de respaldo',
            contentHtml: '<p>corto</p>',
          ),
        ],
      );
      when(() => mockSummaryGenerator.summarize(any(), language: any(named: 'language')))
          .thenAnswer((_) async => 'Resumen');
      when(() => mockSummaryRepository.save(any())).thenAnswer((_) async {});

      await sut.execute(language: 'es');

      final captured = verify(
        () => mockSummaryGenerator.summarize(captureAny(), language: any(named: 'language')),
      ).captured.single as List<ArticleExcerpt>;

      expect(captured.single.excerpt, 'Extracto de respaldo');
    });

    test('artículo sin contentHtml usa excerpt como fallback', () async {
      final now = DateTime.now();
      when(() => mockArticleRepository.getInboxArticles()).thenAnswer(
        (_) async => [
          _article(
            id: 'a1',
            publishedAt: now,
            excerpt: 'Extracto único disponible',
          ),
        ],
      );
      when(() => mockSummaryGenerator.summarize(any(), language: any(named: 'language')))
          .thenAnswer((_) async => 'Resumen');
      when(() => mockSummaryRepository.save(any())).thenAnswer((_) async {});

      await sut.execute(language: 'es');

      final captured = verify(
        () => mockSummaryGenerator.summarize(captureAny(), language: any(named: 'language')),
      ).captured.single as List<ArticleExcerpt>;

      expect(captured.single.excerpt, 'Extracto único disponible');
    });
  });

  group('wouldRegenerateWithSameArticles', () {
    test('false si no hay DailySummary guardado para hoy', () async {
      final now = DateTime.now();
      when(() => mockArticleRepository.getInboxArticles())
          .thenAnswer((_) async => [_article(id: 'a1', publishedAt: now)]);
      when(() => mockSummaryRepository.getByDate(any()))
          .thenAnswer((_) async => null);

      expect(await sut.wouldRegenerateWithSameArticles(), isFalse);
    });

    test('true si el conteo de hoy es igual al articleCount guardado', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      when(() => mockArticleRepository.getInboxArticles()).thenAnswer(
        (_) async => [
          _article(id: 'a1', publishedAt: now),
          _article(id: 'a2', publishedAt: now),
        ],
      );
      when(() => mockSummaryRepository.getByDate(any())).thenAnswer(
        (_) async => DailySummary(
          id: dateKey(today),
          date: today,
          content: 'Resumen',
          articleCount: 2,
          createdAt: today,
        ),
      );

      expect(await sut.wouldRegenerateWithSameArticles(), isTrue);
    });

    test('false si el conteo de hoy es distinto al articleCount guardado', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      when(() => mockArticleRepository.getInboxArticles()).thenAnswer(
        (_) async => [
          _article(id: 'a1', publishedAt: now),
          _article(id: 'a2', publishedAt: now),
        ],
      );
      when(() => mockSummaryRepository.getByDate(any())).thenAnswer(
        (_) async => DailySummary(
          id: dateKey(today),
          date: today,
          content: 'Resumen',
          articleCount: 1,
          createdAt: today,
        ),
      );

      expect(await sut.wouldRegenerateWithSameArticles(), isFalse);
    });
  });
}
