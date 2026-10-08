import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/domain/entities/summary_source_block.dart';
import 'package:newsreader/features/inbox/presentation/cubit/inbox_cubit.dart';
import 'package:newsreader/features/inbox/presentation/screens/inbox_screen.dart';
import 'package:newsreader/features/inbox/presentation/widgets/inbox_summary_card.dart';

import '../../../support/pump_localized_app.dart';

class MockInboxCubit extends MockCubit<InboxState> implements InboxCubit {}

final _summary = DailySummary(
  id: 'summary-1',
  date: DateTime(2026, 10, 7).toUtc(),
  content: 'contenido',
  articleCount: 7,
  createdAt: DateTime(2026, 10, 7).toUtc(),
  sourceBlocks: const [
    SummarySourceBlock(sourceId: 's1', sourceName: 'Alfa', articleIds: ['1']),
    SummarySourceBlock(sourceId: 's2', sourceName: 'Beta', articleIds: ['2']),
  ],
);

final _articles = [
  Article(
    id: '1',
    sourceId: 's1',
    sourceName: 'Newsletter A',
    title: 'Artículo de prueba',
    publishedAt: DateTime(2024, 1, 15),
    articleUrl: 'https://example.com/1',
  ),
];

Widget _buildSubject(InboxCubit cubit) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => BlocProvider<InboxCubit>.value(
          value: cubit,
          child: const InboxView(),
        ),
      ),
      GoRoute(
        path: '/summary/:id',
        builder: (_, state) =>
            Scaffold(body: Text('Detalle ${state.pathParameters['id']}')),
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
  late MockInboxCubit cubit;

  setUpAll(() {
    registerFallbackValue(_summary);
  });

  setUp(() {
    cubit = MockInboxCubit();
    when(() => cubit.openSummaryCard(any())).thenReturn(null);
    when(() => cubit.dismissSummary(any())).thenAnswer((_) async {});
    when(() => cubit.selectSummary(any())).thenAnswer((_) async {});
  });

  void stubLoaded({
    List<Article>? articles,
    DailySummary? pending,
    String searchQuery = '',
    String? openSummaryId,
  }) {
    when(() => cubit.state).thenReturn(
      InboxLoaded(
        articles ?? _articles,
        hasSources: true,
        searchQuery: searchQuery,
        pendingSummary: pending,
        openSummaryId: openSummaryId,
      ),
    );
  }

  testWidgets('muestra la tarjeta antes de los artículos', (tester) async {
    stubLoaded(pending: _summary);

    await tester.pumpWidget(_buildSubject(cubit));

    expect(find.byType(InboxSummaryCard), findsOneWidget);
    final cardTop = tester.getTopLeft(find.byType(InboxSummaryCard)).dy;
    final articleTop = tester.getTopLeft(find.text('Artículo de prueba')).dy;
    expect(cardTop, lessThan(articleTop));
  });

  testWidgets('sin resumen pendiente no hay tarjeta', (tester) async {
    stubLoaded();

    await tester.pumpWidget(_buildSubject(cubit));

    expect(find.byType(InboxSummaryCard), findsNothing);
    expect(find.text('Artículo de prueba'), findsOneWidget);
  });

  testWidgets('la tarjeta no se filtra con el buscador', (tester) async {
    stubLoaded(pending: _summary, searchQuery: 'nada que coincida');

    await tester.pumpWidget(_buildSubject(cubit));

    expect(find.byType(InboxSummaryCard), findsOneWidget);
    expect(find.text('Artículo de prueba'), findsNothing);
  });

  testWidgets('con el Inbox vacío la tarjeta se muestra junto al estado vacío',
      (tester) async {
    stubLoaded(articles: const [], pending: _summary);

    await tester.pumpWidget(_buildSubject(cubit));

    expect(find.byType(InboxSummaryCard), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });

  testWidgets(
      'en compact, tocar la tarjeta registra el evento y empuja el detalle',
      (tester) async {
    stubLoaded(pending: _summary);
    await tester.pumpWidget(_buildSubject(cubit));

    await tester.tap(find.byType(InboxSummaryCard));
    await tester.pumpAndSettle();

    verify(() => cubit.openSummaryCard(_summary)).called(1);
    verifyNever(() => cubit.selectSummary(any()));
    expect(find.text('Detalle summary-1'), findsOneWidget);
  });

  testWidgets('swipe endToStart descarta la tarjeta y la saca del árbol',
      (tester) async {
    stubLoaded(pending: _summary);
    await tester.pumpWidget(_buildSubject(cubit));

    await tester.drag(find.byType(InboxSummaryCard), const Offset(-700, 0));
    await tester.pumpAndSettle();

    verify(() => cubit.dismissSummary(_summary)).called(1);
    expect(find.byType(InboxSummaryCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swipe en la otra dirección no descarta', (tester) async {
    stubLoaded(pending: _summary);
    await tester.pumpWidget(_buildSubject(cubit));

    await tester.drag(find.byType(InboxSummaryCard), const Offset(700, 0));
    await tester.pumpAndSettle();

    verifyNever(() => cubit.dismissSummary(any()));
    expect(find.byType(InboxSummaryCard), findsOneWidget);
  });

  group('dos paneles (>= 840dp)', () {
    setUp(() {});

    Future<void> useWideScreen(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets('tocar la tarjeta selecciona el resumen y navega con go',
        (tester) async {
      await useWideScreen(tester);
      stubLoaded(pending: _summary);
      await tester.pumpWidget(_buildSubject(cubit));

      await tester.tap(find.byType(InboxSummaryCard));
      await tester.pumpAndSettle();

      verify(() => cubit.openSummaryCard(_summary)).called(1);
      verify(() => cubit.selectSummary(_summary)).called(1);
      expect(find.text('Detalle summary-1'), findsOneWidget);
    });

    testWidgets(
        'con el resumen abierto la tarjeta sigue visible, seleccionada y con CTA "Abierto"',
        (tester) async {
      await useWideScreen(tester);
      stubLoaded(pending: _summary, openSummaryId: 'summary-1');

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.byType(InboxSummaryCard), findsOneWidget);
      expect(find.text('Abierto'), findsOneWidget);
      final card =
          tester.widget<InboxSummaryCard>(find.byType(InboxSummaryCard));
      expect(card.isSelected, isTrue);
    });
  });

  testWidgets(
      'en compact una selección de resumen residual se limpia en vez de dejar la tarjeta fija',
      (tester) async {
    when(() => cubit.closeOpenArticle()).thenAnswer((_) async {});
    stubLoaded(pending: _summary, openSummaryId: 'summary-1');

    await tester.pumpWidget(_buildSubject(cubit));
    await tester.pump();

    expect(find.byType(InboxSummaryCard), findsNothing);
    verify(() => cubit.closeOpenArticle()).called(1);
  });
}
