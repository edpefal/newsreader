import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/daily_summary.dart';
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
      when(() => cubit.state)
          .thenReturn(const SummariesLoaded(summaries: []));

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('Sin resúmenes todavía'), findsOneWidget);
    });

    testWidgets('muestra la lista de resúmenes existentes', (tester) async {
      when(() => cubit.state)
          .thenReturn(SummariesLoaded(summaries: [tSummary]));

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.textContaining('Resumen del'), findsOneWidget);
      expect(find.text('4 artículos'), findsOneWidget);
    });

    testWidgets('tap en un item navega al detalle', (tester) async {
      when(() => cubit.state)
          .thenReturn(SummariesLoaded(summaries: [tSummary]));

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.tap(find.textContaining('Resumen del'));
      await tester.pumpAndSettle();

      expect(find.text('Detail'), findsOneWidget);
    });

    testWidgets('no muestra ningún botón de generar ni indicador de cupo',
        (tester) async {
      when(() => cubit.state)
          .thenReturn(SummariesLoaded(summaries: [tSummary]));

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.byType(FilledButton), findsNothing);
    });
  });
}
