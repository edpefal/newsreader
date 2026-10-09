import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/core/domain/entities/summary_source_block.dart';
import 'package:newsreader/features/summaries/domain/usecases/resolve_summary_articles.dart';
import 'package:newsreader/features/summaries/domain/usecases/resolve_summary_sources.dart';
import 'package:newsreader/features/summaries/presentation/screens/summary_detail_screen.dart';
import 'package:newsreader/features/summaries/presentation/widgets/summary_article_row.dart';
import 'package:newsreader/features/summaries/presentation/widgets/summary_source_card.dart';

import '../../../support/pump_localized_app.dart';

class MockResolveSummaryArticles extends Mock
    implements ResolveSummaryArticles {}

class MockResolveSummarySources extends Mock implements ResolveSummarySources {}

NewsSource _source({required String id, String? iconUrl}) => NewsSource(
  id: id,
  name: 'Fuente A',
  feedUrl: 'https://example.com/$id.xml',
  iconUrl: iconUrl,
  addedAt: DateTime(2026, 7, 1),
);

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
  ResolveSummaryArticles resolver,
  ResolveSummarySources sourcesResolver, {
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
          resolveSummarySources: sourcesResolver,
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
  late MockResolveSummarySources sourcesResolver;

  setUp(() {
    resolver = MockResolveSummaryArticles();
    when(() => resolver.execute(any())).thenAnswer((_) async => {});
    sourcesResolver = MockResolveSummarySources();
    when(() => sourcesResolver.execute(any())).thenAnswer((_) async => {});
  });

  final tSummary = DailySummary(
    id: '2026-07-09',
    date: DateTime(2026, 7, 9),
    content: 'Este es el texto completo del resumen de hoy.',
    articleCount: 5,
    createdAt: DateTime(2026, 7, 9),
  );

  testWidgets('muestra el texto completo, fecha y cantidad de artículos', (
    tester,
  ) async {
    await tester.pumpWidget(_buildSubject(tSummary, resolver, sourcesResolver));
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

    await tester.pumpWidget(_buildSubject(summary, resolver, sourcesResolver));
    await tester.pump();

    final titleText = tester.widget<Text>(find.text('Fuente A'));
    expect(titleText.style?.fontWeight, FontWeight.bold);
  });

  testWidgets('con un solo artículo por fuente muestra un link directo', (
    tester,
  ) async {
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
    when(
      () => resolver.execute(['a1']),
    ).thenAnswer((_) async => {'a1': article});

    await tester.pumpWidget(_buildSubject(summary, resolver, sourcesResolver));
    await tester.pumpAndSettle();

    expect(find.text('Artículo único'), findsOneWidget);

    await tester.tap(find.text('Artículo único'));
    await tester.pumpAndSettle();

    expect(find.text('Article a1'), findsOneWidget);
  });

  testWidgets('con varios artículos por fuente muestra varios links', (
    tester,
  ) async {
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
    when(
      () => resolver.execute(['a1', 'a2']),
    ).thenAnswer((_) async => {'a1': a1, 'a2': a2});

    await tester.pumpWidget(_buildSubject(summary, resolver, sourcesResolver));
    await tester.pumpAndSettle();

    expect(find.text('Primer artículo'), findsOneWidget);
    expect(find.text('Segundo artículo'), findsOneWidget);

    await tester.tap(find.text('Segundo artículo'));
    await tester.pumpAndSettle();

    expect(find.text('Article a2'), findsOneWidget);
  });

  testWidgets('sin sourceBlocks (resumen viejo) no muestra ningún link', (
    tester,
  ) async {
    final summary = DailySummary(
      id: '2026-07-09',
      date: DateTime(2026, 7, 9),
      content: 'Fuente A\nPárrafo de la fuente A.',
      articleCount: 1,
      createdAt: DateTime(2026, 7, 9),
    );

    await tester.pumpWidget(_buildSubject(summary, resolver, sourcesResolver));
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
      when(
        () => resolver.execute(['a1', 'a2-borrado']),
      ).thenAnswer((_) async => {'a1': a1});

      await tester.pumpWidget(
        _buildSubject(summary, resolver, sourcesResolver),
      );
      await tester.pumpAndSettle();

      expect(find.text('Artículo existente'), findsOneWidget);
    },
  );

  group('etiqueta de fuente copiada por el modelo en el encabezado', () {
    testWidgets(
      '"Fuente: X" se muestra sin la etiqueta y empareja los links de sus '
      'artículos',
      (tester) async {
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
        when(
          () => resolver.execute(['a1', 'a2']),
        ).thenAnswer((_) async => {'a1': a1, 'a2': a2});

        await tester.pumpWidget(
          _buildSubject(summary, resolver, sourcesResolver),
        );
        await tester.pumpAndSettle();

        final titleText = tester.widget<Text>(find.text('Fuente A'));
        expect(titleText.style?.fontWeight, FontWeight.bold);
        expect(find.text('Fuente: Fuente A'), findsNothing);
        expect(find.text('Primer artículo'), findsOneWidget);
        expect(find.text('Segundo artículo'), findsOneWidget);
      },
    );

    testWidgets('"Source : X" (francés) también empareja el link', (
      tester,
    ) async {
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
      when(() => resolver.execute(['a1'])).thenAnswer((_) async => {'a1': a1});

      await tester.pumpWidget(
        _buildSubject(summary, resolver, sourcesResolver),
      );
      await tester.pumpAndSettle();

      expect(find.text('Source : Fuente A'), findsNothing);
      expect(find.text('Fuente A'), findsOneWidget);
      expect(find.text('Artículo único'), findsOneWidget);
    });

    testWidgets(
      'una etiqueta cuyo resto no coincide con ninguna fuente muestra el '
      'título sin la etiqueta y sin links',
      (tester) async {
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

        await tester.pumpWidget(
          _buildSubject(summary, resolver, sourcesResolver),
        );
        await tester.pumpAndSettle();

        final titleText = tester.widget<Text>(find.text('Otra cosa'));
        expect(titleText.style?.fontWeight, FontWeight.bold);
        expect(find.byType(ActionChip), findsNothing);
        expect(find.byIcon(Icons.open_in_new), findsNothing);
      },
    );

    testWidgets('una fuente cuyo nombre real empieza con la etiqueta sigue '
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
      when(() => resolver.execute(['a1'])).thenAnswer((_) async => {'a1': a1});

      await tester.pumpWidget(
        _buildSubject(summary, resolver, sourcesResolver),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fuente: Reporte'), findsOneWidget);
      expect(find.text('Artículo único'), findsOneWidget);
    });
  });

  group('tarjetas por fuente', () {
    DailySummary twoSourcesSummary() => DailySummary(
      id: '2026-07-09',
      date: DateTime(2026, 7, 9),
      content: 'Fuente A\nPárrafo A.\n\nFuente B\nPárrafo B.',
      articleCount: 3,
      createdAt: DateTime(2026, 7, 9),
      sourceBlocks: const [
        SummarySourceBlock(
          sourceId: 's1',
          sourceName: 'Fuente A',
          articleIds: ['a1', 'a2'],
        ),
        SummarySourceBlock(
          sourceId: 's2',
          sourceName: 'Fuente B',
          articleIds: ['b1'],
        ),
      ],
    );

    testWidgets('cabecera muestra "N artículos de M fuentes"', (tester) async {
      await tester.pumpWidget(
        _buildSubject(twoSourcesSummary(), resolver, sourcesResolver),
      );
      await tester.pumpAndSettle();

      expect(find.text('3 artículos de 2 fuentes'), findsOneWidget);
    });

    testWidgets('cabecera usa singular con 1 artículo de 1 fuente', (
      tester,
    ) async {
      final summary = DailySummary(
        id: '2026-07-09',
        date: DateTime(2026, 7, 9),
        content: 'Fuente A\nPárrafo A.',
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

      await tester.pumpWidget(
        _buildSubject(summary, resolver, sourcesResolver),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 artículo de 1 fuente'), findsOneWidget);
    });

    testWidgets('sin sourceBlocks la cabecera solo cuenta artículos', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSubject(tSummary, resolver, sourcesResolver),
      );
      await tester.pumpAndSettle();

      expect(find.text('5 artículos resumidos'), findsOneWidget);
      expect(find.byType(SummarySourceCard), findsNothing);
    });

    testWidgets('cada bloque emparejado es una tarjeta con contador', (
      tester,
    ) async {
      final a1 = _article(id: 'a1', title: 'Primero');
      final a2 = _article(id: 'a2', title: 'Segundo');
      final b1 = _article(id: 'b1', title: 'Tercero');
      when(
        () => resolver.execute(['a1', 'a2', 'b1']),
      ).thenAnswer((_) async => {'a1': a1, 'a2': a2, 'b1': b1});
      when(() => sourcesResolver.execute(['s1', 's2'])).thenAnswer(
        (_) async => {'s1': _source(id: 's1'), 's2': _source(id: 's2')},
      );

      await tester.pumpWidget(
        _buildSubject(twoSourcesSummary(), resolver, sourcesResolver),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SummarySourceCard), findsNWidgets(2));
      expect(find.byType(SummaryArticleRow), findsNWidgets(3));
      expect(find.text('2 artículos'), findsOneWidget);
      expect(find.text('1 artículo'), findsOneWidget);
    });

    testWidgets('fuente eliminada conserva la tarjeta con la inicial', (
      tester,
    ) async {
      final a1 = _article(id: 'a1', title: 'Primero');
      when(
        () => resolver.execute(['a1', 'a2', 'b1']),
      ).thenAnswer((_) async => {'a1': a1});

      await tester.pumpWidget(
        _buildSubject(twoSourcesSummary(), resolver, sourcesResolver),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SummarySourceCard), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byType(SummarySourceCard).first,
          matching: find.text('F'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('artículo sin imagen muestra el ícono de documento', (
      tester,
    ) async {
      final a1 = _article(id: 'a1', title: 'Sin imagen');
      when(() => resolver.execute(['a1'])).thenAnswer((_) async => {'a1': a1});
      final summary = DailySummary(
        id: '2026-07-09',
        date: DateTime(2026, 7, 9),
        content: 'Fuente A\nPárrafo A.',
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

      await tester.pumpWidget(
        _buildSubject(summary, resolver, sourcesResolver),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.article_outlined), findsOneWidget);
    });

    testWidgets('el contador cuenta solo los artículos que se muestran', (
      tester,
    ) async {
      final a1 = _article(id: 'a1', title: 'Existente');
      when(
        () => resolver.execute(['a1', 'a2', 'b1']),
      ).thenAnswer((_) async => {'a1': a1});

      await tester.pumpWidget(
        _buildSubject(twoSourcesSummary(), resolver, sourcesResolver),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SummaryArticleRow), findsOneWidget);
      expect(find.text('1 artículo'), findsOneWidget);
      expect(find.text('2 artículos'), findsNothing);
    });

    testWidgets('un bloque sin match no es tarjeta', (tester) async {
      final summary = DailySummary(
        id: '2026-07-09',
        date: DateTime(2026, 7, 9),
        content: 'Otra cosa\nPárrafo.',
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

      await tester.pumpWidget(
        _buildSubject(summary, resolver, sourcesResolver),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SummarySourceCard), findsNothing);
      expect(find.text('Otra cosa'), findsOneWidget);
    });

    testWidgets('el contenido se limita a 680 de ancho en pantallas anchas', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final a1 = _article(id: 'a1', title: 'Primero');
      when(
        () => resolver.execute(['a1', 'a2', 'b1']),
      ).thenAnswer((_) async => {'a1': a1});

      await tester.pumpWidget(
        _buildSubject(twoSourcesSummary(), resolver, sourcesResolver),
      );
      await tester.pumpAndSettle();

      final width = tester.getSize(find.byType(SummarySourceCard).first).width;
      expect(width, lessThanOrEqualTo(680));
    });
  });

  testWidgets('invoca onOpened una sola vez al mostrarse', (tester) async {
    var opened = 0;
    await tester.pumpWidget(
      _buildSubject(
        tSummary,
        resolver,
        sourcesResolver,
        onOpened: () => opened++,
      ),
    );
    await tester.pumpAndSettle();

    expect(opened, 1);

    // Un rebuild de la misma pantalla no lo vuelve a disparar.
    await tester.pump();
    expect(opened, 1);
  });
}
