import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/data/datasources/local/hive_article_datasource.dart';
import 'package:newsreader/core/data/models/article_model.dart';

class MockBox extends Mock implements Box<ArticleModel> {}

ArticleModel _article({
  required String id,
  required DateTime publishedAt,
  bool isRead = false,
  DateTime? readAt,
  DateTime? deletedAt,
}) =>
    ArticleModel(
      id: id,
      sourceId: 's1',
      sourceName: 'Source',
      title: 'Title $id',
      articleUrl: 'https://example.com/$id',
      publishedAt: publishedAt,
      isRead: isRead,
      readAt: readAt,
      deletedAt: deletedAt,
    );

void main() {
  late MockBox mockBox;
  late HiveArticleDatasource datasource;

  setUpAll(() {
    registerFallbackValue(_article(id: 'fallback', publishedAt: DateTime(2024)));
  });

  setUp(() {
    mockBox = MockBox();
    datasource = HiveArticleDatasource(mockBox);
  });

  group('getArchive', () {
    test('ordena por publishedAt descendente (más reciente primero)', () async {
      final older = _article(
        id: 'a1',
        publishedAt: DateTime(2024, 1, 1),
        isRead: true,
        readAt: DateTime(2024, 1, 10), // leído más recientemente
      );
      final newer = _article(
        id: 'a2',
        publishedAt: DateTime(2024, 1, 5),
        isRead: true,
        readAt: DateTime(2024, 1, 6),
      );

      when(() => mockBox.values).thenReturn([older, newer]);

      final result = await datasource.getArchive();

      expect(result.first.id, 'a2'); // publicado más reciente primero
      expect(result.last.id, 'a1');
    });

    test('solo retorna artículos con isRead=true', () async {
      final read = _article(id: 'a1', publishedAt: DateTime(2024), isRead: true);
      final unread = _article(id: 'a2', publishedAt: DateTime(2024), isRead: false);

      when(() => mockBox.values).thenReturn([read, unread]);

      final result = await datasource.getArchive();

      expect(result.length, 1);
      expect(result.first.id, 'a1');
    });

    test('retorna lista vacía si no hay leídos', () async {
      when(() => mockBox.values).thenReturn([]);

      final result = await datasource.getArchive();

      expect(result, isEmpty);
    });

    test('excluye artículos soft-deleted (deletedAt no nulo)', () async {
      final live = _article(id: 'a1', publishedAt: DateTime(2024), isRead: true);
      final deleted = _article(
        id: 'a2',
        publishedAt: DateTime(2024),
        isRead: true,
        deletedAt: DateTime(2024, 1, 2),
      );

      when(() => mockBox.values).thenReturn([live, deleted]);

      final result = await datasource.getArchive();

      expect(result.map((a) => a.id), ['a1']);
    });
  });

  group('saveArticle / updateArticle', () {
    test('estampan updatedAt antes de persistir', () async {
      final article = _article(id: 'a1', publishedAt: DateTime(2024));
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      await datasource.saveArticle(article);

      expect(article.updatedAt, isNotNull);
      verify(() => mockBox.put('a1', article)).called(1);
    });
  });

  group('deleteArticle', () {
    test('marca deletedAt/updatedAt en vez de borrar físicamente', () async {
      final article = _article(id: 'a1', publishedAt: DateTime(2024));
      when(() => mockBox.get('a1')).thenReturn(article);
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      await datasource.deleteArticle('a1');

      expect(article.deletedAt, isNotNull);
      expect(article.updatedAt, isNotNull);
      verify(() => mockBox.put('a1', article)).called(1);
      verifyNever(() => mockBox.delete(any()));
    });

    test('no hace nada si el artículo no existe', () async {
      when(() => mockBox.get('missing')).thenReturn(null);

      await datasource.deleteArticle('missing');

      verifyNever(() => mockBox.put(any(), any()));
    });
  });
}
