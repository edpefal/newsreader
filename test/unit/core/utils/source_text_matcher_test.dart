import 'package:flutter_test/flutter_test.dart';
import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/core/utils/source_text_matcher.dart';

NewsSource _source({
  String name = 'Newsletter Genérico',
  String? author = 'Autor Genérico',
}) {
  return NewsSource(
    id: 'id',
    name: name,
    feedUrl: 'https://example.com/feed',
    author: author,
    addedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('sourceMatchesQuery', () {
    test('matchea por nombre, insensible a mayúsculas y por substring', () {
      final source = _source(name: 'The Pragmatic Engineer');
      expect(sourceMatchesQuery(source, 'PRAGMATIC'), isTrue);
    });

    test('matchea por autor aunque no coincida con el nombre', () {
      final source = _source(
        name: 'Algo sin relación',
        author: 'Gergely Orosz',
      );
      expect(sourceMatchesQuery(source, 'orosz'), isTrue);
    });

    test('no matchea si el query no aparece en nombre ni autor', () {
      final source = _source(name: 'Nombre', author: 'Autor');
      expect(sourceMatchesQuery(source, 'inexistente'), isFalse);
    });

    test('un query vacío o solo espacios matchea cualquier fuente', () {
      final source = _source();
      expect(sourceMatchesQuery(source, ''), isTrue);
      expect(sourceMatchesQuery(source, '   '), isTrue);
    });

    test('autor nulo no matchea pero tampoco lanza excepción', () {
      final source = _source(author: null);
      expect(sourceMatchesQuery(source, 'lo que sea'), isFalse);
    });
  });
}
