import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/subscription/subscription_status_provider.dart';
import 'package:newsreader/features/summaries/domain/usecases/generate_daily_summary.dart';
import 'package:newsreader/features/summaries/domain/usecases/get_daily_summaries.dart';
import 'package:newsreader/features/summaries/presentation/cubit/summaries_cubit.dart';

class MockGetDailySummaries extends Mock implements GetDailySummaries {}

class MockGenerateDailySummary extends Mock implements GenerateDailySummary {}

class MockSubscriptionStatusProvider extends Mock
    implements SubscriptionStatusProvider {}

void main() {
  late MockGetDailySummaries mockGetDailySummaries;
  late MockGenerateDailySummary mockGenerateDailySummary;
  late MockSubscriptionStatusProvider mockSubscriptionStatusProvider;

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
      );

  setUp(() {
    mockGetDailySummaries = MockGetDailySummaries();
    mockGenerateDailySummary = MockGenerateDailySummary();
    mockSubscriptionStatusProvider = MockSubscriptionStatusProvider();
    // Suscripción activa por defecto: la mayoría de los tests existentes
    // ejercitan la generación en sí, no el gate del paywall (que tiene su
    // propio grupo de tests más abajo).
    when(() => mockSubscriptionStatusProvider.isSubscribed).thenReturn(true);
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
        SummariesLoaded(summaries: [tSummary], canGenerateToday: true),
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
        const SummariesLoaded(summaries: [], canGenerateToday: false),
      ],
    );

    blocTest<SummariesCubit, SummariesState>(
      'generateTodaySummary() emite Generating y luego Loaded con el nuevo resumen',
      build: () {
        when(() => mockGenerateDailySummary.execute())
            .thenAnswer((_) async => tSummary);
        return buildCubit();
      },
      seed: () => const SummariesLoaded(summaries: [], canGenerateToday: true),
      act: (cubit) => cubit.generateTodaySummary(),
      expect: () => [
        const SummaryGenerating([]),
        SummariesLoaded(summaries: [tSummary], canGenerateToday: true),
      ],
    );

    blocTest<SummariesCubit, SummariesState>(
      'generateTodaySummary() sin artículos hoy emite SummaryGenerationError',
      build: () {
        when(() => mockGenerateDailySummary.execute())
            .thenThrow(const NoArticlesTodayException());
        return buildCubit();
      },
      seed: () =>
          const SummariesLoaded(summaries: [], canGenerateToday: false),
      act: (cubit) => cubit.generateTodaySummary(),
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
        when(() => mockGenerateDailySummary.execute())
            .thenThrow(Exception('modelo no disponible'));
        when(() => mockGenerateDailySummary.countTodayArticles())
            .thenAnswer((_) async => 2);
        return buildCubit();
      },
      seed: () => const SummariesLoaded(summaries: [], canGenerateToday: true),
      act: (cubit) => cubit.generateTodaySummary(),
      expect: () => [
        const SummaryGenerating([]),
        const SummaryGenerationError(
          summaries: [],
          canGenerateToday: true,
          code: AppErrorCode.generationFailed,
        ),
      ],
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
      seed: () => const SummariesLoaded(summaries: [], canGenerateToday: true),
      act: (cubit) => cubit.generateTodaySummary(),
      expect: () => <SummariesState>[],
      verify: (_) {
        verify(
          () => mockSubscriptionStatusProvider.showPaywall(
            onSubscribed: any(named: 'onSubscribed'),
          ),
        ).called(1);
        verifyNever(() => mockGenerateDailySummary.execute());
      },
    );

    blocTest<SummariesCubit, SummariesState>(
      'generateTodaySummary() sin suscripción activa dispara la generación '
      'automáticamente si el usuario completa la compra desde el paywall',
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
          await onSubscribed();
        });
        when(() => mockGenerateDailySummary.execute())
            .thenAnswer((_) async => tSummary);
        return buildCubit();
      },
      seed: () => const SummariesLoaded(summaries: [], canGenerateToday: true),
      act: (cubit) => cubit.generateTodaySummary(),
      expect: () => [
        const SummaryGenerating([]),
        SummariesLoaded(summaries: [tSummary], canGenerateToday: true),
      ],
    );
  });
}
