import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/features/sources/domain/usecases/delete_source.dart';
import 'package:newsreader/features/sources/domain/usecases/get_sources.dart';
import 'package:newsreader/features/sources/domain/usecases/update_source_name.dart';
import 'package:newsreader/features/sources/presentation/cubit/sources_cubit.dart';

class MockGetSources extends Mock implements GetSources {}

class MockUpdateSourceName extends Mock implements UpdateSourceName {}

class MockDeleteSource extends Mock implements DeleteSource {}

void main() {
  late MockGetSources mockGetSources;
  late MockUpdateSourceName mockUpdateSourceName;
  late MockDeleteSource mockDeleteSource;

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

  SourcesCubit buildCubit() =>
      SourcesCubit(mockGetSources, mockUpdateSourceName, mockDeleteSource);

  setUp(() {
    mockGetSources = MockGetSources();
    mockUpdateSourceName = MockUpdateSourceName();
    mockDeleteSource = MockDeleteSource();
  });

  group('SourcesCubit', () {
    test('estado inicial es SourcesLoading', () {
      expect(buildCubit().state, const SourcesLoading());
    });

    blocTest<SourcesCubit, SourcesState>(
      'loadSources() emite [Loading, Loaded] con la lista de fuentes',
      build: () {
        when(() => mockGetSources.execute()).thenAnswer((_) async => tSources);
        return buildCubit();
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
        return buildCubit();
      },
      act: (cubit) => cubit.loadSources(),
      expect: () => [
        const SourcesLoading(),
        const SourcesLoaded([]),
      ],
    );

    blocTest<SourcesCubit, SourcesState>(
      'updateSourceName() llama al caso de uso y recarga con datos actualizados',
      build: () {
        final updated = [
          NewsSource(
            id: '1',
            name: 'Nuevo Nombre',
            feedUrl: 'https://a.com/feed',
            addedAt: DateTime(2024),
          ),
          tSources[1],
        ];
        when(() => mockUpdateSourceName.execute('1', 'Nuevo Nombre'))
            .thenAnswer((_) async {});
        when(() => mockGetSources.execute()).thenAnswer((_) async => updated);
        return buildCubit();
      },
      seed: () => SourcesLoaded(tSources),
      act: (cubit) => cubit.updateSourceName('1', 'Nuevo Nombre'),
      expect: () => [
        SourcesLoaded([
          NewsSource(
            id: '1',
            name: 'Nuevo Nombre',
            feedUrl: 'https://a.com/feed',
            addedAt: DateTime(2024),
          ),
          tSources[1],
        ]),
      ],
      verify: (_) {
        verify(() => mockUpdateSourceName.execute('1', 'Nuevo Nombre'))
            .called(1);
      },
    );

    blocTest<SourcesCubit, SourcesState>(
      'deleteSource() llama al caso de uso y recarga sin emitir Loading',
      build: () {
        when(() => mockDeleteSource.execute('1')).thenAnswer((_) async {});
        when(() => mockGetSources.execute())
            .thenAnswer((_) async => [tSources[1]]);
        return buildCubit();
      },
      seed: () => SourcesLoaded(tSources),
      act: (cubit) => cubit.deleteSource('1'),
      expect: () => [SourcesLoaded([tSources[1]])],
      verify: (_) {
        verify(() => mockDeleteSource.execute('1')).called(1);
      },
    );
  });
}
