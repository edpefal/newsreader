import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/features/summaries/presentation/cubit/summaries_cubit.dart';
import 'package:newsreader/features/summaries/presentation/screens/summaries_screen.dart';

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
        const SummariesLoaded(
          summaries: [],
          canGenerateToday: false,
          alreadyGeneratedToday: false,
          isSubscribed: true,
          freeTierAvailable: true,
        ),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('Sin resúmenes todavía'), findsOneWidget);
    });

    testWidgets('botón deshabilitado cuando no hay artículos hoy',
        (tester) async {
      when(() => cubit.state).thenReturn(
        const SummariesLoaded(
          summaries: [],
          canGenerateToday: false,
          alreadyGeneratedToday: false,
          isSubscribed: true,
          freeTierAvailable: true,
        ),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('botón habilitado cuando hay artículos hoy', (tester) async {
      when(() => cubit.state).thenReturn(
        const SummariesLoaded(
          summaries: [],
          canGenerateToday: true,
          alreadyGeneratedToday: false,
          isSubscribed: true,
          freeTierAvailable: true,
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
          alreadyGeneratedToday: false,
          isSubscribed: true,
          freeTierAvailable: true,
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
        const SummariesLoaded(
          summaries: [],
          canGenerateToday: true,
          alreadyGeneratedToday: false,
          isSubscribed: true,
          freeTierAvailable: true,
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
          alreadyGeneratedToday: false,
          isSubscribed: true,
          freeTierAvailable: true,
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
        const SummaryGenerationError(
          summaries: [],
          canGenerateToday: true,
          code: AppErrorCode.generationFailed,
        ),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      expect(
        find.text('Algo salió mal. Intenta de nuevo.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'muestra mensaje de resumen ya generado tras rechazo del backend',
        (tester) async {
      when(() => cubit.state).thenReturn(
        const SummaryGenerationError(
          summaries: [],
          canGenerateToday: false,
          code: AppErrorCode.dailySummaryAlreadyGenerated,
        ),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      expect(
        find.text('Ya generaste el resumen de hoy. Vuelve mañana para crear uno nuevo.'),
        findsOneWidget,
      );
    });
  });

  group('indicador de resumen ya generado hoy', () {
    testWidgets('muestra el indicador y deshabilita el botón cuando ya se '
        'generó el resumen de hoy', (tester) async {
      when(() => cubit.state).thenReturn(
        const SummariesLoaded(
          summaries: [],
          canGenerateToday: false,
          alreadyGeneratedToday: true,
          isSubscribed: true,
          freeTierAvailable: true,
        ),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      expect(
        find.text('Ya generaste el resumen de hoy. Vuelve mañana para crear uno nuevo.'),
        findsOneWidget,
      );
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('no muestra el indicador cuando todavía no se generó el '
        'resumen de hoy', (tester) async {
      when(() => cubit.state).thenReturn(
        const SummariesLoaded(
          summaries: [],
          canGenerateToday: true,
          alreadyGeneratedToday: false,
          isSubscribed: true,
          freeTierAvailable: true,
        ),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      expect(
        find.text('Ya generaste el resumen de hoy. Vuelve mañana para crear uno nuevo.'),
        findsNothing,
      );
    });
  });

  group('indicador de cupo gratis semanal', () {
    testWidgets('muestra el contador de cupo disponible sin suscripción',
        (tester) async {
      when(() => cubit.state).thenReturn(
        const SummariesLoaded(
          summaries: [],
          canGenerateToday: true,
          alreadyGeneratedToday: false,
          isSubscribed: false,
          freeTierAvailable: true,
        ),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      expect(
        find.text('Te queda 1 resumen gratis esta semana'),
        findsOneWidget,
      );
    });

    testWidgets('muestra el mensaje de cupo agotado sin suscripción',
        (tester) async {
      when(() => cubit.state).thenReturn(
        const SummariesLoaded(
          summaries: [],
          canGenerateToday: true,
          alreadyGeneratedToday: false,
          isSubscribed: false,
          freeTierAvailable: false,
        ),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      expect(
        find.text(
          'Ya usaste tu resumen gratis de esta semana — se renueva el lunes, '
          'o suscríbete para tener un resumen todos los días',
        ),
        findsOneWidget,
      );
    });

    testWidgets('no muestra ningún indicador de cupo gratis con suscripción '
        'activa', (tester) async {
      when(() => cubit.state).thenReturn(
        const SummariesLoaded(
          summaries: [],
          canGenerateToday: true,
          alreadyGeneratedToday: false,
          isSubscribed: true,
          freeTierAvailable: false,
        ),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('Te queda 1 resumen gratis esta semana'), findsNothing);
      expect(
        find.text(
          'Ya usaste tu resumen gratis de esta semana — se renueva el lunes, '
          'o suscríbete para tener un resumen todos los días',
        ),
        findsNothing,
      );
    });
  });
}
