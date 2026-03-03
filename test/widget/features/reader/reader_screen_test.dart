import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    excerpt: 'Este es el resumen del artículo.',
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

    testWidgets('muestra el excerpt cuando está disponible', (tester) async {
      await tester.pumpWidget(_buildSubject(tArticle, mockMarkAsRead));

      expect(find.text('Este es el resumen del artículo.'), findsOneWidget);
    });

    testWidgets('no muestra excerpt cuando es nulo', (tester) async {
      final articleSinExcerpt = Article(
        id: 'a2',
        sourceId: 's1',
        sourceName: 'Newsletter A',
        title: 'Sin resumen',
        publishedAt: DateTime(2024, 3, 15),
        articleUrl: 'https://example.com/article',
      );

      await tester.pumpWidget(_buildSubject(articleSinExcerpt, mockMarkAsRead));

      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('llama a markAsRead con el id del artículo al abrir',
        (tester) async {
      await tester.pumpWidget(_buildSubject(tArticle, mockMarkAsRead));
      await tester.pump();

      verify(() => mockMarkAsRead.execute('a1')).called(1);
    });
  });
}
