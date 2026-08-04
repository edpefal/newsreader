import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/features/inbox/presentation/widgets/article_inbox_tile.dart';

Article _article({String? imageUrl}) => Article(
      id: '1',
      sourceId: 's1',
      sourceName: 'Newsletter A',
      title: 'Artículo de prueba',
      publishedAt: DateTime(2024, 1, 15),
      articleUrl: 'https://example.com/1',
      imageUrl: imageUrl,
    );

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('no muestra thumbnail cuando el artículo no tiene imagen', (tester) async {
    await tester.pumpWidget(_wrap(ArticleInboxTile(article: _article())));

    final tile = tester.widget<ListTile>(find.byType(ListTile));
    expect(tile.trailing, isNull);
  });

  testWidgets('muestra thumbnail cuando el artículo tiene imagen', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ArticleInboxTile(
          article: _article(imageUrl: 'https://example.com/1/image.jpg'),
        ),
      ),
    );

    final tile = tester.widget<ListTile>(find.byType(ListTile));
    expect(tile.trailing, isNotNull);
  });
}
