import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/core/feed/feed_sync_trigger.dart';
import 'package:newsreader/features/inbox/domain/usecases/get_inbox_articles.dart';
import 'package:newsreader/features/inbox/domain/usecases/mark_article_as_read.dart';
import 'package:newsreader/features/inbox/presentation/cubit/inbox_cubit.dart';
import 'package:newsreader/features/sources/domain/usecases/get_sources.dart';
import 'package:newsreader/features/sync/domain/usecases/sync_user_data.dart';

import '../../../../../support/fake_observability_client.dart';

class MockGetInboxArticles extends Mock implements GetInboxArticles {}

class MockGetSources extends Mock implements GetSources {}

class MockFeedSyncTrigger extends Mock implements FeedSyncTrigger {}

class MockMarkArticleAsRead extends Mock implements MarkArticleAsRead {}

class MockSyncUserData extends Mock implements SyncUserData {}

void main() {
  late MockGetInboxArticles mockGetInboxArticles;
  late MockGetSources mockGetSources;
  late MockFeedSyncTrigger mockFeedSyncTrigger;
  late MockMarkArticleAsRead mockMarkArticleAsRead;
  late MockSyncUserData mockSyncUserData;
  late MockObservabilityClient mockObservabilityClient;

  final tArticles = [
    Article(
      id: '1',
      sourceId: 's1',
      sourceName: 'Newsletter A',
      title: 'Artículo uno',
      publishedAt: DateTime(2024, 1, 15),
      articleUrl: 'https://example.com/1',
    ),
  ];

  final tArticlesRefreshed = [
    ...tArticles,
    Article(
      id: '2',
      sourceId: 's1',
      sourceName: 'Newsletter A',
      title: 'Artículo nuevo tras refrescar feeds',
      publishedAt: DateTime(2024, 1, 16),
      articleUrl: 'https://example.com/2',
    ),
  ];

  final tSources = [
    NewsSource(
      id: 's1',
      name: 'Newsletter A',
      feedUrl: 'https://a.com/feed',
      addedAt: DateTime(2024),
    ),
  ];

  InboxCubit buildCubit() => InboxCubit(
        mockGetInboxArticles,
        mockGetSources,
        mockFeedSyncTrigger,
        mockMarkArticleAsRead,
        mockSyncUserData,
        mockObservabilityClient,
      );

  setUp(() {
    mockGetInboxArticles = MockGetInboxArticles();
    mockGetSources = MockGetSources();
    mockFeedSyncTrigger = MockFeedSyncTrigger();
    mockMarkArticleAsRead = MockMarkArticleAsRead();
    mockSyncUserData = MockSyncUserData();
    mockObservabilityClient = MockObservabilityClient();
    when(() => mockSyncUserData.execute()).thenAnswer((_) async {});
  });

  group('InboxCubit', () {
    test('estado inicial es InboxLoading', () {
      expect(buildCubit().state, const InboxLoading());
    });

    blocTest<InboxCubit, InboxState>(
      'loadArticles() emite [Loading, Loaded] con artículos y fuentes',
      build: () {
        when(() => mockGetInboxArticles.execute())
            .thenAnswer((_) async => tArticles);
        when(() => mockGetSources.execute())
            .thenAnswer((_) async => tSources);
        return buildCubit();
      },
      act: (cubit) => cubit.loadArticles(),
      expect: () => [
        const InboxLoading(),
        InboxLoaded(tArticles, hasSources: true),
      ],
    );

    blocTest<InboxCubit, InboxState>(
      'loadArticles() emite hasSources=false cuando no hay fuentes',
      build: () {
        when(() => mockGetInboxArticles.execute())
            .thenAnswer((_) async => []);
        when(() => mockGetSources.execute()).thenAnswer((_) async => []);
        return buildCubit();
      },
      act: (cubit) => cubit.loadArticles(),
      expect: () => [
        const InboxLoading(),
        const InboxLoaded([], hasSources: false),
      ],
    );

    blocTest<InboxCubit, InboxState>(
      'loadArticles() emite hasSources=true cuando hay fuentes pero no artículos',
      build: () {
        when(() => mockGetInboxArticles.execute())
            .thenAnswer((_) async => []);
        when(() => mockGetSources.execute())
            .thenAnswer((_) async => tSources);
        return buildCubit();
      },
      act: (cubit) => cubit.loadArticles(),
      expect: () => [
        const InboxLoading(),
        const InboxLoaded([], hasSources: true),
      ],
    );

    blocTest<InboxCubit, InboxState>(
      'syncAndReload() llama a FeedSyncTrigger y emite Loaded sin Loading',
      build: () {
        when(() => mockFeedSyncTrigger.execute()).thenAnswer(
          (_) async => const FeedSyncResult(synced: 1, failedSourceIds: []),
        );
        when(() => mockGetInboxArticles.execute())
            .thenAnswer((_) async => tArticles);
        when(() => mockGetSources.execute())
            .thenAnswer((_) async => tSources);
        return buildCubit();
      },
      seed: () => const InboxLoaded([], hasSources: true),
      act: (cubit) => cubit.syncAndReload(),
      expect: () => [InboxLoaded(tArticles, hasSources: true)],
      verify: (_) {
        verify(() => mockFeedSyncTrigger.execute()).called(1);
        verify(() => mockSyncUserData.execute()).called(2);
      },
    );

    blocTest<InboxCubit, InboxState>(
      'syncAfterSignIn() emite Loading, sincroniza, recarga, y luego '
      'refresca los feeds en segundo plano sin bloquear la UI',
      build: () {
        when(() => mockFeedSyncTrigger.execute()).thenAnswer(
          (_) async => const FeedSyncResult(synced: 1, failedSourceIds: []),
        );
        when(() => mockGetInboxArticles.execute())
            .thenAnswer((_) async => tArticles);
        when(() => mockGetSources.execute())
            .thenAnswer((_) async => tSources);
        return buildCubit();
      },
      seed: () => const InboxLoaded([], hasSources: false),
      act: (cubit) => cubit.syncAfterSignIn(),
      wait: const Duration(milliseconds: 10),
      expect: () => [
        const InboxLoading(isSyncing: true),
        InboxLoaded(tArticles, hasSources: true),
        InboxLoaded(tArticles, hasSources: true, isSyncingInBackground: true),
        InboxLoaded(tArticles, hasSources: true),
      ],
      verify: (_) {
        verify(() => mockSyncUserData.execute()).called(2);
        verify(() => mockFeedSyncTrigger.execute()).called(1);
      },
    );

    blocTest<InboxCubit, InboxState>(
      'syncAfterSignIn() actualiza el Inbox con los artículos nuevos que '
      'trae el refresco silencioso de feeds',
      build: () {
        var reloadCount = 0;
        when(() => mockFeedSyncTrigger.execute()).thenAnswer(
          (_) async => const FeedSyncResult(synced: 1, failedSourceIds: []),
        );
        when(() => mockGetInboxArticles.execute()).thenAnswer((_) async {
          reloadCount++;
          return reloadCount == 1 ? tArticles : tArticlesRefreshed;
        });
        when(() => mockGetSources.execute())
            .thenAnswer((_) async => tSources);
        return buildCubit();
      },
      seed: () => const InboxLoaded([], hasSources: false),
      act: (cubit) => cubit.syncAfterSignIn(),
      wait: const Duration(milliseconds: 10),
      expect: () => [
        const InboxLoading(isSyncing: true),
        InboxLoaded(tArticles, hasSources: true),
        InboxLoaded(tArticles, hasSources: true, isSyncingInBackground: true),
        InboxLoaded(tArticlesRefreshed, hasSources: true),
      ],
    );

    blocTest<InboxCubit, InboxState>(
      'syncAfterSignIn() no propaga a la UI un error del refresco '
      'silencioso de feeds (a diferencia de syncAndReload())',
      build: () {
        when(() => mockFeedSyncTrigger.execute())
            .thenAnswer((_) async => throw const FeedSyncException('boom'));
        when(() => mockGetInboxArticles.execute())
            .thenAnswer((_) async => tArticles);
        when(() => mockGetSources.execute())
            .thenAnswer((_) async => tSources);
        return buildCubit();
      },
      seed: () => const InboxLoaded([], hasSources: false),
      act: (cubit) => cubit.syncAfterSignIn(),
      wait: const Duration(milliseconds: 10),
      expect: () => [
        const InboxLoading(isSyncing: true),
        InboxLoaded(tArticles, hasSources: true),
        InboxLoaded(tArticles, hasSources: true, isSyncingInBackground: true),
        InboxLoaded(tArticles, hasSources: true),
      ],
      errors: () => [],
    );

    test(
      'un pull-to-refresh manual que coincide con el refresco silencioso '
      'de login reusa la misma invocación de FeedSyncTrigger en vez de '
      'disparar una segunda',
      () async {
        final completer = Completer<FeedSyncResult>();
        when(() => mockFeedSyncTrigger.execute())
            .thenAnswer((_) => completer.future);
        when(() => mockGetInboxArticles.execute())
            .thenAnswer((_) async => tArticles);
        when(() => mockGetSources.execute())
            .thenAnswer((_) async => tSources);

        final cubit = buildCubit();

        // Dispara el login: su fase silenciosa deja una invocación de
        // FeedSyncTrigger en vuelo (el completer todavía no se resuelve).
        final signInDone = cubit.syncAfterSignIn();
        await Future<void>.delayed(Duration.zero);

        // Un pull-to-refresh manual se solapa mientras esa invocación
        // sigue pendiente.
        final reloadDone = cubit.syncAndReload();

        completer.complete(
          const FeedSyncResult(synced: 1, failedSourceIds: []),
        );

        await signInDone;
        await reloadDone;

        verify(() => mockFeedSyncTrigger.execute()).called(1);
      },
    );

    blocTest<InboxCubit, InboxState>(
      'syncInBackground() marca isSyncingInBackground sin ocultar los artículos ya cargados',
      build: () {
        when(() => mockGetInboxArticles.execute())
            .thenAnswer((_) async => tArticles);
        when(() => mockGetSources.execute())
            .thenAnswer((_) async => tSources);
        return buildCubit();
      },
      seed: () => InboxLoaded(tArticles, hasSources: true),
      act: (cubit) => cubit.syncInBackground(),
      expect: () => [
        InboxLoaded(tArticles, hasSources: true, isSyncingInBackground: true),
        InboxLoaded(tArticles, hasSources: true),
      ],
      verify: (_) => verify(() => mockSyncUserData.execute()).called(1),
    );

    blocTest<InboxCubit, InboxState>(
      'syncInBackground() no emite el flag intermedio si el estado actual no es InboxLoaded',
      build: () {
        when(() => mockGetInboxArticles.execute())
            .thenAnswer((_) async => tArticles);
        when(() => mockGetSources.execute())
            .thenAnswer((_) async => tSources);
        return buildCubit();
      },
      act: (cubit) => cubit.syncInBackground(),
      expect: () => [InboxLoaded(tArticles, hasSources: true)],
    );

    blocTest<InboxCubit, InboxState>(
      'syncAndReload() sube el estado local antes de disparar el fetch del servidor',
      build: () {
        when(() => mockFeedSyncTrigger.execute()).thenAnswer(
          (_) async => const FeedSyncResult(synced: 1, failedSourceIds: []),
        );
        when(() => mockGetInboxArticles.execute())
            .thenAnswer((_) async => tArticles);
        when(() => mockGetSources.execute())
            .thenAnswer((_) async => tSources);
        return buildCubit();
      },
      seed: () => const InboxLoaded([], hasSources: true),
      act: (cubit) => cubit.syncAndReload(),
      expect: () => [InboxLoaded(tArticles, hasSources: true)],
      verify: (_) {
        verifyInOrder([
          () => mockSyncUserData.execute(),
          () => mockFeedSyncTrigger.execute(),
          () => mockSyncUserData.execute(),
        ]);
      },
    );

    test('syncAndReload() retorna FeedSyncResult con isNetworkError=true', () async {
      const expectedResult = FeedSyncResult(
        synced: 0,
        failedSourceIds: ['s1'],
        isNetworkError: true,
      );
      when(() => mockFeedSyncTrigger.execute())
          .thenAnswer((_) async => expectedResult);
      when(() => mockGetInboxArticles.execute()).thenAnswer((_) async => []);
      when(() => mockGetSources.execute()).thenAnswer((_) async => tSources);

      final cubit = buildCubit();
      final result = await cubit.syncAndReload();

      expect(result.isNetworkError, isTrue);
      expect(result.failedSourceIds, ['s1']);
    });

    test('syncAndReload() retorna FeedSyncResult con fallos parciales', () async {
      const expectedResult = FeedSyncResult(
        synced: 0,
        failedSourceIds: ['s1', 's2'],
      );
      when(() => mockFeedSyncTrigger.execute())
          .thenAnswer((_) async => expectedResult);
      when(() => mockGetInboxArticles.execute()).thenAnswer((_) async => []);
      when(() => mockGetSources.execute()).thenAnswer((_) async => tSources);

      final cubit = buildCubit();
      final result = await cubit.syncAndReload();

      expect(result.isNetworkError, isFalse);
      expect(result.failedSourceIds.length, 2);
    });

    blocTest<InboxCubit, InboxState>(
      'loadArticlesAfterReading() emite InboxLoaded con readArticleId sin Loading previo',
      build: () {
        when(() => mockGetInboxArticles.execute())
            .thenAnswer((_) async => [tArticles[0]]);
        when(() => mockGetSources.execute())
            .thenAnswer((_) async => tSources);
        return buildCubit();
      },
      seed: () => InboxLoaded(tArticles, hasSources: true),
      act: (cubit) => cubit.loadArticlesAfterReading('2'),
      expect: () => [
        InboxLoaded([tArticles[0]], hasSources: true, readArticleId: '2'),
      ],
    );

    blocTest<InboxCubit, InboxState>(
      'markAsRead() marca el artículo y emite InboxLoaded con readArticleId',
      build: () {
        when(() => mockMarkArticleAsRead.execute(any()))
            .thenAnswer((_) async {});
        when(() => mockGetInboxArticles.execute())
            .thenAnswer((_) async => []);
        when(() => mockGetSources.execute())
            .thenAnswer((_) async => tSources);
        return buildCubit();
      },
      seed: () => InboxLoaded(tArticles, hasSources: true),
      act: (cubit) => cubit.markAsRead('1'),
      expect: () => [
        const InboxLoaded([], hasSources: true, readArticleId: '1'),
      ],
      verify: (_) => verify(() => mockMarkArticleAsRead.execute('1')).called(1),
    );

    final tSearchableArticles = [
      Article(
        id: '1',
        sourceId: 's1',
        sourceName: 'Newsletter A',
        title: 'Cómo escribir mejor código Dart',
        publishedAt: DateTime(2024, 1, 15),
        articleUrl: 'https://example.com/1',
      ),
      Article(
        id: '2',
        sourceId: 's2',
        sourceName: 'The Pragmatic Engineer',
        title: 'Otro artículo sin relación',
        publishedAt: DateTime(2024, 1, 16),
        articleUrl: 'https://example.com/2',
      ),
    ];

    blocTest<InboxCubit, InboxState>(
      'search() filtra visibleArticles sin llamar al repositorio',
      build: buildCubit,
      seed: () => InboxLoaded(tSearchableArticles, hasSources: true),
      act: (cubit) => cubit.search('dart'),
      expect: () => [
        InboxLoaded(tSearchableArticles, hasSources: true, searchQuery: 'dart'),
      ],
      verify: (_) => verifyNever(() => mockGetInboxArticles.execute()),
    );

    test('visibleArticles refleja el filtro de search() sobre título/fuente', () {
      final cubit = InboxCubit(
        mockGetInboxArticles,
        mockGetSources,
        mockFeedSyncTrigger,
        mockMarkArticleAsRead,
        mockSyncUserData,
        mockObservabilityClient,
      );
      cubit.emit(InboxLoaded(tSearchableArticles, hasSources: true));

      cubit.search('pragmatic');
      final loaded = cubit.state as InboxLoaded;
      expect(loaded.visibleArticles, [tSearchableArticles[1]]);

      cubit.search('');
      final cleared = cubit.state as InboxLoaded;
      expect(cleared.visibleArticles, tSearchableArticles);
    });

    blocTest<InboxCubit, InboxState>(
      'search() sin coincidencias deja visibleArticles vacío',
      build: buildCubit,
      seed: () => InboxLoaded(tSearchableArticles, hasSources: true),
      act: (cubit) => cubit.search('inexistente'),
      verify: (cubit) {
        final loaded = cubit.state as InboxLoaded;
        expect(loaded.visibleArticles, isEmpty);
      },
    );

    blocTest<InboxCubit, InboxState>(
      'search() no tiene efecto si el estado actual no es InboxLoaded',
      build: buildCubit,
      act: (cubit) => cubit.search('algo'),
      expect: () => [],
    );

    blocTest<InboxCubit, InboxState>(
      'selectArticle() sin selección previa solo resalta, sin recargar del repositorio',
      build: buildCubit,
      seed: () => InboxLoaded(tArticles, hasSources: true),
      act: (cubit) => cubit.selectArticle('1'),
      expect: () => [
        InboxLoaded(tArticles, hasSources: true, openArticleId: '1'),
      ],
      verify: (_) => verifyNever(() => mockGetInboxArticles.execute()),
    );

    blocTest<InboxCubit, InboxState>(
      'selectArticle() con el mismo artículo ya abierto es un no-op',
      build: buildCubit,
      seed: () =>
          InboxLoaded(tArticles, hasSources: true, openArticleId: '1'),
      act: (cubit) => cubit.selectArticle('1'),
      expect: () => [],
    );

    blocTest<InboxCubit, InboxState>(
      'selectArticle() con otra selección abierta anima la salida de la '
      'anterior (readArticleId) y resalta la nueva (openArticleId)',
      build: () {
        when(() => mockGetInboxArticles.execute())
            .thenAnswer((_) async => [tArticles[0]]);
        when(() => mockGetSources.execute())
            .thenAnswer((_) async => tSources);
        return buildCubit();
      },
      seed: () =>
          InboxLoaded(tArticles, hasSources: true, openArticleId: '1'),
      act: (cubit) => cubit.selectArticle('2'),
      expect: () => [
        InboxLoaded(
          [tArticles[0]],
          hasSources: true,
          readArticleId: '1',
          openArticleId: '2',
        ),
      ],
    );

    blocTest<InboxCubit, InboxState>(
      'closeOpenArticle() anima la salida del artículo abierto y limpia openArticleId',
      build: () {
        when(() => mockGetInboxArticles.execute())
            .thenAnswer((_) async => []);
        when(() => mockGetSources.execute())
            .thenAnswer((_) async => tSources);
        return buildCubit();
      },
      seed: () =>
          InboxLoaded(tArticles, hasSources: true, openArticleId: '1'),
      act: (cubit) => cubit.closeOpenArticle(),
      expect: () => [
        const InboxLoaded([], hasSources: true, readArticleId: '1'),
      ],
    );

    blocTest<InboxCubit, InboxState>(
      'closeOpenArticle() no tiene efecto si no hay ningún artículo abierto',
      build: buildCubit,
      seed: () => InboxLoaded(tArticles, hasSources: true),
      act: (cubit) => cubit.closeOpenArticle(),
      expect: () => [],
      verify: (_) => verifyNever(() => mockGetInboxArticles.execute()),
    );

    blocTest<InboxCubit, InboxState>(
      'syncInBackground() conserva la selección abierta (openArticleId)',
      build: () {
        when(() => mockGetInboxArticles.execute())
            .thenAnswer((_) async => tArticles);
        when(() => mockGetSources.execute())
            .thenAnswer((_) async => tSources);
        return buildCubit();
      },
      seed: () =>
          InboxLoaded(tArticles, hasSources: true, openArticleId: '1'),
      act: (cubit) => cubit.syncInBackground(),
      expect: () => [
        InboxLoaded(
          tArticles,
          hasSources: true,
          isSyncingInBackground: true,
          openArticleId: '1',
        ),
        InboxLoaded(tArticles, hasSources: true, openArticleId: '1'),
      ],
    );
  });
}
