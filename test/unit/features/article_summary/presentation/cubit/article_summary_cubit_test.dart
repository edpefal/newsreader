import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/ai/article_summary_generator.dart';
import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/entities/article_summary.dart';
import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/features/article_summary/domain/usecases/generate_article_summary.dart';
import 'package:newsreader/features/article_summary/presentation/cubit/article_summary_cubit.dart';

import '../../../../../support/fake_observability_client.dart';

class MockGenerateArticleSummary extends Mock
    implements GenerateArticleSummary {}

void main() {
  late MockGenerateArticleSummary mockGenerateArticleSummary;
  late MockObservabilityClient mockObservabilityClient;

  final tArticle = Article(
    id: 'a1',
    sourceId: 's1',
    sourceName: 'Newsletter A',
    title: 'Un artículo',
    publishedAt: DateTime(2024, 3, 15),
    articleUrl: 'https://example.com/a1',
  );

  final tSummary = ArticleSummary(
    articleId: 'a1',
    summary: 'Resumen generado',
    mentions: const [],
    createdAt: DateTime(2024, 3, 15),
  );

  ArticleSummaryCubit buildCubit() => ArticleSummaryCubit(
        mockGenerateArticleSummary,
        mockObservabilityClient,
      );

  setUpAll(() {
    registerFallbackValue(StackTrace.empty);
    registerFallbackValue(
      Article(
        id: 'fallback',
        sourceId: 's1',
        sourceName: 'Newsletter A',
        title: 'Título',
        publishedAt: DateTime(2000),
        articleUrl: 'https://example.com/fallback',
      ),
    );
  });

  setUp(() {
    mockGenerateArticleSummary = MockGenerateArticleSummary();
    mockObservabilityClient = MockObservabilityClient();
  });

  group('ArticleSummaryCubit', () {
    test('estado inicial es ArticleSummaryLoading', () {
      expect(buildCubit().state, const ArticleSummaryLoading());
    });

    blocTest<ArticleSummaryCubit, ArticleSummaryState>(
      'generate() emite Loading y luego Loaded con el resumen',
      build: () {
        when(() => mockGenerateArticleSummary.execute(
              any(),
              language: any(named: 'language'),
            )).thenAnswer((_) async => tSummary);
        return buildCubit();
      },
      act: (cubit) => cubit.generate(tArticle, 'es'),
      expect: () => [
        const ArticleSummaryLoading(),
        ArticleSummaryLoaded(tSummary),
      ],
    );

    blocTest<ArticleSummaryCubit, ArticleSummaryState>(
      'generate() threadea el language recibido hasta el usecase',
      build: () {
        when(() => mockGenerateArticleSummary.execute(
              any(),
              language: any(named: 'language'),
            )).thenAnswer((_) async => tSummary);
        return buildCubit();
      },
      act: (cubit) => cubit.generate(tArticle, 'fr'),
      verify: (_) {
        verify(() => mockGenerateArticleSummary.execute(
              tArticle,
              language: 'fr',
            )).called(1);
      },
    );

    blocTest<ArticleSummaryCubit, ArticleSummaryState>(
      'generate() con falla genérica emite Error(generationFailed) y reporta',
      build: () {
        when(() => mockGenerateArticleSummary.execute(
              any(),
              language: any(named: 'language'),
            )).thenThrow(Exception('modelo no disponible'));
        return buildCubit();
      },
      act: (cubit) => cubit.generate(tArticle, 'es'),
      expect: () => [
        const ArticleSummaryLoading(),
        const ArticleSummaryError(AppErrorCode.generationFailed),
      ],
      verify: (_) {
        verify(
          () => mockObservabilityClient.captureException(any(), any()),
        ).called(1);
      },
    );

    blocTest<ArticleSummaryCubit, ArticleSummaryState>(
      'generate() con presupuesto de IA agotado emite Error sin reportarlo',
      build: () {
        when(() => mockGenerateArticleSummary.execute(
              any(),
              language: any(named: 'language'),
            )).thenThrow(
          const ArticleSummaryGenerationException(
            AppErrorCode.aiUsageLimitReached,
          ),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.generate(tArticle, 'es'),
      expect: () => [
        const ArticleSummaryLoading(),
        const ArticleSummaryError(AppErrorCode.aiUsageLimitReached),
      ],
      verify: (_) {
        verifyNever(
          () => mockObservabilityClient.captureException(any(), any()),
        );
      },
    );
  });
}
