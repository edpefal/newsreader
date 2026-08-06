import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/features/archive/domain/usecases/get_archive.dart';
import 'package:newsreader/features/archive/presentation/cubit/archive_cubit.dart';

class MockGetArchive extends Mock implements GetArchive {}

void main() {
  late MockGetArchive mockGetArchive;

  final tArticles = [
    Article(
      id: 'a1',
      sourceId: 's1',
      sourceName: 'Newsletter A',
      title: 'Artículo archivado',
      publishedAt: DateTime(2024, 1, 15),
      articleUrl: 'https://example.com/1',
      isRead: true,
    ),
  ];

  ArchiveCubit buildCubit() => ArchiveCubit(mockGetArchive);

  setUp(() {
    mockGetArchive = MockGetArchive();
  });

  group('ArchiveCubit', () {
    test('estado inicial es ArchiveLoading', () {
      expect(buildCubit().state, const ArchiveLoading());
    });

    blocTest<ArchiveCubit, ArchiveState>(
      'loadArchive() emite [Loading, Loaded] con artículos',
      build: () {
        when(() => mockGetArchive.execute())
            .thenAnswer((_) async => tArticles);
        return buildCubit();
      },
      act: (cubit) => cubit.loadArchive(),
      expect: () => [
        const ArchiveLoading(),
        ArchiveLoaded(tArticles),
      ],
    );

    blocTest<ArchiveCubit, ArchiveState>(
      'loadArchive() emite [Loading, Loaded([])] cuando no hay archivados',
      build: () {
        when(() => mockGetArchive.execute()).thenAnswer((_) async => []);
        return buildCubit();
      },
      act: (cubit) => cubit.loadArchive(),
      expect: () => [
        const ArchiveLoading(),
        const ArchiveLoaded([]),
      ],
    );

    final tSearchableArticles = [
      Article(
        id: 'a1',
        sourceId: 's1',
        sourceName: 'Newsletter A',
        title: 'Cómo escribir mejor código Dart',
        publishedAt: DateTime(2024, 1, 15),
        articleUrl: 'https://example.com/1',
        isRead: true,
      ),
      Article(
        id: 'a2',
        sourceId: 's2',
        sourceName: 'The Pragmatic Engineer',
        title: 'Otro artículo sin relación',
        publishedAt: DateTime(2024, 1, 16),
        articleUrl: 'https://example.com/2',
        isRead: true,
      ),
    ];

    blocTest<ArchiveCubit, ArchiveState>(
      'search() filtra visibleArticles sin llamar al repositorio',
      build: buildCubit,
      seed: () => ArchiveLoaded(tSearchableArticles),
      act: (cubit) => cubit.search('dart'),
      expect: () => [
        ArchiveLoaded(tSearchableArticles, searchQuery: 'dart'),
      ],
      verify: (_) => verifyNever(() => mockGetArchive.execute()),
    );

    test('search("") restaura la lista completa', () {
      final cubit = ArchiveCubit(mockGetArchive);
      cubit.emit(ArchiveLoaded(tSearchableArticles));

      cubit.search('pragmatic');
      expect(
        (cubit.state as ArchiveLoaded).visibleArticles,
        [tSearchableArticles[1]],
      );

      cubit.search('');
      expect(
        (cubit.state as ArchiveLoaded).visibleArticles,
        tSearchableArticles,
      );
    });

    blocTest<ArchiveCubit, ArchiveState>(
      'search() no tiene efecto si el estado actual no es ArchiveLoaded',
      build: buildCubit,
      act: (cubit) => cubit.search('algo'),
      expect: () => [],
    );
  });
}
