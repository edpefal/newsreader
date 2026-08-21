import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/domain/entities/summary_source_block.dart';
import 'package:newsreader/features/summaries/domain/usecases/resolve_summary_articles.dart';
import 'package:newsreader/features/summaries/presentation/screens/summary_detail_screen.dart';

import '../../../support/pump_localized_app.dart';

class MockResolveSummaryArticles extends Mock
    implements ResolveSummaryArticles {}

Article _article({required String id, required String title}) => Article(
      id: id,
      sourceId: 's1',
      sourceName: 'Fuente A',
      title: title,
      publishedAt: DateTime(2026, 7, 9),
      articleUrl: 'https://example.com/$id',
    );

Widget _buildSubject(DailySummary summary, ResolveSummaryArticles resolver) {
  final router = GoRouter(
    initialLocation: '/summary',
    routes: [
      GoRoute(
        path: '/summary',
        builder: (_, __) => SummaryDetailScreen(
          summary: summary,
          resolveSummaryArticles: resolver,
        ),
      ),
      GoRoute(
        path: '/article/:id',
        builder: (_, state) =>
            Scaffold(body: Text('Article ${state.pathParameters['id']}')),
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
  late MockResolveSummaryArticles resolver;

  setUp(() {
    resolver = MockResolveSummaryArticles();
    when(() => resolver.execute(any())).thenAnswer((_) async => {});
  });

  final tSummary = DailySummary(
    id: '2026-07-09',
    date: DateTime(2026, 7, 9),
    content: 'Este es el texto completo del resumen de hoy.',
    articleCount: 5,
    createdAt: DateTime(2026, 7, 9),
  );

  testWidgets('muestra el texto completo, fecha y cantidad de artículos',
      (tester) async {
    await tester.pumpWidget(_buildSubject(tSummary, resolver));
    await tester.pump();

    expect(
      find.text('Este es el texto completo del resumen de hoy.'),
      findsOneWidget,
    );
    expect(find.text('5 artículos resumidos'), findsOneWidget);
    expect(find.textContaining('9 jul 2026'), findsOneWidget);
  });

  testWidgets('muestra el nombre de la fuente en negrita', (tester) async {
    final summary = DailySummary(
      id: '2026-07-09',
      date: DateTime(2026, 7, 9),
      content: 'Fuente A\nPárrafo de la fuente A.',
      articleCount: 1,
      createdAt: DateTime(2026, 7, 9),
    );

    await tester.pumpWidget(_buildSubject(summary, resolver));
    await tester.pump();

    final titleText = tester.widget<Text>(find.text('Fuente A'));
    expect(titleText.style?.fontWeight, FontWeight.bold);
  });

  testWidgets('con un solo artículo por fuente muestra un link directo',
      (tester) async {
    final article = _article(id: 'a1', title: 'Artículo único');
    final summary = DailySummary(
      id: '2026-07-09',
      date: DateTime(2026, 7, 9),
      content: 'Fuente A\nPárrafo de la fuente A.',
      articleCount: 1,
      createdAt: DateTime(2026, 7, 9),
      sourceBlocks: const [
        SummarySourceBlock(
          sourceId: 's1',
          sourceName: 'Fuente A',
          articleIds: ['a1'],
        ),
      ],
    );
    when(() => resolver.execute(['a1']))
        .thenAnswer((_) async => {'a1': article});

    await tester.pumpWidget(_buildSubject(summary, resolver));
    await tester.pumpAndSettle();

    expect(find.text('Artículo único'), findsOneWidget);

    await tester.tap(find.text('Artículo único'));
    await tester.pumpAndSettle();

    expect(find.text('Article a1'), findsOneWidget);
  });

  testWidgets('con varios artículos por fuente muestra varios links',
      (tester) async {
    final a1 = _article(id: 'a1', title: 'Primer artículo');
    final a2 = _article(id: 'a2', title: 'Segundo artículo');
    final summary = DailySummary(
      id: '2026-07-09',
      date: DateTime(2026, 7, 9),
      content: 'Fuente A\nPárrafo de la fuente A.',
      articleCount: 2,
      createdAt: DateTime(2026, 7, 9),
      sourceBlocks: const [
        SummarySourceBlock(
          sourceId: 's1',
          sourceName: 'Fuente A',
          articleIds: ['a1', 'a2'],
        ),
      ],
    );
    when(() => resolver.execute(['a1', 'a2']))
        .thenAnswer((_) async => {'a1': a1, 'a2': a2});

    await tester.pumpWidget(_buildSubject(summary, resolver));
    await tester.pumpAndSettle();

    expect(find.text('Primer artículo'), findsOneWidget);
    expect(find.text('Segundo artículo'), findsOneWidget);

    await tester.tap(find.text('Segundo artículo'));
    await tester.pumpAndSettle();

    expect(find.text('Article a2'), findsOneWidget);
  });

  testWidgets('sin sourceBlocks (resumen viejo) no muestra ningún link',
      (tester) async {
    final summary = DailySummary(
      id: '2026-07-09',
      date: DateTime(2026, 7, 9),
      content: 'Fuente A\nPárrafo de la fuente A.',
      articleCount: 1,
      createdAt: DateTime(2026, 7, 9),
    );

    await tester.pumpWidget(_buildSubject(summary, resolver));
    await tester.pumpAndSettle();

    final titleText = tester.widget<Text>(find.text('Fuente A'));
    expect(titleText.style?.fontWeight, FontWeight.bold);
    expect(find.byType(ActionChip), findsNothing);
    expect(find.byIcon(Icons.open_in_new), findsNothing);
  });

  testWidgets(
      'un articleId que no resuelve se omite sin romper el resto de los links',
      (tester) async {
    final a1 = _article(id: 'a1', title: 'Artículo existente');
    final summary = DailySummary(
      id: '2026-07-09',
      date: DateTime(2026, 7, 9),
      content: 'Fuente A\nPárrafo de la fuente A.',
      articleCount: 2,
      createdAt: DateTime(2026, 7, 9),
      sourceBlocks: const [
        SummarySourceBlock(
          sourceId: 's1',
          sourceName: 'Fuente A',
          articleIds: ['a1', 'a2-borrado'],
        ),
      ],
    );
    when(() => resolver.execute(['a1', 'a2-borrado']))
        .thenAnswer((_) async => {'a1': a1});

    await tester.pumpWidget(_buildSubject(summary, resolver));
    await tester.pumpAndSettle();

    expect(find.text('Artículo existente'), findsOneWidget);
  });
}
