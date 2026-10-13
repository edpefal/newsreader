import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/features/summaries/domain/usecases/resolve_summary_articles.dart';
import 'package:newsreader/features/summaries/domain/usecases/resolve_summary_sources.dart';
import 'package:newsreader/features/summaries/presentation/cubit/summaries_cubit.dart';
import 'package:newsreader/features/summaries/presentation/screens/summaries_screen.dart';
import 'package:newsreader/features/summaries/presentation/widgets/summary_detail_body.dart';

import '../../../support/pump_localized_app.dart';

class MockSummariesCubit extends MockCubit<SummariesState>
    implements SummariesCubit {}

class MockResolveSummaryArticles extends Mock
    implements ResolveSummaryArticles {}

class MockResolveSummarySources extends Mock implements ResolveSummarySources {}

Widget _buildSubject(
  SummariesCubit cubit, {
  void Function(String)? onSummaryOpened,
}) {
  return MaterialApp(
    locale: testLocale,
    localizationsDelegates: testLocalizationsDelegates,
    supportedLocales: testSupportedLocales,
    home: BlocProvider<SummariesCubit>.value(
      value: cubit,
      child: SummariesView(
        resolveSummaryArticles: MockResolveSummaryArticles(),
        resolveSummarySources: MockResolveSummarySources(),
        onSummaryOpened: onSummaryOpened,
      ),
    ),
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
    testWidgets('muestra spinner cuando estado es SummariesLoading', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(const SummariesLoading());

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'sin resumen muestra el estado vacío que explica que habrá otro',
      (tester) async {
        when(
          () => cubit.state,
        ).thenReturn(const SummariesLoaded(summary: null));

        await tester.pumpWidget(_buildSubject(cubit));

        expect(find.text('Sin resúmenes todavía'), findsOneWidget);
        expect(find.textContaining('Se creará uno'), findsOneWidget);
        expect(find.byType(SummaryDetailBody), findsNothing);
      },
    );

    testWidgets('con resumen lo muestra directo, sin lista ni AppBar propia', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(SummariesLoaded(summary: tSummary));

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.pumpAndSettle();

      expect(find.byType(SummaryDetailBody), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
      expect(find.byType(AppBar), findsNothing);
      expect(find.text('Resumen de hoy'), findsOneWidget);
    });

    testWidgets('abrir la tab notifica el id del resumen mostrado', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(SummariesLoaded(summary: tSummary));
      final opened = <String>[];

      await tester.pumpWidget(
        _buildSubject(cubit, onSummaryOpened: opened.add),
      );
      await tester.pumpAndSettle();

      expect(opened, ['2026-07-09']);
    });

    testWidgets('no muestra ningún botón de generar ni indicador de cupo', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(SummariesLoaded(summary: tSummary));

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.byType(FilledButton), findsNothing);
    });
  });
}
