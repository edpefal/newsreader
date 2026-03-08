import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/features/sources/domain/usecases/get_source_articles.dart';
import 'package:newsreader/features/sources/presentation/cubit/source_detail_cubit.dart';

class MockGetSourceArticles extends Mock implements GetSourceArticles {}

void main() {
  late MockGetSourceArticles mockGetSourceArticles;

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
  });

  group('SourceDetailCubit', () {
    blocTest<SourceDetailCubit, SourceDetailState>(
      'emite [SourceDetailLoading, SourceDetailLoaded] al cargar artículos',
      build: () => SourceDetailCubit(mockGetSourceArticles),
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
      build: () => SourceDetailCubit(mockGetSourceArticles),
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
  });
}
