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

Widget _buildSubject(
  DailySummary summary,
  ResolveSummaryArticles resolver, {
  VoidCallback? onOpened,
}) {
  final router = GoRouter(
    initialLocation: '/summary',
    routes: [
      GoRoute(
        path: '/summary',
        builder: (_, __) => SummaryDetailScreen(
          summary: summary,
          resolveSummaryArticles: resolver,
          onOpened: onOpened,
        ),
        routes: [
          GoRoute(
            path: 'article/:id',
            builder: (_, state) =>
                Scaffold(body: Text('Article ${state.pathParameters['id']}')),
          ),
        ],
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

  group('etiqueta de fuente copiada por el modelo en el encabezado', () {
    testWidgets(
        '"Fuente: X" se muestra sin la etiqueta y empareja los links de sus '
        'artículos', (tester) async {
      final a1 = _article(id: 'a1', title: 'Primer artículo');
      final a2 = _article(id: 'a2', title: 'Segundo artículo');
      final summary = DailySummary(
        id: '2026-10-03',
        date: DateTime(2026, 10, 3),
        content: 'Fuente: Fuente A\nPárrafo de la fuente A.',
        articleCount: 2,
        createdAt: DateTime(2026, 10, 3),
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

      final titleText = tester.widget<Text>(find.text('Fuente A'));
      expect(titleText.style?.fontWeight, FontWeight.bold);
      expect(find.text('Fuente: Fuente A'), findsNothing);
      expect(find.text('Primer artículo'), findsOneWidget);
      expect(find.text('Segundo artículo'), findsOneWidget);
    });

    testWidgets('"Source : X" (francés) también empareja el link',
        (tester) async {
      final a1 = _article(id: 'a1', title: 'Artículo único');
      final summary = DailySummary(
        id: '2026-10-03',
        date: DateTime(2026, 10, 3),
        content: 'Source : Fuente A\nPárrafo de la fuente A.',
        articleCount: 1,
        createdAt: DateTime(2026, 10, 3),
        sourceBlocks: const [
          SummarySourceBlock(
            sourceId: 's1',
            sourceName: 'Fuente A',
            articleIds: ['a1'],
          ),
        ],
      );
      when(() => resolver.execute(['a1']))
          .thenAnswer((_) async => {'a1': a1});

      await tester.pumpWidget(_buildSubject(summary, resolver));
      await tester.pumpAndSettle();

      expect(find.text('Source : Fuente A'), findsNothing);
      expect(find.text('Fuente A'), findsOneWidget);
      expect(find.text('Artículo único'), findsOneWidget);
    });

    testWidgets(
        'una etiqueta cuyo resto no coincide con ninguna fuente muestra el '
        'título sin la etiqueta y sin links', (tester) async {
      final summary = DailySummary(
        id: '2026-10-03',
        date: DateTime(2026, 10, 3),
        content: 'Fuente: Otra cosa\nPárrafo.',
        articleCount: 1,
        createdAt: DateTime(2026, 10, 3),
        sourceBlocks: const [
          SummarySourceBlock(
            sourceId: 's1',
            sourceName: 'Fuente A',
            articleIds: ['a1'],
          ),
        ],
      );

      await tester.pumpWidget(_buildSubject(summary, resolver));
      await tester.pumpAndSettle();

      final titleText = tester.widget<Text>(find.text('Otra cosa'));
      expect(titleText.style?.fontWeight, FontWeight.bold);
      expect(find.byType(ActionChip), findsNothing);
      expect(find.byIcon(Icons.open_in_new), findsNothing);
    });

    testWidgets(
        'una fuente cuyo nombre real empieza con la etiqueta sigue '
        'emparejando por igualdad exacta', (tester) async {
      final a1 = _article(id: 'a1', title: 'Artículo único');
      final summary = DailySummary(
        id: '2026-10-03',
        date: DateTime(2026, 10, 3),
        content: 'Fuente: Reporte\nPárrafo.',
        articleCount: 1,
        createdAt: DateTime(2026, 10, 3),
        sourceBlocks: const [
          SummarySourceBlock(
            sourceId: 's1',
            sourceName: 'Fuente: Reporte',
            articleIds: ['a1'],
          ),
        ],
      );
      when(() => resolver.execute(['a1']))
          .thenAnswer((_) async => {'a1': a1});

      await tester.pumpWidget(_buildSubject(summary, resolver));
      await tester.pumpAndSettle();

      expect(find.text('Fuente: Reporte'), findsOneWidget);
      expect(find.text('Artículo único'), findsOneWidget);
    });
  });

  testWidgets('invoca onOpened una sola vez al mostrarse', (tester) async {
    var opened = 0;
    await tester.pumpWidget(
      _buildSubject(tSummary, resolver, onOpened: () => opened++),
    );
    await tester.pumpAndSettle();

    expect(opened, 1);

    // Un rebuild de la misma pantalla no lo vuelve a disparar.
    await tester.pump();
    expect(opened, 1);
  });
}
