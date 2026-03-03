import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/features/inbox/domain/usecases/get_inbox_articles.dart';
import 'package:newsreader/features/inbox/domain/usecases/sync_sources.dart';
import 'package:newsreader/features/inbox/presentation/cubit/inbox_cubit.dart';
import 'package:newsreader/features/sources/domain/usecases/get_sources.dart';

class MockGetInboxArticles extends Mock implements GetInboxArticles {}

class MockGetSources extends Mock implements GetSources {}

class MockSyncSources extends Mock implements SyncSources {}

void main() {
  late MockGetInboxArticles mockGetInboxArticles;
  late MockGetSources mockGetSources;
  late MockSyncSources mockSyncSources;

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

  InboxCubit buildCubit() =>
      InboxCubit(mockGetInboxArticles, mockGetSources, mockSyncSources);

  setUp(() {
    mockGetInboxArticles = MockGetInboxArticles();
    mockGetSources = MockGetSources();
    mockSyncSources = MockSyncSources();
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
      'syncAndReload() llama a SyncSources y emite Loaded sin Loading',
      build: () {
        when(() => mockSyncSources.execute()).thenAnswer(
          (_) async => const SyncResult(synced: 1, failedSourceIds: []),
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
      verify: (_) => verify(() => mockSyncSources.execute()).called(1),
    );

    test('syncAndReload() retorna SyncResult con isNetworkError=true', () async {
      const expectedResult = SyncResult(
        synced: 0,
        failedSourceIds: ['s1'],
        isNetworkError: true,
      );
      when(() => mockSyncSources.execute())
          .thenAnswer((_) async => expectedResult);
      when(() => mockGetInboxArticles.execute()).thenAnswer((_) async => []);
      when(() => mockGetSources.execute()).thenAnswer((_) async => tSources);

      final cubit = buildCubit();
      final result = await cubit.syncAndReload();

      expect(result.isNetworkError, isTrue);
      expect(result.failedSourceIds, ['s1']);
    });

    test('syncAndReload() retorna SyncResult con fallos parciales', () async {
      const expectedResult = SyncResult(
        synced: 0,
        failedSourceIds: ['s1', 's2'],
      );
      when(() => mockSyncSources.execute())
          .thenAnswer((_) async => expectedResult);
      when(() => mockGetInboxArticles.execute()).thenAnswer((_) async => []);
      when(() => mockGetSources.execute()).thenAnswer((_) async => tSources);

      final cubit = buildCubit();
      final result = await cubit.syncAndReload();

      expect(result.isNetworkError, isFalse);
      expect(result.failedSourceIds.length, 2);
    });
  });
}
