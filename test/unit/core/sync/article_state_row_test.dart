import 'package:flutter_test/flutter_test.dart';

import 'package:newsreader/core/data/models/article_model.dart';
import 'package:newsreader/core/sync/article_state_row.dart';

ArticleModel _article({
  DateTime? readAt,
  DateTime? savedAsFavoriteAt,
  DateTime? updatedAt,
  DateTime? deletedAt,
}) =>
    ArticleModel(
      id: 'a1',
      sourceId: 's1',
      sourceName: 'Source',
      title: 'Título',
      articleUrl: 'https://example.com/a1',
      publishedAt: DateTime(2026),
      isRead: true,
      isFavorite: false,
      isArchived: false,
      readAt: readAt,
      savedAsFavoriteAt: savedAsFavoriteAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );

void main() {
  test('mapea únicamente el estado de usuario, nunca el contenido', () {
    final row = articleStateRow(_article(updatedAt: DateTime(2026, 1, 1)));

    expect(row['id'], 'a1');
    expect(row['is_read'], true);
    expect(row['is_favorite'], false);
    expect(row['is_archived'], false);
    expect(row.containsKey('title'), isFalse);
    expect(row.containsKey('content_html'), isFalse);
    expect(row.containsKey('source_id'), isFalse);
  });

  test('serializa readAt/savedAsFavoriteAt/deletedAt como null cuando no están seteados', () {
    final row = articleStateRow(_article(updatedAt: DateTime(2026, 1, 1)));

    expect(row['read_at'], isNull);
    expect(row['saved_as_favorite_at'], isNull);
    expect(row['deleted_at'], isNull);
  });

  test('serializa los timestamps en UTC', () {
    final row = articleStateRow(
      _article(
        readAt: DateTime(2026, 1, 1, 10),
        updatedAt: DateTime(2026, 1, 1, 10),
      ),
    );

    expect(row['read_at'], endsWith('Z'));
    expect(row['updated_at'], endsWith('Z'));
  });

  test('usa DateTime.now() como fallback si updatedAt es null', () {
    final row = articleStateRow(_article());

    expect(row['updated_at'], isNotNull);
    expect(row['updated_at'], endsWith('Z'));
  });
}
