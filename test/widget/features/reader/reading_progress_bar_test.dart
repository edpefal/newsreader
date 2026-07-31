import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/features/inbox/domain/usecases/mark_article_as_read.dart';
import 'package:newsreader/features/reader/domain/usecases/toggle_favorite.dart';
import 'package:newsreader/features/reader/presentation/screens/reader_screen.dart';

class MockMarkArticleAsRead extends Mock implements MarkArticleAsRead {}

class MockToggleFavorite extends Mock implements ToggleFavorite {}

Widget _buildSubject(
  Article article,
  MarkArticleAsRead markAsRead,
  ToggleFavorite toggleFavorite,
) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => ReaderScreen(
          article: article,
          markAsRead: markAsRead,
          toggleFavorite: toggleFavorite,
        ),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  late MockMarkArticleAsRead mockMarkAsRead;
  late MockToggleFavorite mockToggleFavorite;

  setUp(() {
    mockMarkAsRead = MockMarkArticleAsRead();
    mockToggleFavorite = MockToggleFavorite();
    when(() => mockMarkAsRead.execute(any())).thenAnswer((_) async {});
    when(() => mockToggleFavorite.execute(any())).thenAnswer((_) async {});
  });

  group('ReadingProgressBar en ReaderScreen', () {
    testWidgets(
        'no se muestra cuando el contenido cabe completamente en el viewport',
        (tester) async {
      final articleCorto = Article(
        id: 'short',
        sourceId: 's1',
        sourceName: 'Newsletter A',
        title: 'Artículo corto',
        excerpt: 'Un resumen breve.',
        publishedAt: DateTime(2024, 3, 15),
        articleUrl: 'https://example.com/article',
      );

      await tester.pumpWidget(
          _buildSubject(articleCorto, mockMarkAsRead, mockToggleFavorite));
      await tester.pumpAndSettle();

      expect(find.byType(FractionallySizedBox), findsNothing);
    });

    testWidgets(
        'se muestra y avanza el progreso al hacer scroll en contenido largo',
        (tester) async {
      final articleLargo = Article(
        id: 'long',
        sourceId: 's1',
        sourceName: 'Newsletter A',
        title: 'Artículo largo',
        excerpt: 'Párrafo de contenido. ' * 300,
        publishedAt: DateTime(2024, 3, 15),
        articleUrl: 'https://example.com/article',
      );

      await tester.pumpWidget(
          _buildSubject(articleLargo, mockMarkAsRead, mockToggleFavorite));
      await tester.pumpAndSettle();

      expect(find.byType(FractionallySizedBox), findsOneWidget);

      final barAntes =
          tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox));
      expect(barAntes.heightFactor, 0);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -2000),
      );
      await tester.pump();

      final barDespues =
          tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox));
      expect(barDespues.heightFactor, greaterThan(0));
    });
  });
}
