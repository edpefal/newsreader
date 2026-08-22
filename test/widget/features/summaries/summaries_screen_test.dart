import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/ai_usage/ai_usage_policy.dart';
import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/features/summaries/presentation/cubit/summaries_cubit.dart';
import 'package:newsreader/features/summaries/presentation/screens/summaries_screen.dart';

import '../../../support/fake_ai_usage_policy.dart';
import '../../../support/pump_localized_app.dart';

class MockSummariesCubit extends MockCubit<SummariesState>
    implements SummariesCubit {}

Widget _buildSubject(SummariesCubit cubit) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => BlocProvider<SummariesCubit>.value(
          value: cubit,
          child: const SummariesView(),
        ),
      ),
      GoRoute(
        path: '/summaries/:date',
        builder: (_, __) => const Scaffold(body: Text('Detail')),
      ),
    ],
  );
  return MaterialApp.router(
    locale: testLocale,
    localizationsDelegates: testLocalizationsDelegates,
    supportedLocales: testSupportedLocales,
    routerConfig: router,
  );
}

void main() {
  late MockSummariesCubit cubit;

  final tSummary = DailySummary(
    id: '2026-07-09',
    date: DateTime(2026, 7, 9),
    content: 'Resumen de hoy',
    articleCount: 4,
    createdAt: DateTime(2026, 7, 9),
  );

  setUp(() {
    cubit = MockSummariesCubit();
    // La mayoría de los tests no ejercitan el diálogo de confirmación (que
    // tiene su propio grupo más abajo) -- por defecto se comporta como si
    // hubiera artículos nuevos, así que el tap procede directo.
    when(() => cubit.wouldRegenerateWithSameArticles())
        .thenAnswer((_) async => false);
  });

  group('SummariesScreen', () {
    testWidgets('muestra spinner cuando estado es SummariesLoading',
        (tester) async {
      when(() => cubit.state).thenReturn(const SummariesLoading());

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra estado vacío sin resúmenes', (tester) async {
      when(() => cubit.state).thenReturn(
        SummariesLoaded(
          summaries: const [],
          canGenerateToday: false,
          usage: tAiUsageStatusNotReached,
        ),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('Sin resúmenes todavía'), findsOneWidget);
    });

    testWidgets('botón deshabilitado cuando no hay artículos hoy',
        (tester) async {
      when(() => cubit.state).thenReturn(
        SummariesLoaded(
          summaries: const [],
          canGenerateToday: false,
          usage: tAiUsageStatusNotReached,
        ),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('botón habilitado cuando hay artículos hoy', (tester) async {
      when(() => cubit.state).thenReturn(
        SummariesLoaded(
          summaries: const [],
          canGenerateToday: true,
          usage: tAiUsageStatusNotReached,
        ),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('muestra la lista de resúmenes existentes', (tester) async {
      when(() => cubit.state).thenReturn(
        SummariesLoaded(
          summaries: [tSummary],
          canGenerateToday: true,
          usage: tAiUsageStatusNotReached,
        ),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.textContaining('Resumen del'), findsOneWidget);
      expect(find.text('4 artículos'), findsOneWidget);
    });

    testWidgets(
        'tap en el botón invoca generateTodaySummary con el languageCode del locale activo',
        (tester) async {
      when(() => cubit.state).thenReturn(
        SummariesLoaded(
          summaries: const [],
          canGenerateToday: true,
          usage: tAiUsageStatusNotReached,
        ),
      );
      when(() => cubit.generateTodaySummary(any())).thenAnswer((_) async {});

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      verify(() => cubit.generateTodaySummary(testLocale.languageCode)).called(1);
    });

    testWidgets('tap en un item navega al detalle', (tester) async {
      when(() => cubit.state).thenReturn(
        SummariesLoaded(
          summaries: [tSummary],
          canGenerateToday: true,
          usage: tAiUsageStatusNotReached,
        ),
      );

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.tap(find.textContaining('Resumen del'));
      await tester.pumpAndSettle();

      expect(find.text('Detail'), findsOneWidget);
    });

    testWidgets('muestra mensaje de error cuando falla la generación',
        (tester) async {
      when(() => cubit.state).thenReturn(
        SummaryGenerationError(
          summaries: const [],
          canGenerateToday: true,
          code: AppErrorCode.generationFailed,
          usage: tAiUsageStatusNotReached,
        ),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      expect(
        find.text('Algo salió mal. Intenta de nuevo.'),
        findsOneWidget,
      );
    });

    testWidgets('muestra mensaje de límite de IA alcanzado tras rechazo del backend',
        (tester) async {
      when(() => cubit.state).thenReturn(
        SummaryGenerationError(
          summaries: const [],
          canGenerateToday: true,
          code: AppErrorCode.aiUsageLimitReached,
          usage: AiUsageStatus(
            wordsUsed: 30000,
            wordLimit: 30000,
            resetsAt: DateTime.utc(2026, 1, 2),
          ),
        ),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      expect(
        find.text('Alcanzaste el límite diario de uso de IA. Intenta de nuevo mañana.'),
        findsOneWidget,
      );
    });
  });

  group('medidor de consumo de IA', () {
    testWidgets('muestra las palabras consumidas y el límite diario',
        (tester) async {
      when(() => cubit.state).thenReturn(
        SummariesLoaded(
          summaries: const [],
          canGenerateToday: true,
          usage: AiUsageStatus(
            wordsUsed: 6300,
            wordLimit: 30000,
            resetsAt: DateTime.utc(2026, 1, 2),
          ),
        ),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('6300 / 30000 palabras usadas hoy'), findsOneWidget);
    });

    testWidgets('botón deshabilitado cuando el consumo alcanzó el límite,'
        ' aunque haya artículos hoy', (tester) async {
      when(() => cubit.state).thenReturn(
        SummariesLoaded(
          summaries: const [],
          canGenerateToday: true,
          usage: AiUsageStatus(
            wordsUsed: 30000,
            wordLimit: 30000,
            resetsAt: DateTime.utc(2026, 1, 2),
          ),
        ),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });
  });

  group('confirmación antes de regenerar sin artículos nuevos', () {
    testWidgets('muestra el diálogo cuando regenerar traería el mismo conteo',
        (tester) async {
      when(() => cubit.state).thenReturn(
        SummariesLoaded(
          summaries: const [],
          canGenerateToday: true,
          usage: tAiUsageStatusNotReached,
        ),
      );
      when(() => cubit.wouldRegenerateWithSameArticles())
          .thenAnswer((_) async => true);

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('¿Regenerar igual?'), findsOneWidget);
      verifyNever(() => cubit.generateTodaySummary(any()));
    });

    testWidgets('confirmar el diálogo dispara la generación', (tester) async {
      when(() => cubit.state).thenReturn(
        SummariesLoaded(
          summaries: const [],
          canGenerateToday: true,
          usage: tAiUsageStatusNotReached,
        ),
      );
      when(() => cubit.wouldRegenerateWithSameArticles())
          .thenAnswer((_) async => true);
      when(() => cubit.generateTodaySummary(any())).thenAnswer((_) async {});

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Regenerar igual'));
      await tester.pumpAndSettle();

      verify(() => cubit.generateTodaySummary(testLocale.languageCode)).called(1);
    });

    testWidgets('cancelar el diálogo no dispara la generación', (tester) async {
      when(() => cubit.state).thenReturn(
        SummariesLoaded(
          summaries: const [],
          canGenerateToday: true,
          usage: tAiUsageStatusNotReached,
        ),
      );
      when(() => cubit.wouldRegenerateWithSameArticles())
          .thenAnswer((_) async => true);

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('¿Regenerar igual?'), findsNothing);
      verifyNever(() => cubit.generateTodaySummary(any()));
    });
  });
}
