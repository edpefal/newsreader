import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/core/feed/feed_sync_trigger.dart';
import 'package:newsreader/features/inbox/presentation/cubit/inbox_cubit.dart';
import 'package:newsreader/features/inbox/presentation/screens/inbox_screen.dart';

import '../../../support/pump_localized_app.dart';

class MockInboxCubit extends MockCubit<InboxState> implements InboxCubit {}

Widget _buildSubject(InboxCubit cubit, {NewsSource? sourceToReturnOnAdd}) {
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
        path: '/sources/add',
        builder: (context, __) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).pop(sourceToReturnOnAdd),
            child: const Text('Agregar'),
          ),
        ),
      ),
      GoRoute(
        path: '/sources/:id',
        builder: (context, state) => Scaffold(
          body: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Detalle${state.uri.queryParameters['justAdded'] == 'true' ? ' (justAdded)' : ''}',
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      ),
      GoRoute(
        path: '/article/:id',
        builder: (_, __) => const Scaffold(body: Text('Reader')),
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

  final tArticles = [
    Article(
      id: '1',
      sourceId: 's1',
      sourceName: 'Newsletter A',
      title: 'Artículo de prueba',
      publishedAt: DateTime(2024, 1, 15),
      articleUrl: 'https://example.com/1',
    ),
    Article(
      id: '2',
      sourceId: 's1',
      sourceName: 'Newsletter A',
      title: 'Otro artículo',
      publishedAt: DateTime(2024, 1, 14),
      articleUrl: 'https://example.com/2',
    ),
  ];

  setUp(() {
    cubit = MockInboxCubit();
  });

  group('InboxScreen', () {
    testWidgets('muestra spinner cuando estado es InboxLoading', (tester) async {
      when(() => cubit.state).thenReturn(const InboxLoading());

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra onboarding cuando no hay fuentes ni artículos',
        (tester) async {
      when(() => cubit.state)
          .thenReturn(const InboxLoaded([], hasSources: false));

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('Bienvenido a Reevo'), findsOneWidget);
      expect(find.text('Agrega tu primera fuente'), findsOneWidget);
    });

    testWidgets(
        'muestra estado al día cuando hay fuentes pero no artículos',
        (tester) async {
      when(() => cubit.state)
          .thenReturn(const InboxLoaded([], hasSources: true));

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('Estás al día'), findsOneWidget);
      expect(find.text('Desliza para actualizar.'), findsOneWidget);
    });

    testWidgets('muestra lista de artículos cuando hay artículos',
        (tester) async {
      when(() => cubit.state)
          .thenReturn(InboxLoaded(tArticles, hasSources: true));

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('Artículo de prueba'), findsOneWidget);
      expect(find.text('Otro artículo'), findsOneWidget);
    });

    testWidgets(
        'muestra la lista aunque el último estado conocido traiga readArticleId '
        '(ej. InboxView remontada tras rotar con un artículo ya leído en modo split)',
        (tester) async {
      when(() => cubit.state).thenReturn(
        InboxLoaded(tArticles, hasSources: true, readArticleId: 'old-id'),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('Artículo de prueba'), findsOneWidget);
      expect(find.text('Otro artículo'), findsOneWidget);
      expect(find.text('Estás al día'), findsNothing);
    });

    testWidgets('cada artículo muestra el nombre de la fuente', (tester) async {
      when(() => cubit.state)
          .thenReturn(InboxLoaded(tArticles, hasSources: true));

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.textContaining('Newsletter A'), findsWidgets);
    });

    testWidgets('botón onboarding navega a /sources/add', (tester) async {
      when(() => cubit.state)
          .thenReturn(const InboxLoaded([], hasSources: false));
      when(() => cubit.loadArticles()).thenAnswer((_) async {});

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.tap(find.text('Agrega tu primera fuente'));
      await tester.pumpAndSettle();

      expect(find.text('Agregar'), findsOneWidget);
    });

    testWidgets(
        'botón onboarding, al agregar una fuente, recarga los artículos y '
        'navega a su detalle con justAdded',
        (tester) async {
      when(() => cubit.state)
          .thenReturn(const InboxLoaded([], hasSources: false));
      when(() => cubit.loadArticles()).thenAnswer((_) async {});
      final addedSource = NewsSource(
        id: 'new-1',
        name: 'Newsletter Nueva',
        feedUrl: 'https://nueva.com/feed',
        addedAt: DateTime(2024),
      );

      await tester.pumpWidget(
        _buildSubject(cubit, sourceToReturnOnAdd: addedSource),
      );
      await tester.tap(find.text('Agrega tu primera fuente'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Agregar'));
      await tester.pumpAndSettle();

      verify(() => cubit.loadArticles()).called(1);
      expect(find.text('Detalle (justAdded)'), findsOneWidget);
    });

    testWidgets(
        'botón onboarding recarga los artículos otra vez al volver de la '
        'pantalla de detalle (sincronizada mientras tanto)',
        (tester) async {
      when(() => cubit.state)
          .thenReturn(const InboxLoaded([], hasSources: false));
      when(() => cubit.loadArticles()).thenAnswer((_) async {});
      final addedSource = NewsSource(
        id: 'new-1',
        name: 'Newsletter Nueva',
        feedUrl: 'https://nueva.com/feed',
        addedAt: DateTime(2024),
      );

      await tester.pumpWidget(
        _buildSubject(cubit, sourceToReturnOnAdd: addedSource),
      );
      await tester.tap(find.text('Agrega tu primera fuente'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Agregar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();

      verify(() => cubit.loadArticles()).called(2);
    });

    testWidgets(
        'muestra LinearProgressIndicator cuando isSyncingInBackground es true sin ocultar los artículos',
        (tester) async {
      when(() => cubit.state).thenReturn(
        InboxLoaded(tArticles, hasSources: true, isSyncingInBackground: true),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Artículo de prueba'), findsOneWidget);
    });

    testWidgets(
        'no muestra LinearProgressIndicator cuando isSyncingInBackground es false',
        (tester) async {
      when(() => cubit.state)
          .thenReturn(InboxLoaded(tArticles, hasSources: true));

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('muestra RefreshIndicator cuando el estado es InboxLoaded',
        (tester) async {
      when(() => cubit.state)
          .thenReturn(InboxLoaded(tArticles, hasSources: true));

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets(
        'pull-to-refresh llama a syncAndReload y muestra snackbar de red',
        (tester) async {
      when(() => cubit.state)
          .thenReturn(InboxLoaded(tArticles, hasSources: true));
      when(() => cubit.syncAndReload()).thenAnswer(
        (_) async => const FeedSyncResult(
          synced: 0,
          failedSourceIds: ['s1'],
          isNetworkError: true,
        ),
      );

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.fling(find.byType(AnimatedList), const Offset(0, 400), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(
        find.text('Sin conexión. Los artículos descargados siguen disponibles.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'pull-to-refresh muestra snackbar de fallos parciales',
        (tester) async {
      when(() => cubit.state)
          .thenReturn(InboxLoaded(tArticles, hasSources: true));
      when(() => cubit.syncAndReload()).thenAnswer(
        (_) async => const FeedSyncResult(
          synced: 1,
          failedSourceIds: ['s1', 's2'],
        ),
      );

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.fling(find.byType(AnimatedList), const Offset(0, 400), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('2 fuentes no pudieron sincronizarse.'),
        findsOneWidget,
      );
    });

    testWidgets('tap en artículo navega al reader', (tester) async {
      when(() => cubit.state)
          .thenReturn(InboxLoaded(tArticles, hasSources: true));

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.tap(find.text('Artículo de prueba'));
      await tester.pumpAndSettle();

      expect(find.text('Reader'), findsOneWidget);
    });

    testWidgets(
        'en modo split (ancho expanded), tap en artículo lo selecciona en vez '
        'de marcarlo como leído de inmediato (queda resaltado, no se archiva)',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(() => cubit.state)
          .thenReturn(InboxLoaded(tArticles, hasSources: true));
      when(() => cubit.selectArticle(any())).thenAnswer((_) async {});

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.tap(find.text('Artículo de prueba'));
      await tester.pumpAndSettle();

      // Se selecciona (para resaltarlo en la columna central) en vez de
      // marcarse leído de inmediato -- el archivado se difiere hasta que el
      // usuario cierre explícitamente esa selección (chevron o elegir otro
      // artículo). Ver proposal.md de `highlight-selected-inbox-article`.
      verify(() => cubit.selectArticle('1')).called(1);
      verifyNever(() => cubit.markAsRead(any()));
    });

    testWidgets(
        'en modo split, el artículo con openArticleId se resalta con secondaryContainer',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(() => cubit.state).thenReturn(
        InboxLoaded(tArticles, hasSources: true, openArticleId: '1'),
      );

      final widget = _buildSubject(cubit);
      await tester.pumpWidget(widget);

      final theme = Theme.of(tester.element(find.text('Artículo de prueba')));
      final openTileMaterial = tester.widget<Material>(
        find
            .ancestor(
              of: find.text('Artículo de prueba'),
              matching: find.byType(Material),
            )
            .first,
      );
      final closedTileMaterial = tester.widget<Material>(
        find
            .ancestor(
              of: find.text('Otro artículo'),
              matching: find.byType(Material),
            )
            .first,
      );

      expect(openTileMaterial.color, theme.colorScheme.secondaryContainer);
      expect(closedTileMaterial.color, Colors.transparent);
    });

    testWidgets(
        'al cambiar la selección abierta (openArticleId), el artículo previo '
        'se anima hacia afuera y el nuevo queda resaltado',
        (tester) async {
      final openFirstState = InboxLoaded(
        tArticles,
        hasSources: true,
        openArticleId: '1',
      );
      final switchedState = InboxLoaded(
        [tArticles[1]],
        hasSources: true,
        readArticleId: '1',
        openArticleId: '2',
      );

      whenListen(
        cubit,
        Stream.fromIterable([switchedState]),
        initialState: openFirstState,
      );

      await tester.pumpWidget(_buildSubject(cubit));
      expect(find.text('Artículo de prueba'), findsOneWidget);
      expect(find.text('Otro artículo'), findsOneWidget);

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Artículo de prueba'), findsNothing);
      expect(find.text('Otro artículo'), findsOneWidget);

      final theme = Theme.of(tester.element(find.text('Otro artículo')));
      final remainingTileMaterial = tester.widget<Material>(
        find
            .ancestor(
              of: find.text('Otro artículo'),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(
        remainingTileMaterial.color,
        theme.colorScheme.secondaryContainer,
      );
    });

    testWidgets(
        'pull-to-refresh no muestra snackbar cuando sync es exitoso',
        (tester) async {
      when(() => cubit.state)
          .thenReturn(InboxLoaded(tArticles, hasSources: true));
      when(() => cubit.syncAndReload()).thenAnswer(
        (_) async => const FeedSyncResult(synced: 3, failedSourceIds: []),
      );

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.fling(find.byType(AnimatedList), const Offset(0, 400), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('muestra separadores de fecha con "Hoy" y "Ayer"', (tester) async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final todayArticle = Article(
        id: 'today',
        sourceId: 's1',
        sourceName: 'Newsletter A',
        title: 'Artículo de hoy',
        publishedAt: DateTime(now.year, now.month, now.day, 10),
        articleUrl: 'https://example.com/today',
      );
      final yesterdayArticle = Article(
        id: 'yesterday',
        sourceId: 's1',
        sourceName: 'Newsletter A',
        title: 'Artículo de ayer',
        publishedAt: DateTime(yesterday.year, yesterday.month, yesterday.day, 10),
        articleUrl: 'https://example.com/yesterday',
      );

      when(() => cubit.state).thenReturn(
        InboxLoaded([todayArticle, yesterdayArticle], hasSources: true),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('Hoy'), findsOneWidget);
      expect(find.text('Ayer'), findsOneWidget);
    });

    testWidgets('agrupa artículos del mismo día bajo un único separador',
        (tester) async {
      final now = DateTime.now();
      final article1 = Article(
        id: 'a1',
        sourceId: 's1',
        sourceName: 'Newsletter A',
        title: 'Artículo A',
        publishedAt: DateTime(now.year, now.month, now.day, 9),
        articleUrl: 'https://example.com/a1',
      );
      final article2 = Article(
        id: 'a2',
        sourceId: 's1',
        sourceName: 'Newsletter A',
        title: 'Artículo B',
        publishedAt: DateTime(now.year, now.month, now.day, 8),
        articleUrl: 'https://example.com/a2',
      );

      when(() => cubit.state)
          .thenReturn(InboxLoaded([article1, article2], hasSources: true));

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('Hoy'), findsOneWidget);
    });

    testWidgets('animación de dismiss elimina el artículo leído de la lista',
        (tester) async {
      final initialState = InboxLoaded(tArticles, hasSources: true);
      final afterReadState = InboxLoaded(
        [tArticles[1]],
        hasSources: true,
        readArticleId: '1',
      );

      whenListen(
        cubit,
        Stream.fromIterable([afterReadState]),
        initialState: initialState,
      );

      await tester.pumpWidget(_buildSubject(cubit));
      expect(find.text('Artículo de prueba'), findsOneWidget);
      expect(find.text('Otro artículo'), findsOneWidget);

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Artículo de prueba'), findsNothing);
      expect(find.text('Otro artículo'), findsOneWidget);
    });

    testWidgets(
        'estado "sin resultados" se muestra distinto al estado sin fuentes',
        (tester) async {
      when(() => cubit.state).thenReturn(
        const InboxLoaded([], hasSources: true, searchQuery: 'algo'),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('Sin resultados'), findsOneWidget);
      expect(find.text('Estás al día'), findsNothing);
    });
  });
}
