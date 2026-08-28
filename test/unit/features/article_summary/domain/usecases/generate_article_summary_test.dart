import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/ai/article_summary_generator.dart';
import 'package:newsreader/core/ai/mention_enricher.dart';
import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/entities/article_summary.dart';
import 'package:newsreader/core/domain/repositories/article_summary_repository.dart';
import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/features/article_summary/domain/usecases/generate_article_summary.dart';

class MockArticleSummaryRepository extends Mock
    implements ArticleSummaryRepository {}

class MockArticleSummaryGenerator extends Mock
    implements ArticleSummaryGenerator {}

class MockMentionEnricher extends Mock implements MentionEnricher {}

void main() {
  late MockArticleSummaryRepository mockRepository;
  late MockArticleSummaryGenerator mockGenerator;
  late MockMentionEnricher mockEnricher;
  late GenerateArticleSummary sut;

  final tArticle = Article(
    id: 'a1',
    sourceId: 's1',
    sourceName: 'Newsletter A',
    title: 'Un artículo sobre libros',
    excerpt: 'Extracto corto',
    contentHtml: '<p>${'Contenido completo real. ' * 30}</p>',
    publishedAt: DateTime(2024, 3, 15),
    articleUrl: 'https://example.com/a1',
  );

  setUpAll(() {
    registerFallbackValue(<RawMention>[]);
    registerFallbackValue(
      ArticleSummary(
        articleId: 'fallback',
        summary: '',
        mentions: const [],
        createdAt: DateTime(2000),
      ),
    );
  });

  setUp(() {
    mockRepository = MockArticleSummaryRepository();
    mockGenerator = MockArticleSummaryGenerator();
    mockEnricher = MockMentionEnricher();
    sut = GenerateArticleSummary(mockRepository, mockGenerator, mockEnricher);
  });

  group('con un resumen ya persistido', () {
    test('lo devuelve directo sin invocar al generador ni al enricher',
        () async {
      final existing = ArticleSummary(
        articleId: 'a1',
        summary: 'Ya generado',
        mentions: const [],
        createdAt: DateTime(2024, 3, 16),
      );
      when(() => mockRepository.getByArticleId('a1'))
          .thenAnswer((_) async => existing);

      final result = await sut.execute(tArticle, language: 'es');

      expect(result, existing);
      verifyNever(
        () => mockGenerator.summarizeArticle(
          any(),
          any(),
          language: any(named: 'language'),
        ),
      );
      verifyNever(() => mockEnricher.enrich(any()));
      verifyNever(() => mockRepository.save(any()));
    });
  });

  group('sin resumen persistido', () {
    test('genera, enriquece y persiste el nuevo resumen', () async {
      when(() => mockRepository.getByArticleId('a1'))
          .thenAnswer((_) async => null);
      when(() => mockGenerator.summarizeArticle(
            any(),
            any(),
            language: any(named: 'language'),
          )).thenAnswer((_) async => (
            summary: 'Resumen generado',
            mentions: [(type: MentionType.book, name: 'Un libro', url: null)],
          ));
      when(() => mockEnricher.enrich(any())).thenAnswer((_) async => [
            (
              type: MentionType.book,
              name: 'Un libro',
              imageUrl: 'https://books.example/cover.jpg',
              link: 'https://books.example/info',
            ),
          ]);
      when(() => mockRepository.save(any())).thenAnswer((_) async {});

      final result = await sut.execute(tArticle, language: 'es');

      expect(result.articleId, 'a1');
      expect(result.summary, 'Resumen generado');
      expect(result.mentions.single.imageUrl, 'https://books.example/cover.jpg');
      verify(() => mockRepository.save(result)).called(1);
    });

    test('usa el texto extraído de contentHtml no truncado, no el excerpt',
        () async {
      when(() => mockRepository.getByArticleId('a1'))
          .thenAnswer((_) async => null);
      when(() => mockGenerator.summarizeArticle(
            any(),
            any(),
            language: any(named: 'language'),
          )).thenAnswer(
        (_) async => (summary: 'Resumen', mentions: <RawMention>[]),
      );
      when(() => mockEnricher.enrich(any())).thenAnswer((_) async => []);
      when(() => mockRepository.save(any())).thenAnswer((_) async {});

      await sut.execute(tArticle, language: 'es');

      final captured = verify(() => mockGenerator.summarizeArticle(
            any(),
            captureAny(),
            language: any(named: 'language'),
          )).captured.single as String;

      expect(captured, contains('Contenido completo real.'));
      expect(captured, isNot(contains('Extracto corto')));
    });

    test('usa excerpt como fallback si contentHtml está truncado', () async {
      final articleTruncado = Article(
        id: 'a2',
        sourceId: 's1',
        sourceName: 'Newsletter A',
        title: 'Título',
        excerpt: 'Extracto de respaldo',
        contentHtml: '<p>corto</p>',
        publishedAt: DateTime(2024, 3, 15),
        articleUrl: 'https://example.com/a2',
      );
      when(() => mockRepository.getByArticleId('a2'))
          .thenAnswer((_) async => null);
      when(() => mockGenerator.summarizeArticle(
            any(),
            any(),
            language: any(named: 'language'),
          )).thenAnswer(
        (_) async => (summary: 'Resumen', mentions: <RawMention>[]),
      );
      when(() => mockEnricher.enrich(any())).thenAnswer((_) async => []);
      when(() => mockRepository.save(any())).thenAnswer((_) async {});

      await sut.execute(articleTruncado, language: 'es');

      final captured = verify(() => mockGenerator.summarizeArticle(
            any(),
            captureAny(),
            language: any(named: 'language'),
          )).captured.single as String;

      expect(captured, 'Extracto de respaldo');
    });

    test(
        'si el enriquecimiento falla, persiste igual el resumen con las '
        'menciones sin enriquecer', () async {
      when(() => mockRepository.getByArticleId('a1'))
          .thenAnswer((_) async => null);
      when(() => mockGenerator.summarizeArticle(
            any(),
            any(),
            language: any(named: 'language'),
          )).thenAnswer((_) async => (
            summary: 'Resumen generado',
            mentions: [(type: MentionType.podcast, name: 'Un podcast', url: null)],
          ));
      when(() => mockEnricher.enrich(any()))
          .thenThrow(const MentionEnrichmentException(
        AppErrorCode.unknown,
      ));
      when(() => mockRepository.save(any())).thenAnswer((_) async {});

      final result = await sut.execute(tArticle, language: 'es');

      expect(result.mentions.single.name, 'Un podcast');
      expect(result.mentions.single.imageUrl, isNull);
      expect(result.mentions.single.link, isNull);
      verify(() => mockRepository.save(result)).called(1);
    });

    test(
        'si el enriquecimiento falla, una mención de tipo artículo igual '
        'queda con su link (la URL ya la extrajo la API de IA)', () async {
      when(() => mockRepository.getByArticleId('a1'))
          .thenAnswer((_) async => null);
      when(() => mockGenerator.summarizeArticle(
            any(),
            any(),
            language: any(named: 'language'),
          )).thenAnswer((_) async => (
            summary: 'Resumen generado',
            mentions: [
              (
                type: MentionType.article,
                name: 'Otro artículo',
                url: 'https://other.example.com/post',
              ),
            ],
          ));
      when(() => mockEnricher.enrich(any()))
          .thenThrow(const MentionEnrichmentException(
        AppErrorCode.unknown,
      ));
      when(() => mockRepository.save(any())).thenAnswer((_) async {});

      final result = await sut.execute(tArticle, language: 'es');

      expect(result.mentions.single.imageUrl, isNull);
      expect(result.mentions.single.link, 'https://other.example.com/post');
    });
  });
}
