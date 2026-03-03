import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
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
      GoRoute(
        path: '/article/:id/web',
        builder: (_, __) => const Scaffold(body: Text('WebView')),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  late MockMarkArticleAsRead mockMarkAsRead;
  late MockToggleFavorite mockToggleFavorite;

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

  final tArticleFavorito = Article(
    id: 'a1',
    sourceId: 's1',
    sourceName: 'Newsletter A',
    title: 'Un artículo interesante',
    publishedAt: DateTime(2024, 3, 15),
    articleUrl: 'https://example.com/article',
    isFavorite: true,
  );

  setUp(() {
    mockMarkAsRead = MockMarkArticleAsRead();
    mockToggleFavorite = MockToggleFavorite();
    when(() => mockMarkAsRead.execute(any())).thenAnswer((_) async {});
    when(() => mockToggleFavorite.execute(any())).thenAnswer((_) async {});
  });

  group('ReaderScreen', () {
    testWidgets('muestra el nombre de la fuente en el AppBar', (tester) async {
      await tester.pumpWidget(
          _buildSubject(tArticle, mockMarkAsRead, mockToggleFavorite));

      expect(find.text('Newsletter A'), findsOneWidget);
    });

    testWidgets('muestra el título del artículo', (tester) async {
      await tester.pumpWidget(
          _buildSubject(tArticle, mockMarkAsRead, mockToggleFavorite));

      expect(find.text('Un artículo interesante'), findsOneWidget);
    });

    testWidgets('muestra el autor y la fecha', (tester) async {
      await tester.pumpWidget(
          _buildSubject(tArticle, mockMarkAsRead, mockToggleFavorite));

      expect(find.textContaining('Juan Pérez'), findsOneWidget);
      expect(find.textContaining('15/3/2024'), findsOneWidget);
    });

    testWidgets('muestra HtmlWidget cuando hay contentHtml', (tester) async {
      await tester.pumpWidget(
          _buildSubject(tArticle, mockMarkAsRead, mockToggleFavorite));
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

      await tester.pumpWidget(
          _buildSubject(articleSinHtml, mockMarkAsRead, mockToggleFavorite));

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

      await tester.pumpWidget(
          _buildSubject(articleMinimal, mockMarkAsRead, mockToggleFavorite));

      expect(find.text('Contenido no disponible en el feed.'), findsOneWidget);
      expect(find.byType(HtmlWidget), findsNothing);
    });

    testWidgets('llama a markAsRead con el id del artículo al abrir',
        (tester) async {
      await tester.pumpWidget(
          _buildSubject(tArticle, mockMarkAsRead, mockToggleFavorite));
      await tester.pump();

      verify(() => mockMarkAsRead.execute('a1')).called(1);
    });

    testWidgets('muestra botón Ver en navegador en el AppBar', (tester) async {
      await tester.pumpWidget(
          _buildSubject(tArticle, mockMarkAsRead, mockToggleFavorite));

      expect(find.byIcon(Icons.open_in_browser), findsOneWidget);
    });

    testWidgets('botón Ver en navegador navega al WebView', (tester) async {
      await tester.pumpWidget(
          _buildSubject(tArticle, mockMarkAsRead, mockToggleFavorite));
      await tester.tap(find.byIcon(Icons.open_in_browser));
      await tester.pumpAndSettle();

      expect(find.text('WebView'), findsOneWidget);
    });

    testWidgets('muestra botón de Modo Reader en el AppBar', (tester) async {
      await tester.pumpWidget(
          _buildSubject(tArticle, mockMarkAsRead, mockToggleFavorite));

      expect(find.byIcon(Icons.chrome_reader_mode_outlined), findsOneWidget);
    });

    testWidgets('activar Modo Reader oculta HtmlWidget y muestra texto plano',
        (tester) async {
      await tester.pumpWidget(
          _buildSubject(tArticle, mockMarkAsRead, mockToggleFavorite));
      await tester.pump();

      expect(find.byType(HtmlWidget), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chrome_reader_mode_outlined));
      await tester.pump();

      expect(find.byType(HtmlWidget), findsNothing);
      expect(find.byIcon(Icons.chrome_reader_mode), findsOneWidget);
    });

    testWidgets('desactivar Modo Reader vuelve a mostrar HtmlWidget',
        (tester) async {
      await tester.pumpWidget(
          _buildSubject(tArticle, mockMarkAsRead, mockToggleFavorite));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.chrome_reader_mode_outlined));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.chrome_reader_mode));
      await tester.pump();

      expect(find.byType(HtmlWidget), findsOneWidget);
    });

    testWidgets('Modo Reader con excerpt (sin contentHtml) muestra el excerpt',
        (tester) async {
      final articleSoloExcerpt = Article(
        id: 'a4',
        sourceId: 's1',
        sourceName: 'Newsletter A',
        title: 'Solo excerpt',
        excerpt: 'Resumen del artículo.',
        publishedAt: DateTime(2024, 3, 15),
        articleUrl: 'https://example.com/article',
      );

      await tester.pumpWidget(
          _buildSubject(articleSoloExcerpt, mockMarkAsRead, mockToggleFavorite));
      await tester.tap(find.byIcon(Icons.chrome_reader_mode_outlined));
      await tester.pump();

      expect(find.text('Resumen del artículo.'), findsOneWidget);
    });

    // --- US-13/14: Favoritos ---

    testWidgets('muestra star_outline cuando el artículo no es favorito',
        (tester) async {
      await tester.pumpWidget(
          _buildSubject(tArticle, mockMarkAsRead, mockToggleFavorite));

      expect(find.byIcon(Icons.star_outline), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('muestra star cuando el artículo ya es favorito',
        (tester) async {
      await tester.pumpWidget(
          _buildSubject(tArticleFavorito, mockMarkAsRead, mockToggleFavorite));

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.star_outline), findsNothing);
    });

    testWidgets('tap en star_outline llama toggleFavorite y muestra star',
        (tester) async {
      await tester.pumpWidget(
          _buildSubject(tArticle, mockMarkAsRead, mockToggleFavorite));

      await tester.tap(find.byIcon(Icons.star_outline));
      await tester.pump();

      verify(() => mockToggleFavorite.execute('a1')).called(1);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.star_outline), findsNothing);
    });

    testWidgets('tap en star llama toggleFavorite y vuelve a star_outline',
        (tester) async {
      await tester.pumpWidget(
          _buildSubject(tArticleFavorito, mockMarkAsRead, mockToggleFavorite));

      await tester.tap(find.byIcon(Icons.star));
      await tester.pump();

      verify(() => mockToggleFavorite.execute('a1')).called(1);
      expect(find.byIcon(Icons.star_outline), findsOneWidget);
    });
  });
}
