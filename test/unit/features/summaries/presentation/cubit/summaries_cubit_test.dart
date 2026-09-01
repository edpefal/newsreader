import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/ai/summary_generator.dart';
import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/subscription/subscription_status_provider.dart';
import 'package:newsreader/features/summaries/domain/usecases/generate_daily_summary.dart';
import 'package:newsreader/features/summaries/domain/usecases/get_daily_summaries.dart';
import 'package:newsreader/features/summaries/presentation/cubit/summaries_cubit.dart';

import '../../../../../support/fake_telemetry_client.dart';

class MockGetDailySummaries extends Mock implements GetDailySummaries {}

class MockGenerateDailySummary extends Mock implements GenerateDailySummary {}

class MockSubscriptionStatusProvider extends Mock
    implements SubscriptionStatusProvider {}

void main() {
  late MockGetDailySummaries mockGetDailySummaries;
  late MockGenerateDailySummary mockGenerateDailySummary;
  late MockSubscriptionStatusProvider mockSubscriptionStatusProvider;
  late MockTelemetryClient mockTelemetryClient;

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
        mockTelemetryClient,
      );

  setUpAll(() {
    registerFallbackValue(StackTrace.empty);
  });

  setUp(() {
    mockGetDailySummaries = MockGetDailySummaries();
    mockGenerateDailySummary = MockGenerateDailySummary();
    mockSubscriptionStatusProvider = MockSubscriptionStatusProvider();
    mockTelemetryClient = MockTelemetryClient();
    when(() => mockSubscriptionStatusProvider.isSubscribed).thenReturn(true);
    // Sin resumen generado hoy por defecto: la mayoría de los tests
    // existentes ejercitan la generación en sí, no el gate de "ya generado
    // hoy" (que tiene su propio grupo más abajo).
    when(() => mockGenerateDailySummary.hasGeneratedToday())
        .thenAnswer((_) async => false);
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
          alreadyGeneratedToday: false,
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
          alreadyGeneratedToday: false,
        ),
      ],
    );

    blocTest<SummariesCubit, SummariesState>(
      'loadSummaries() emite canGenerateToday=false y alreadyGeneratedToday=true '
      'si ya se generó el resumen de hoy, aunque haya artículos',
      build: () {
        when(() => mockGetDailySummaries.execute())
            .thenAnswer((_) async => [tSummary]);
        when(() => mockGenerateDailySummary.countTodayArticles())
            .thenAnswer((_) async => 3);
        when(() => mockGenerateDailySummary.hasGeneratedToday())
            .thenAnswer((_) async => true);
        return buildCubit();
      },
      act: (cubit) => cubit.loadSummaries(),
      expect: () => [
        const SummariesLoading(),
        SummariesLoaded(
          summaries: [tSummary],
          canGenerateToday: false,
          alreadyGeneratedToday: true,
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
        alreadyGeneratedToday: false,
      ),
      act: (cubit) => cubit.generateTodaySummary('es'),
      expect: () => [
        const SummaryGenerating([]),
        SummariesLoaded(
          summaries: [tSummary],
          canGenerateToday: false,
          alreadyGeneratedToday: true,
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
        alreadyGeneratedToday: false,
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
        alreadyGeneratedToday: false,
      ),
      act: (cubit) => cubit.generateTodaySummary('es'),
      expect: () => [
        const SummaryGenerating([]),
        const SummaryGenerationError(
          summaries: [],
          canGenerateToday: false,
          code: AppErrorCode.noArticlesToday,
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
        alreadyGeneratedToday: false,
      ),
      act: (cubit) => cubit.generateTodaySummary('es'),
      expect: () => [
        const SummaryGenerating([]),
        const SummaryGenerationError(
          summaries: [],
          canGenerateToday: true,
          code: AppErrorCode.generationFailed,
        ),
      ],
      verify: (_) {
        verify(
          () => mockTelemetryClient.captureException(any(), any()),
        ).called(1);
      },
    );

    blocTest<SummariesCubit, SummariesState>(
      'generateTodaySummary() rechazado por el backend por resumen ya '
      'generado hoy emite SummaryGenerationError sin reportarlo a '
      'observability',
      build: () {
        when(() => mockGenerateDailySummary.execute(language: any(named: 'language')))
            .thenThrow(
          const SummaryGenerationException(
            AppErrorCode.dailySummaryAlreadyGenerated,
          ),
        );
        when(() => mockGenerateDailySummary.countTodayArticles())
            .thenAnswer((_) async => 2);
        when(() => mockGenerateDailySummary.hasGeneratedToday())
            .thenAnswer((_) async => true);
        return buildCubit();
      },
      seed: () => SummariesLoaded(
        summaries: const [],
        canGenerateToday: true,
        alreadyGeneratedToday: false,
      ),
      act: (cubit) => cubit.generateTodaySummary('es'),
      expect: () => [
        const SummaryGenerating([]),
        const SummaryGenerationError(
          summaries: [],
          canGenerateToday: false,
          code: AppErrorCode.dailySummaryAlreadyGenerated,
        ),
      ],
      verify: (_) {
        verifyNever(
          () => mockTelemetryClient.captureException(any(), any()),
        );
      },
    );

    blocTest<SummariesCubit, SummariesState>(
      'generateTodaySummary() rechazado localmente por resumen ya generado '
      'hoy (chequeo local stale) emite SummaryGenerationError sin '
      'reportarlo a observability',
      build: () {
        when(() => mockGenerateDailySummary.execute(language: any(named: 'language')))
            .thenThrow(const DailySummaryAlreadyGeneratedException());
        return buildCubit();
      },
      seed: () => SummariesLoaded(
        summaries: const [],
        canGenerateToday: true,
        alreadyGeneratedToday: false,
      ),
      act: (cubit) => cubit.generateTodaySummary('es'),
      expect: () => [
        const SummaryGenerating([]),
        const SummaryGenerationError(
          summaries: [],
          canGenerateToday: false,
          code: AppErrorCode.dailySummaryAlreadyGenerated,
        ),
      ],
      verify: (_) {
        verifyNever(
          () => mockTelemetryClient.captureException(any(), any()),
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
        alreadyGeneratedToday: false,
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
        alreadyGeneratedToday: false,
      ),
      act: (cubit) => cubit.generateTodaySummary('es'),
      expect: () => [
        const SummaryGenerating([]),
        SummariesLoaded(
          summaries: [tSummary],
          canGenerateToday: false,
          alreadyGeneratedToday: true,
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
        alreadyGeneratedToday: false,
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
  });
}
