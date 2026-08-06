import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/features/account/domain/usecases/export_favorites_json.dart';
import 'package:newsreader/features/favorites/domain/usecases/get_favorites.dart';

class MockGetFavorites extends Mock implements GetFavorites {}

void main() {
  late MockGetFavorites mockGetFavorites;

  ExportFavoritesJson buildUseCase() => ExportFavoritesJson(mockGetFavorites);

  setUp(() {
    mockGetFavorites = MockGetFavorites();
  });

  group('ExportFavoritesJson', () {
    test('genera un JSON válido con un objeto por artículo favorito',
        () async {
      when(() => mockGetFavorites.execute()).thenAnswer(
        (_) async => [
          Article(
            id: '1',
            sourceId: 's1',
            sourceName: 'Newsletter A',
            title: 'Artículo favorito',
            publishedAt: DateTime(2024, 1, 1),
            articleUrl: 'https://a.com/1',
            isFavorite: true,
            savedAsFavoriteAt: DateTime.utc(2024, 1, 2, 10),
          ),
        ],
      );

      final result = await buildUseCase().execute();
      final decoded = jsonDecode(result) as List<dynamic>;

      expect(decoded, hasLength(1));
      final item = decoded.single as Map<String, dynamic>;
      expect(item['title'], 'Artículo favorito');
      expect(item['articleUrl'], 'https://a.com/1');
      expect(item['sourceName'], 'Newsletter A');
      expect(item['savedAsFavoriteAt'], '2024-01-02T10:00:00.000Z');
    });

    test('sin favoritos, genera una lista JSON vacía válida', () async {
      when(() => mockGetFavorites.execute()).thenAnswer((_) async => []);

      final result = await buildUseCase().execute();
      final decoded = jsonDecode(result) as List<dynamic>;

      expect(decoded, isEmpty);
    });
  });
}
