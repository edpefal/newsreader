import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/features/inbox/domain/usecases/mark_article_as_read.dart';
import 'package:newsreader/features/reader/presentation/screens/reader_screen.dart';

class MockMarkArticleAsRead extends Mock implements MarkArticleAsRead {}

Widget _buildSubject(Article article, MarkArticleAsRead markAsRead) {
  return MaterialApp(
    home: ReaderScreen(article: article, markAsRead: markAsRead),
  );
}

void main() {
  late MockMarkArticleAsRead mockMarkAsRead;

  final tArticle = Article(
    id: 'a1',
    sourceId: 's1',
    sourceName: 'Newsletter A',
    title: 'Un artículo interesante',
    author: 'Juan Pérez',
    contentHtml: '<p>Contenido completo del artículo.</p>',
    excerpt: 'Este es el resumen.',
    publishedAt: DateTime(2024, 3, 15),
    articleUrl: 'https://example.com/article',
  );

  setUp(() {
    mockMarkAsRead = MockMarkArticleAsRead();
    when(() => mockMarkAsRead.execute(any())).thenAnswer((_) async {});
  });

  group('ReaderScreen', () {
    testWidgets('muestra el nombre de la fuente en el AppBar', (tester) async {
      await tester.pumpWidget(_buildSubject(tArticle, mockMarkAsRead));

      expect(find.text('Newsletter A'), findsOneWidget);
    });

    testWidgets('muestra el título del artículo', (tester) async {
      await tester.pumpWidget(_buildSubject(tArticle, mockMarkAsRead));

      expect(find.text('Un artículo interesante'), findsOneWidget);
    });

    testWidgets('muestra el autor y la fecha', (tester) async {
      await tester.pumpWidget(_buildSubject(tArticle, mockMarkAsRead));

      expect(find.textContaining('Juan Pérez'), findsOneWidget);
      expect(find.textContaining('15/3/2024'), findsOneWidget);
    });

    testWidgets('muestra HtmlWidget cuando hay contentHtml', (tester) async {
      await tester.pumpWidget(_buildSubject(tArticle, mockMarkAsRead));
      await tester.pump();

      expect(find.byType(HtmlWidget), findsOneWidget);
    });

    testWidgets('muestra excerpt cuando contentHtml es nulo', (tester) async {
      final articleSinHtml = Article(
        id: 'a2',
        sourceId: 's1',
        sourceName: 'Newsletter A',
        title: 'Sin HTML',
        excerpt: 'Solo el resumen.',
        publishedAt: DateTime(2024, 3, 15),
        articleUrl: 'https://example.com/article',
      );

      await tester.pumpWidget(_buildSubject(articleSinHtml, mockMarkAsRead));

      expect(find.text('Solo el resumen.'), findsOneWidget);
      expect(find.byType(HtmlWidget), findsNothing);
    });

    testWidgets('muestra fallback cuando no hay contentHtml ni excerpt',
        (tester) async {
      final articleMinimal = Article(
        id: 'a3',
        sourceId: 's1',
        sourceName: 'Newsletter A',
        title: 'Sin contenido',
        publishedAt: DateTime(2024, 3, 15),
        articleUrl: 'https://example.com/article',
      );

      await tester.pumpWidget(_buildSubject(articleMinimal, mockMarkAsRead));

      expect(
        find.text('Contenido no disponible en el feed.'),
        findsOneWidget,
      );
      expect(find.byType(HtmlWidget), findsNothing);
    });

    testWidgets('llama a markAsRead con el id del artículo al abrir',
        (tester) async {
      await tester.pumpWidget(_buildSubject(tArticle, mockMarkAsRead));
      await tester.pump();

      verify(() => mockMarkAsRead.execute('a1')).called(1);
    });
  });
}
