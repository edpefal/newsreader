import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/widgets/chamfered_box.dart';
import 'package:newsreader/features/inbox/presentation/widgets/article_inbox_tile.dart';
import 'package:newsreader/presentation/theme/app_theme.dart';

import '../../../../support/pump_localized_app.dart';

Article _article({
  String? imageUrl,
  bool isRead = false,
  bool isFavorite = false,
}) =>
    Article(
      id: '1',
      sourceId: 's1',
      sourceName: 'Newsletter A',
      title: 'Artículo de prueba',
      publishedAt: DateTime(2024, 1, 15),
      articleUrl: 'https://example.com/1',
      imageUrl: imageUrl,
      isRead: isRead,
      isFavorite: isFavorite,
    );

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light,
      locale: testLocale,
      localizationsDelegates: testLocalizationsDelegates,
      supportedLocales: testSupportedLocales,
      home: Scaffold(body: child),
    );

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

  testWidgets('muestra el chaflán ámbar de no-leído cuando el artículo no fue leído', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(ArticleInboxTile(article: _article(isRead: false))),
    );

    expect(find.byType(ChamferedBox), findsWidgets);
  });

  testWidgets('no muestra el chaflán de no-leído cuando el artículo ya fue leído', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(ArticleInboxTile(article: _article(isRead: true))),
    );

    // SourceIcon también usa ChamferedBox; con isRead=true solo debe
    // quedar ese, no el indicador de no-leído.
    expect(find.byType(ChamferedBox), findsOneWidget);
  });

  testWidgets('muestra el ícono de favorito en ámbar cuando el artículo está marcado', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(ArticleInboxTile(article: _article(isFavorite: true))),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.star));
    expect(icon.color, AppTheme.light.extension<ReevoAccent>()!.unreadFavoriteAmber);
  });

  testWidgets('no muestra ícono de favorito cuando el artículo no está marcado', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(ArticleInboxTile(article: _article(isFavorite: false))),
    );

    expect(find.byIcon(Icons.star), findsNothing);
  });
}
