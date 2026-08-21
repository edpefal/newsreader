import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/core/feed/feed_sync_trigger.dart';
import 'package:newsreader/features/sources/domain/usecases/get_source_articles.dart';
import 'package:newsreader/features/sources/presentation/cubit/source_detail_cubit.dart';
import 'package:newsreader/features/sources/presentation/screens/source_detail_screen.dart';
import 'package:newsreader/features/sync/domain/usecases/sync_user_data.dart';

import '../../../support/pump_localized_app.dart';

class MockSourceDetailCubit extends MockCubit<SourceDetailState>
    implements SourceDetailCubit {}

class MockGetSourceArticles extends Mock implements GetSourceArticles {}

class MockFeedSyncTrigger extends Mock implements FeedSyncTrigger {}

class MockSyncUserData extends Mock implements SyncUserData {}

Widget _buildSubject(SourceDetailCubit cubit, String sourceName) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => BlocProvider<SourceDetailCubit>.value(
          value: cubit,
          child: SourceDetailView(sourceName: sourceName),
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
  late MockSourceDetailCubit cubit;

  final tSource = NewsSource(
    id: 's1',
    name: 'Newsletter A',
    feedUrl: 'https://example.com/feed',
    addedAt: DateTime(2024),
  );

  final tArticles = [
    Article(
      id: 'a1',
      sourceId: 's1',
      sourceName: 'Newsletter A',
      title: 'Artículo uno',
      publishedAt: DateTime(2024, 3, 15),
      articleUrl: 'https://example.com/1',
    ),
    Article(
      id: 'a2',
      sourceId: 's1',
      sourceName: 'Newsletter A',
      title: 'Artículo dos',
      publishedAt: DateTime(2024, 3, 14),
      articleUrl: 'https://example.com/2',
    ),
  ];

  setUp(() {
    cubit = MockSourceDetailCubit();
  });

  group('SourceDetailScreen', () {
    testWidgets('muestra spinner cuando estado es SourceDetailLoading', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(const SourceDetailLoading());

      await tester.pumpWidget(_buildSubject(cubit, tSource.name));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra el nombre de la fuente en el AppBar', (tester) async {
      when(() => cubit.state).thenReturn(const SourceDetailLoaded([]));

      await tester.pumpWidget(_buildSubject(cubit, tSource.name));

      expect(find.text('Newsletter A'), findsOneWidget);
    });

    testWidgets('muestra estado vacío cuando no hay artículos', (tester) async {
      when(() => cubit.state).thenReturn(const SourceDetailLoaded([]));

      await tester.pumpWidget(_buildSubject(cubit, tSource.name));

      expect(find.text('Sin publicaciones'), findsOneWidget);
      expect(find.byIcon(Icons.article_outlined), findsOneWidget);
    });

    testWidgets('muestra lista de artículos cuando hay publicaciones', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(SourceDetailLoaded(tArticles));

      await tester.pumpWidget(_buildSubject(cubit, tSource.name));

      expect(find.text('Artículo uno'), findsOneWidget);
      expect(find.text('Artículo dos'), findsOneWidget);
    });

    testWidgets('muestra separadores de fecha agrupando artículos por día', (
      tester,
    ) async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final articles = [
        Article(
          id: 'hoy',
          sourceId: 's1',
          sourceName: 'Newsletter A',
          title: 'Artículo de hoy',
          publishedAt: DateTime(now.year, now.month, now.day, 10),
          articleUrl: 'https://example.com/hoy',
        ),
        Article(
          id: 'ayer',
          sourceId: 's1',
          sourceName: 'Newsletter A',
          title: 'Artículo de ayer',
          publishedAt: DateTime(
            yesterday.year,
            yesterday.month,
            yesterday.day,
            10,
          ),
          articleUrl: 'https://example.com/ayer',
        ),
      ];

      when(() => cubit.state).thenReturn(SourceDetailLoaded(articles));

      await tester.pumpWidget(_buildSubject(cubit, tSource.name));

      expect(find.text('Hoy'), findsOneWidget);
      expect(find.text('Ayer'), findsOneWidget);
    });

    testWidgets('tap en artículo navega al reader', (tester) async {
      when(() => cubit.state).thenReturn(SourceDetailLoaded(tArticles));

      await tester.pumpWidget(_buildSubject(cubit, tSource.name));
      await tester.tap(find.text('Artículo uno'));
      await tester.pumpAndSettle();

      expect(find.text('Reader'), findsOneWidget);
    });
  });

  group('SourceDetailScreen (syncOnOpen)', () {
    late MockGetSourceArticles mockGetSourceArticles;
    late MockFeedSyncTrigger mockFeedSyncTrigger;
    late MockSyncUserData mockSyncUserData;

    Widget buildScreen({required bool syncOnOpen}) {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => SourceDetailScreen(
              source: tSource,
              getSourceArticles: mockGetSourceArticles,
              feedSyncTrigger: mockFeedSyncTrigger,
              syncUserData: mockSyncUserData,
              syncOnOpen: syncOnOpen,
            ),
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

    setUp(() {
      mockGetSourceArticles = MockGetSourceArticles();
      mockFeedSyncTrigger = MockFeedSyncTrigger();
      mockSyncUserData = MockSyncUserData();
      when(
        () => mockGetSourceArticles.execute(any()),
      ).thenAnswer((_) async => tArticles);
      when(() => mockFeedSyncTrigger.execute()).thenAnswer(
        (_) async => const FeedSyncResult(synced: 0, failedSourceIds: []),
      );
      when(() => mockSyncUserData.execute()).thenAnswer((_) async {});
    });

    testWidgets('syncOnOpen: true dispara sincronización antes de cargar', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen(syncOnOpen: true));
      await tester.pumpAndSettle();

      verify(() => mockFeedSyncTrigger.execute()).called(1);
      verify(() => mockSyncUserData.execute()).called(2);
      verify(() => mockGetSourceArticles.execute('s1')).called(1);
    });

    testWidgets('syncOnOpen: false (default) solo carga lo local', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen(syncOnOpen: false));
      await tester.pumpAndSettle();

      verifyNever(() => mockFeedSyncTrigger.execute());
      verifyNever(() => mockSyncUserData.execute());
      verify(() => mockGetSourceArticles.execute('s1')).called(1);
    });
  });
}
