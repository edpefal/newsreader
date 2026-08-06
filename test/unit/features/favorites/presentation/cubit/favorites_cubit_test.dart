import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/features/favorites/domain/usecases/get_favorites.dart';
import 'package:newsreader/features/favorites/presentation/cubit/favorites_cubit.dart';

class MockGetFavorites extends Mock implements GetFavorites {}

void main() {
  late MockGetFavorites mockGetFavorites;

  final tArticles = [
    Article(
      id: 'a1',
      sourceId: 's1',
      sourceName: 'Newsletter A',
      title: 'Artículo favorito',
      publishedAt: DateTime(2024, 1, 15),
      articleUrl: 'https://example.com/1',
      isFavorite: true,
    ),
  ];

  FavoritesCubit buildCubit() => FavoritesCubit(mockGetFavorites);

  setUp(() {
    mockGetFavorites = MockGetFavorites();
  });

  group('FavoritesCubit', () {
    test('estado inicial es FavoritesLoading', () {
      expect(buildCubit().state, const FavoritesLoading());
    });

    blocTest<FavoritesCubit, FavoritesState>(
      'loadFavorites() emite [Loading, Loaded] con artículos',
      build: () {
        when(() => mockGetFavorites.execute())
            .thenAnswer((_) async => tArticles);
        return buildCubit();
      },
      act: (cubit) => cubit.loadFavorites(),
      expect: () => [
        const FavoritesLoading(),
        FavoritesLoaded(tArticles),
      ],
    );

    blocTest<FavoritesCubit, FavoritesState>(
      'loadFavorites() emite [Loading, Loaded([])] cuando no hay favoritos',
      build: () {
        when(() => mockGetFavorites.execute()).thenAnswer((_) async => []);
        return buildCubit();
      },
      act: (cubit) => cubit.loadFavorites(),
      expect: () => [
        const FavoritesLoading(),
        const FavoritesLoaded([]),
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
        isFavorite: true,
      ),
      Article(
        id: 'a2',
        sourceId: 's2',
        sourceName: 'The Pragmatic Engineer',
        title: 'Otro artículo sin relación',
        publishedAt: DateTime(2024, 1, 16),
        articleUrl: 'https://example.com/2',
        isFavorite: true,
      ),
    ];

    blocTest<FavoritesCubit, FavoritesState>(
      'search() filtra visibleArticles sin llamar al repositorio',
      build: buildCubit,
      seed: () => FavoritesLoaded(tSearchableArticles),
      act: (cubit) => cubit.search('dart'),
      expect: () => [
        FavoritesLoaded(tSearchableArticles, searchQuery: 'dart'),
      ],
      verify: (_) => verifyNever(() => mockGetFavorites.execute()),
    );

    test('search("") restaura la lista completa', () {
      final cubit = FavoritesCubit(mockGetFavorites);
      cubit.emit(FavoritesLoaded(tSearchableArticles));

      cubit.search('pragmatic');
      expect(
        (cubit.state as FavoritesLoaded).visibleArticles,
        [tSearchableArticles[1]],
      );

      cubit.search('');
      expect(
        (cubit.state as FavoritesLoaded).visibleArticles,
        tSearchableArticles,
      );
    });

    blocTest<FavoritesCubit, FavoritesState>(
      'search() no tiene efecto si el estado actual no es FavoritesLoaded',
      build: buildCubit,
      act: (cubit) => cubit.search('algo'),
      expect: () => [],
    );
  });
}
