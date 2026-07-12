import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/features/summaries/presentation/cubit/summaries_cubit.dart';
import 'package:newsreader/features/summaries/presentation/screens/summaries_screen.dart';

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
  return MaterialApp.router(routerConfig: router);
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
        const SummariesLoaded(summaries: [], canGenerateToday: false),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('Sin resúmenes todavía'), findsOneWidget);
    });

    testWidgets('botón deshabilitado cuando no hay artículos hoy',
        (tester) async {
      when(() => cubit.state).thenReturn(
        const SummariesLoaded(summaries: [], canGenerateToday: false),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('botón habilitado cuando hay artículos hoy', (tester) async {
      when(() => cubit.state).thenReturn(
        const SummariesLoaded(summaries: [], canGenerateToday: true),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('muestra la lista de resúmenes existentes', (tester) async {
      when(() => cubit.state).thenReturn(
        SummariesLoaded(summaries: [tSummary], canGenerateToday: true),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.textContaining('Resumen del'), findsOneWidget);
      expect(find.text('4 artículos'), findsOneWidget);
    });

    testWidgets('tap en el botón invoca generateTodaySummary', (tester) async {
      when(() => cubit.state).thenReturn(
        const SummariesLoaded(summaries: [], canGenerateToday: true),
      );
      when(() => cubit.generateTodaySummary()).thenAnswer((_) async {});

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.tap(find.byType(FilledButton));

      verify(() => cubit.generateTodaySummary()).called(1);
    });

    testWidgets('tap en un item navega al detalle', (tester) async {
      when(() => cubit.state).thenReturn(
        SummariesLoaded(summaries: [tSummary], canGenerateToday: true),
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
          message: 'No se pudo generar el resumen. Intentá de nuevo.',
        ),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      expect(
        find.text('No se pudo generar el resumen. Intentá de nuevo.'),
        findsOneWidget,
      );
    });
  });
}
