import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/features/sources/domain/usecases/get_sources.dart';
import 'package:newsreader/features/sources/presentation/cubit/sources_cubit.dart';

class MockGetSources extends Mock implements GetSources {}

void main() {
  late MockGetSources mockGetSources;

  final tSources = [
    NewsSource(
      id: '1',
      name: 'Newsletter A',
      feedUrl: 'https://a.com/feed',
      addedAt: DateTime(2024),
    ),
    NewsSource(
      id: '2',
      name: 'Newsletter B',
      feedUrl: 'https://b.com/feed',
      addedAt: DateTime(2024),
    ),
  ];

  setUp(() {
    mockGetSources = MockGetSources();
  });

  group('SourcesCubit', () {
    test('estado inicial es SourcesLoading', () {
      expect(
        SourcesCubit(mockGetSources).state,
        const SourcesLoading(),
      );
    });

    blocTest<SourcesCubit, SourcesState>(
      'loadSources() emite [Loading, Loaded] con la lista de fuentes',
      build: () {
        when(() => mockGetSources.execute()).thenAnswer((_) async => tSources);
        return SourcesCubit(mockGetSources);
      },
      act: (cubit) => cubit.loadSources(),
      expect: () => [
        const SourcesLoading(),
        SourcesLoaded(tSources),
      ],
    );

    blocTest<SourcesCubit, SourcesState>(
      'loadSources() emite [Loading, Loaded([])] cuando no hay fuentes',
      build: () {
        when(() => mockGetSources.execute()).thenAnswer((_) async => []);
        return SourcesCubit(mockGetSources);
      },
      act: (cubit) => cubit.loadSources(),
      expect: () => [
        const SourcesLoading(),
        const SourcesLoaded([]),
      ],
    );
  });
}
