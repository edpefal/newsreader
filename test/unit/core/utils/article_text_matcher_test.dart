import 'package:flutter_test/flutter_test.dart';
import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/utils/article_text_matcher.dart';

Article _article({
  String title = 'Un título cualquiera',
  String sourceName = 'Newsletter Genérico',
  String? author = 'Autor Genérico',
  String? contentHtml,
  String? excerpt,
}) {
  return Article(
    id: 'id',
    sourceId: 'source-id',
    sourceName: sourceName,
    title: title,
    author: author,
    publishedAt: DateTime(2026, 1, 1),
    contentHtml: contentHtml,
    excerpt: excerpt,
    articleUrl: 'https://example.com/article',
  );
}

void main() {
  group('articleMatchesQuery', () {
    test('matchea por título, insensible a mayúsculas y por substring', () {
      final article = _article(title: 'Cómo escribir mejor código Dart');
      expect(articleMatchesQuery(article, 'ESCRIBIR'), isTrue);
    });

    test('matchea por nombre de fuente aunque no coincida con el título', () {
      final article = _article(
        title: 'Algo sin relación',
        sourceName: 'The Pragmatic Engineer',
      );
      expect(articleMatchesQuery(article, 'pragmatic'), isTrue);
    });

    test('matchea por autor aunque no coincida con título ni fuente', () {
      final article = _article(
        title: 'Algo sin relación',
        sourceName: 'Otra fuente',
        author: 'Gergely Orosz',
      );
      expect(articleMatchesQuery(article, 'orosz'), isTrue);
    });

    test('no matchea si el query no aparece en título, fuente ni autor', () {
      final article = _article(
        title: 'Título',
        sourceName: 'Fuente',
        author: 'Autor',
      );
      expect(articleMatchesQuery(article, 'inexistente'), isFalse);
    });

    test('un query vacío o solo espacios matchea cualquier artículo', () {
      final article = _article();
      expect(articleMatchesQuery(article, ''), isTrue);
      expect(articleMatchesQuery(article, '   '), isTrue);
    });

    test('no considera contentHtml ni excerpt para el matching', () {
      final article = _article(
        title: 'Título',
        sourceName: 'Fuente',
        author: 'Autor',
        contentHtml: '<p>palabra-secreta-en-contenido</p>',
        excerpt: 'palabra-secreta-en-excerpt',
      );
      expect(articleMatchesQuery(article, 'palabra-secreta'), isFalse);
    });

    test('autor nulo no matchea pero tampoco lanza excepción', () {
      final article = _article(author: null);
      expect(articleMatchesQuery(article, 'lo que sea'), isFalse);
    });
  });
}
