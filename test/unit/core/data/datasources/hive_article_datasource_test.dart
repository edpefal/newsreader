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
    );

void main() {
  late MockBox mockBox;
  late HiveArticleDatasource datasource;

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
  });
}
