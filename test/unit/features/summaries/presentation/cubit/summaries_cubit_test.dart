import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/ai/summary_generator.dart';
import 'package:newsreader/core/ai_usage/ai_usage_policy.dart';
import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/subscription/subscription_status_provider.dart';
import 'package:newsreader/features/summaries/domain/usecases/generate_daily_summary.dart';
import 'package:newsreader/features/summaries/domain/usecases/get_daily_summaries.dart';
import 'package:newsreader/features/summaries/presentation/cubit/summaries_cubit.dart';

import '../../../../../support/fake_ai_usage_policy.dart';
import '../../../../../support/fake_observability_client.dart';

class MockGetDailySummaries extends Mock implements GetDailySummaries {}

class MockGenerateDailySummary extends Mock implements GenerateDailySummary {}

class MockSubscriptionStatusProvider extends Mock
    implements SubscriptionStatusProvider {}

void main() {
  late MockGetDailySummaries mockGetDailySummaries;
  late MockGenerateDailySummary mockGenerateDailySummary;
  late MockSubscriptionStatusProvider mockSubscriptionStatusProvider;
  late MockObservabilityClient mockObservabilityClient;
  late MockAiUsagePolicy mockAiUsagePolicy;

  final tSummary = DailySummary(
    id: '2026-07-09',
    date: DateTime(2026, 7, 9),
    content: 'Resumen de hoy',
    articleCount: 4,
    createdAt: DateTime(2026, 7, 9),
  );

  SummariesCubit buildCubit() => SummariesCubit(
        mockGetDailySummaries,
        mockGenerateDailySummary,
        mockSubscriptionStatusProvider,
        mockObservabilityClient,
        mockAiUsagePolicy,
      );

  setUpAll(() {
    registerFallbackValue(StackTrace.empty);
  });

  setUp(() {
    mockGetDailySummaries = MockGetDailySummaries();
    mockGenerateDailySummary = MockGenerateDailySummary();
    mockSubscriptionStatusProvider = MockSubscriptionStatusProvider();
    mockObservabilityClient = MockObservabilityClient();
    mockAiUsagePolicy = MockAiUsagePolicy();
    when(() => mockSubscriptionStatusProvider.isSubscribed).thenReturn(true);
    // Consumo dentro del presupuesto por defecto: la mayoría de los tests
    // existentes ejercitan la generación en sí, no el medidor/límite (que
    // tiene su propio grupo de tests más abajo).
    when(() => mockAiUsagePolicy.getStatus())
        .thenAnswer((_) async => tAiUsageStatusNotReached);
  });

  group('SummariesCubit', () {
    test('estado inicial es SummariesLoading', () {
      expect(buildCubit().state, const SummariesLoading());
    });

    blocTest<SummariesCubit, SummariesState>(
      'loadSummaries() emite Loaded con canGenerateToday=true si hay artículos hoy',
      build: () {
        when(() => mockGetDailySummaries.execute())
            .thenAnswer((_) async => [tSummary]);
        when(() => mockGenerateDailySummary.countTodayArticles())
            .thenAnswer((_) async => 3);
        return buildCubit();
      },
      act: (cubit) => cubit.loadSummaries(),
      expect: () => [
        const SummariesLoading(),
        SummariesLoaded(
          summaries: [tSummary],
          canGenerateToday: true,
          usage: tAiUsageStatusNotReached,
        ),
      ],
    );

    blocTest<SummariesCubit, SummariesState>(
      'loadSummaries() emite canGenerateToday=false sin artículos hoy',
      build: () {
        when(() => mockGetDailySummaries.execute())
            .thenAnswer((_) async => []);
        when(() => mockGenerateDailySummary.countTodayArticles())
            .thenAnswer((_) async => 0);
        return buildCubit();
      },
      act: (cubit) => cubit.loadSummaries(),
      expect: () => [
        const SummariesLoading(),
        SummariesLoaded(
          summaries: const [],
          canGenerateToday: false,
          usage: tAiUsageStatusNotReached,
        ),
      ],
    );

    blocTest<SummariesCubit, SummariesState>(
      'loadSummaries() expone el AiUsageStatus devuelto por AiUsagePolicy',
      build: () {
        when(() => mockGetDailySummaries.execute())
            .thenAnswer((_) async => []);
        when(() => mockGenerateDailySummary.countTodayArticles())
            .thenAnswer((_) async => 0);
        when(() => mockAiUsagePolicy.getStatus()).thenAnswer(
          (_) async => AiUsageStatus(
            wordsUsed: 25000,
            wordLimit: 30000,
            resetsAt: DateTime.utc(2026, 1, 2),
          ),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.loadSummaries(),
      expect: () => [
        const SummariesLoading(),
        SummariesLoaded(
          summaries: const [],
          canGenerateToday: false,
          usage: AiUsageStatus(
            wordsUsed: 25000,
            wordLimit: 30000,
            resetsAt: DateTime.utc(2026, 1, 2),
          ),
        ),
      ],
    );

    blocTest<SummariesCubit, SummariesState>(
      'generateTodaySummary() emite Generating y luego Loaded con el nuevo resumen',
      build: () {
        when(() => mockGenerateDailySummary.execute(language: any(named: 'language')))
            .thenAnswer((_) async => tSummary);
        return buildCubit();
      },
      seed: () => SummariesLoaded(
        summaries: const [],
        canGenerateToday: true,
        usage: tAiUsageStatusNotReached,
      ),
      act: (cubit) => cubit.generateTodaySummary('es'),
      expect: () => [
        SummaryGenerating(const [], tAiUsageStatusNotReached),
        SummariesLoaded(
          summaries: [tSummary],
          canGenerateToday: true,
          usage: tAiUsageStatusNotReached,
        ),
      ],
    );

    blocTest<SummariesCubit, SummariesState>(
      'generateTodaySummary() threadea el language recibido hasta el usecase',
      build: () {
        when(() => mockGenerateDailySummary.execute(language: any(named: 'language')))
            .thenAnswer((_) async => tSummary);
        return buildCubit();
      },
      seed: () => SummariesLoaded(
        summaries: const [],
        canGenerateToday: true,
        usage: tAiUsageStatusNotReached,
      ),
      act: (cubit) => cubit.generateTodaySummary('fr'),
      verify: (_) {
        verify(() => mockGenerateDailySummary.execute(language: 'fr')).called(1);
      },
    );

    blocTest<SummariesCubit, SummariesState>(
      'generateTodaySummary() sin artículos hoy emite SummaryGenerationError',
      build: () {
        when(() => mockGenerateDailySummary.execute(language: any(named: 'language')))
            .thenThrow(const NoArticlesTodayException());
        return buildCubit();
      },
      seed: () => SummariesLoaded(
        summaries: const [],
        canGenerateToday: false,
        usage: tAiUsageStatusNotReached,
      ),
      act: (cubit) => cubit.generateTodaySummary('es'),
      expect: () => [
        SummaryGenerating(const [], tAiUsageStatusNotReached),
        SummaryGenerationError(
          summaries: const [],
          canGenerateToday: false,
          code: AppErrorCode.noArticlesToday,
          usage: tAiUsageStatusNotReached,
        ),
      ],
    );

    blocTest<SummariesCubit, SummariesState>(
      'generateTodaySummary() con falla del modelo emite SummaryGenerationError',
      build: () {
        when(() => mockGenerateDailySummary.execute(language: any(named: 'language')))
            .thenThrow(Exception('modelo no disponible'));
        when(() => mockGenerateDailySummary.countTodayArticles())
            .thenAnswer((_) async => 2);
        return buildCubit();
      },
      seed: () => SummariesLoaded(
        summaries: const [],
        canGenerateToday: true,
        usage: tAiUsageStatusNotReached,
      ),
      act: (cubit) => cubit.generateTodaySummary('es'),
      expect: () => [
        SummaryGenerating(const [], tAiUsageStatusNotReached),
        SummaryGenerationError(
          summaries: const [],
          canGenerateToday: true,
          code: AppErrorCode.generationFailed,
          usage: tAiUsageStatusNotReached,
        ),
      ],
      verify: (_) {
        verify(
          () => mockObservabilityClient.captureException(any(), any()),
        ).called(1);
      },
    );

    blocTest<SummariesCubit, SummariesState>(
      'generateTodaySummary() con presupuesto de IA agotado emite '
      'SummaryGenerationError sin reportarlo a observability',
      build: () {
        when(() => mockGenerateDailySummary.execute(language: any(named: 'language')))
            .thenThrow(
          const SummaryGenerationException(AppErrorCode.aiUsageLimitReached),
        );
        when(() => mockGenerateDailySummary.countTodayArticles())
            .thenAnswer((_) async => 2);
        return buildCubit();
      },
      seed: () => SummariesLoaded(
        summaries: const [],
        canGenerateToday: true,
        usage: tAiUsageStatusNotReached,
      ),
      act: (cubit) => cubit.generateTodaySummary('es'),
      expect: () => [
        SummaryGenerating(const [], tAiUsageStatusNotReached),
        SummaryGenerationError(
          summaries: const [],
          canGenerateToday: true,
          code: AppErrorCode.aiUsageLimitReached,
          usage: tAiUsageStatusNotReached,
        ),
      ],
      verify: (_) {
        verifyNever(
          () => mockObservabilityClient.captureException(any(), any()),
        );
      },
    );

    blocTest<SummariesCubit, SummariesState>(
      'generateTodaySummary() sin suscripción activa muestra el paywall '
      'en vez de generar',
      build: () {
        when(() => mockSubscriptionStatusProvider.isSubscribed)
            .thenReturn(false);
        when(
          () => mockSubscriptionStatusProvider.showPaywall(
            onSubscribed: any(named: 'onSubscribed'),
          ),
        ).thenAnswer((_) async {});
        return buildCubit();
      },
      seed: () => SummariesLoaded(
        summaries: const [],
        canGenerateToday: true,
        usage: tAiUsageStatusNotReached,
      ),
      act: (cubit) => cubit.generateTodaySummary('es'),
      expect: () => <SummariesState>[],
      verify: (_) {
        verify(
          () => mockSubscriptionStatusProvider.showPaywall(
            onSubscribed: any(named: 'onSubscribed'),
          ),
        ).called(1);
        verifyNever(() => mockGenerateDailySummary.execute(language: any(named: 'language')));
      },
    );

    blocTest<SummariesCubit, SummariesState>(
      'generateTodaySummary() sin suscripción activa dispara la generación '
      'automáticamente si el usuario completa la compra desde el paywall',
      build: () {
        var isSubscribed = false;
        when(() => mockSubscriptionStatusProvider.isSubscribed)
            .thenAnswer((_) => isSubscribed);
        when(
          () => mockSubscriptionStatusProvider.showPaywall(
            onSubscribed: any(named: 'onSubscribed'),
          ),
        ).thenAnswer((invocation) async {
          // Simula que Superwall actualiza `subscriptionStatus` (compra
          // completada) antes de invocar el callback `feature`/`onSubscribed`.
          isSubscribed = true;
          final onSubscribed = invocation.namedArguments[#onSubscribed]
              as Future<void> Function();
          await onSubscribed();
        });
        when(() => mockGenerateDailySummary.execute(language: any(named: 'language')))
            .thenAnswer((_) async => tSummary);
        return buildCubit();
      },
      seed: () => SummariesLoaded(
        summaries: const [],
        canGenerateToday: true,
        usage: tAiUsageStatusNotReached,
      ),
      act: (cubit) => cubit.generateTodaySummary('es'),
      expect: () => [
        SummaryGenerating(const [], tAiUsageStatusNotReached),
        SummariesLoaded(
          summaries: [tSummary],
          canGenerateToday: true,
          usage: tAiUsageStatusNotReached,
        ),
      ],
    );

    blocTest<SummariesCubit, SummariesState>(
      'generateTodaySummary() NO genera si el paywall invoca onSubscribed '
      'sin que la suscripción esté realmente activa (ej. feature_gating '
      'mal configurado en Superwall, o el usuario cerró el paywall sin '
      'comprar)',
      build: () {
        when(() => mockSubscriptionStatusProvider.isSubscribed)
            .thenReturn(false);
        when(
          () => mockSubscriptionStatusProvider.showPaywall(
            onSubscribed: any(named: 'onSubscribed'),
          ),
        ).thenAnswer((invocation) async {
          final onSubscribed = invocation.namedArguments[#onSubscribed]
              as Future<void> Function();
          // `isSubscribed` nunca pasa a `true` -- simula un paywall que
          // invoca `feature` igual (non_gated) o que el usuario lo cerró
          // sin completar la compra.
          await onSubscribed();
        });
        return buildCubit();
      },
      seed: () => SummariesLoaded(
        summaries: const [],
        canGenerateToday: true,
        usage: tAiUsageStatusNotReached,
      ),
      act: (cubit) => cubit.generateTodaySummary('es'),
      expect: () => <SummariesState>[],
      verify: (_) {
        verifyNever(
          () => mockGenerateDailySummary.execute(
            language: any(named: 'language'),
          ),
        );
      },
    );

    blocTest<SummariesCubit, SummariesState>(
      'generateTodaySummary() refresca el AiUsageStatus tras generar exitosamente',
      build: () {
        when(() => mockGenerateDailySummary.execute(language: any(named: 'language')))
            .thenAnswer((_) async => tSummary);
        // El usage inicial viene del estado ya cargado (seed), no de
        // getStatus() -- este stub cubre el refresh que pasa después de
        // generar, reflejando las palabras recién consumidas.
        when(() => mockAiUsagePolicy.getStatus()).thenAnswer(
          (_) async => AiUsageStatus(
            wordsUsed: 5000,
            wordLimit: 30000,
            resetsAt: DateTime.utc(2026, 1, 2),
          ),
        );
        return buildCubit();
      },
      seed: () => SummariesLoaded(
        summaries: const [],
        canGenerateToday: true,
        usage: tAiUsageStatusNotReached,
      ),
      act: (cubit) => cubit.generateTodaySummary('es'),
      expect: () => [
        SummaryGenerating(const [], tAiUsageStatusNotReached),
        SummariesLoaded(
          summaries: [tSummary],
          canGenerateToday: true,
          usage: AiUsageStatus(
            wordsUsed: 5000,
            wordLimit: 30000,
            resetsAt: DateTime.utc(2026, 1, 2),
          ),
        ),
      ],
    );
  });
}
