import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/features/inbox/domain/usecases/get_inbox_articles.dart';
import 'package:newsreader/features/inbox/presentation/cubit/inbox_cubit.dart';

class MockGetInboxArticles extends Mock implements GetInboxArticles {}

void main() {
  late MockGetInboxArticles mockGetInboxArticles;

  final tArticles = [
    Article(
      id: '1',
      sourceId: 's1',
      sourceName: 'Newsletter A',
      title: 'Artículo uno',
      publishedAt: DateTime(2024, 1, 15),
      articleUrl: 'https://example.com/1',
    ),
    Article(
      id: '2',
      sourceId: 's1',
      sourceName: 'Newsletter A',
      title: 'Artículo dos',
      publishedAt: DateTime(2024, 1, 14),
      articleUrl: 'https://example.com/2',
    ),
  ];

  setUp(() {
    mockGetInboxArticles = MockGetInboxArticles();
  });

  group('InboxCubit', () {
    test('estado inicial es InboxLoading', () {
      expect(
        InboxCubit(mockGetInboxArticles).state,
        const InboxLoading(),
      );
    });

    blocTest<InboxCubit, InboxState>(
      'loadArticles() emite [Loading, Loaded] con artículos',
      build: () {
        when(() => mockGetInboxArticles.execute())
            .thenAnswer((_) async => tArticles);
        return InboxCubit(mockGetInboxArticles);
      },
      act: (cubit) => cubit.loadArticles(),
      expect: () => [
        const InboxLoading(),
        InboxLoaded(tArticles),
      ],
    );

    blocTest<InboxCubit, InboxState>(
      'loadArticles() emite [Loading, Loaded([])] cuando no hay artículos',
      build: () {
        when(() => mockGetInboxArticles.execute()).thenAnswer((_) async => []);
        return InboxCubit(mockGetInboxArticles);
      },
      act: (cubit) => cubit.loadArticles(),
      expect: () => [
        const InboxLoading(),
        const InboxLoaded([]),
      ],
    );
  });
}
