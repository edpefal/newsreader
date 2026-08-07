import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/feed/feed_sync_trigger.dart';
import 'package:newsreader/features/sources/domain/usecases/get_source_articles.dart';
import 'package:newsreader/features/sources/presentation/cubit/source_detail_cubit.dart';
import 'package:newsreader/features/sync/domain/usecases/sync_user_data.dart';

class MockGetSourceArticles extends Mock implements GetSourceArticles {}
class MockFeedSyncTrigger extends Mock implements FeedSyncTrigger {}
class MockSyncUserData extends Mock implements SyncUserData {}

void main() {
  late MockGetSourceArticles mockGetSourceArticles;
  late MockFeedSyncTrigger mockFeedSyncTrigger;
  late MockSyncUserData mockSyncUserData;

  final tArticles = [
    Article(
      id: 'a1',
      sourceId: 's1',
      sourceName: 'Newsletter A',
      title: 'Artículo 1',
      publishedAt: DateTime(2024, 3, 15),
      articleUrl: 'https://example.com/1',
    ),
    Article(
      id: 'a2',
      sourceId: 's1',
      sourceName: 'Newsletter A',
      title: 'Artículo 2',
      publishedAt: DateTime(2024, 3, 14),
      articleUrl: 'https://example.com/2',
    ),
  ];

  setUp(() {
    mockGetSourceArticles = MockGetSourceArticles();
    mockFeedSyncTrigger = MockFeedSyncTrigger();
    mockSyncUserData = MockSyncUserData();
  });

  SourceDetailCubit buildCubit() => SourceDetailCubit(
        mockGetSourceArticles,
        mockFeedSyncTrigger,
        mockSyncUserData,
      );

  group('SourceDetailCubit', () {
    blocTest<SourceDetailCubit, SourceDetailState>(
      'emite [SourceDetailLoading, SourceDetailLoaded] al cargar artículos',
      build: buildCubit,
      setUp: () {
        when(() => mockGetSourceArticles.execute('s1'))
            .thenAnswer((_) async => tArticles);
      },
      act: (cubit) => cubit.loadArticles('s1'),
      expect: () => [
        const SourceDetailLoading(),
        SourceDetailLoaded(tArticles),
      ],
    );

    blocTest<SourceDetailCubit, SourceDetailState>(
      'emite [SourceDetailLoading, SourceDetailLoaded([])] cuando no hay artículos',
      build: buildCubit,
      setUp: () {
        when(() => mockGetSourceArticles.execute('s1'))
            .thenAnswer((_) async => []);
      },
      act: (cubit) => cubit.loadArticles('s1'),
      expect: () => [
        const SourceDetailLoading(),
        const SourceDetailLoaded([]),
      ],
    );

    blocTest<SourceDetailCubit, SourceDetailState>(
      'syncAndLoadArticles: sincroniza y luego carga los artículos',
      build: buildCubit,
      setUp: () {
        when(() => mockFeedSyncTrigger.execute()).thenAnswer(
          (_) async => const FeedSyncResult(synced: 1, failedSourceIds: []),
        );
        when(() => mockSyncUserData.execute()).thenAnswer((_) async {});
        when(() => mockGetSourceArticles.execute('s1'))
            .thenAnswer((_) async => tArticles);
      },
      act: (cubit) => cubit.syncAndLoadArticles('s1'),
      expect: () => [
        const SourceDetailLoading(),
        SourceDetailLoaded(tArticles),
      ],
      verify: (_) {
        verify(() => mockFeedSyncTrigger.execute()).called(1);
        // Dos veces: una para subir la fuente recién agregada antes del
        // fetch (el servidor todavía no la conoce), otra para bajar los
        // artículos que ese fetch crea.
        verify(() => mockSyncUserData.execute()).called(2);
      },
    );

    blocTest<SourceDetailCubit, SourceDetailState>(
      'syncAndLoadArticles: un error de red en el sync no impide cargar lo local',
      build: buildCubit,
      setUp: () {
        when(() => mockFeedSyncTrigger.execute())
            .thenThrow(const NetworkException());
        when(() => mockSyncUserData.execute()).thenAnswer((_) async {});
        when(() => mockGetSourceArticles.execute('s1'))
            .thenAnswer((_) async => tArticles);
      },
      act: (cubit) => cubit.syncAndLoadArticles('s1'),
      expect: () => [
        const SourceDetailLoading(),
        SourceDetailLoaded(tArticles),
      ],
      verify: (_) {
        verify(() => mockSyncUserData.execute()).called(2);
      },
    );
  });
}
