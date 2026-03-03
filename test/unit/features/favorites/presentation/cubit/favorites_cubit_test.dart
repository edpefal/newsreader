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
  });
}
