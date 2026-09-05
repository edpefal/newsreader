import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/ai/article_summary_generator.dart';
import 'package:newsreader/core/domain/entities/ai_usage_status.dart';
import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/entities/article_summary.dart';
import 'package:newsreader/core/domain/repositories/ai_usage_repository.dart';
import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/features/article_summary/domain/usecases/generate_article_summary.dart';
import 'package:newsreader/features/article_summary/presentation/cubit/article_summary_cubit.dart';

import '../../../../../support/fake_telemetry_client.dart';

class MockGenerateArticleSummary extends Mock
    implements GenerateArticleSummary {}

class MockAiUsageRepository extends Mock implements AiUsageRepository {}

void main() {
  late MockGenerateArticleSummary mockGenerateArticleSummary;
  late MockAiUsageRepository mockAiUsageRepository;
  late MockTelemetryClient mockTelemetryClient;

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
        mockAiUsageRepository,
        mockTelemetryClient,
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
    mockAiUsageRepository = MockAiUsageRepository();
    mockTelemetryClient = MockTelemetryClient();
    when(() => mockAiUsageRepository.getStatus()).thenAnswer(
      (_) async =>
          const AiUsageStatus(summariesUsedToday: 10, dailyLimit: 25),
    );
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
        ArticleSummaryLoaded(tSummary, remainingToday: 15),
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
        const ArticleSummaryError(
          AppErrorCode.generationFailed,
          remainingToday: 15,
        ),
      ],
      verify: (_) {
        verify(
          () => mockTelemetryClient.captureException(any(), any()),
        ).called(1);
      },
    );

    blocTest<ArticleSummaryCubit, ArticleSummaryState>(
      'generate() con límite diario alcanzado emite LimitReached sin reportarlo',
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
        const ArticleSummaryLimitReached(dailyLimit: 25),
      ],
      verify: (_) {
        verifyNever(
          () => mockTelemetryClient.captureException(any(), any()),
        );
      },
    );

    blocTest<ArticleSummaryCubit, ArticleSummaryState>(
      'generate() con límite gratis (free tier) alcanzado emite LimitReached con dailyLimit=2',
      build: () {
        when(() => mockGenerateArticleSummary.execute(
              any(),
              language: any(named: 'language'),
            )).thenThrow(
          const ArticleSummaryGenerationException(
            AppErrorCode.aiUsageLimitReached,
          ),
        );
        when(() => mockAiUsageRepository.getStatus()).thenAnswer(
          (_) async =>
              const AiUsageStatus(summariesUsedToday: 2, dailyLimit: 2),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.generate(tArticle, 'es'),
      expect: () => [
        const ArticleSummaryLoading(),
        const ArticleSummaryLimitReached(dailyLimit: 2),
      ],
    );

    blocTest<ArticleSummaryCubit, ArticleSummaryState>(
      'showFreeTierExhausted() emite FreeTierExhausted sin llamar a la generación ni al repositorio de uso',
      build: buildCubit,
      act: (cubit) => cubit.showFreeTierExhausted(),
      expect: () => [const ArticleSummaryFreeTierExhausted()],
      verify: (_) {
        verifyNever(() => mockGenerateArticleSummary.execute(
              any(),
              language: any(named: 'language'),
            ));
        verifyNever(() => mockAiUsageRepository.getStatus());
      },
    );
  });
}
