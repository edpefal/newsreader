import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/features/inbox/domain/usecases/sync_sources.dart';
import 'package:newsreader/features/inbox/presentation/cubit/inbox_cubit.dart';
import 'package:newsreader/features/inbox/presentation/screens/inbox_screen.dart';

class MockInboxCubit extends MockCubit<InboxState> implements InboxCubit {}

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
        path: '/sources/add',
        builder: (_, __) => const Scaffold(body: Text('Agregar')),
      ),
      GoRoute(
        path: '/article/:id',
        builder: (_, __) => const Scaffold(body: Text('Reader')),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
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

      expect(find.text('Bienvenido a Newsletter Hub'), findsOneWidget);
      expect(find.text('Agregar tu primer newsletter'), findsOneWidget);
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
      await tester.tap(find.text('Agregar tu primer newsletter'));
      await tester.pumpAndSettle();

      expect(find.text('Agregar'), findsOneWidget);
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
        (_) async => const SyncResult(
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
        (_) async => const SyncResult(
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
        find.textContaining('2 fuente(s) no pudieron sincronizarse.'),
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
        'pull-to-refresh no muestra snackbar cuando sync es exitoso',
        (tester) async {
      when(() => cubit.state)
          .thenReturn(InboxLoaded(tArticles, hasSources: true));
      when(() => cubit.syncAndReload()).thenAnswer(
        (_) async => const SyncResult(synced: 3, failedSourceIds: []),
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
  });
}
