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
      );

  setUp(() {
    mockGetInboxArticles = MockGetInboxArticles();
    mockGetSources = MockGetSources();
    mockFeedSyncTrigger = MockFeedSyncTrigger();
    mockMarkArticleAsRead = MockMarkArticleAsRead();
    mockSyncUserData = MockSyncUserData();
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
      'syncAfterSignIn() emite Loading, sincroniza y recarga con los datos bajados',
      build: () {
        when(() => mockSyncUserData.execute()).thenAnswer((_) async {});
        when(() => mockGetInboxArticles.execute())
            .thenAnswer((_) async => tArticles);
        when(() => mockGetSources.execute())
            .thenAnswer((_) async => tSources);
        return buildCubit();
      },
      seed: () => const InboxLoaded([], hasSources: false),
      act: (cubit) => cubit.syncAfterSignIn(),
      expect: () => [
        const InboxLoading(message: 'Sincronizando fuentes...'),
        InboxLoaded(tArticles, hasSources: true),
      ],
      verify: (_) {
        verify(() => mockSyncUserData.execute()).called(1);
        verifyNever(() => mockFeedSyncTrigger.execute());
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
  });
}
