import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/features/inbox/domain/usecases/get_inbox_articles.dart';
import 'package:newsreader/features/inbox/presentation/cubit/inbox_cubit.dart';
import 'package:newsreader/features/sources/domain/usecases/get_sources.dart';

class MockGetInboxArticles extends Mock implements GetInboxArticles {}

class MockGetSources extends Mock implements GetSources {}

void main() {
  late MockGetInboxArticles mockGetInboxArticles;
  late MockGetSources mockGetSources;

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
      InboxCubit(mockGetInboxArticles, mockGetSources);

  setUp(() {
    mockGetInboxArticles = MockGetInboxArticles();
    mockGetSources = MockGetSources();
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
  });
}
