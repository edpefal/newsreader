import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xml/xml.dart';

import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/features/account/domain/usecases/export_sources_opml.dart';
import 'package:newsreader/features/sources/domain/usecases/get_sources.dart';

class MockGetSources extends Mock implements GetSources {}

void main() {
  late MockGetSources mockGetSources;

  ExportSourcesOpml buildUseCase() => ExportSourcesOpml(mockGetSources);

  setUp(() {
    mockGetSources = MockGetSources();
  });

  group('ExportSourcesOpml', () {
    test('genera un OPML válido con un outline por fuente', () async {
      when(() => mockGetSources.execute()).thenAnswer(
        (_) async => [
          NewsSource(
            id: '1',
            name: 'Newsletter A',
            feedUrl: 'https://a.com/feed',
            addedAt: DateTime(2024),
          ),
          NewsSource(
            id: '2',
            name: 'Newsletter B',
            feedUrl: 'https://b.com/feed',
            addedAt: DateTime(2024),
          ),
        ],
      );

      final result = await buildUseCase().execute();
      final document = XmlDocument.parse(result);
      final outlines = document.findAllElements('outline').toList();

      expect(outlines, hasLength(2));
      expect(outlines[0].getAttribute('xmlUrl'), 'https://a.com/feed');
      expect(outlines[0].getAttribute('text'), 'Newsletter A');
      expect(outlines[1].getAttribute('xmlUrl'), 'https://b.com/feed');
    });

    test('sin fuentes suscritas, genera un OPML válido sin outlines', () async {
      when(() => mockGetSources.execute()).thenAnswer((_) async => []);

      final result = await buildUseCase().execute();
      final document = XmlDocument.parse(result);

      expect(document.findAllElements('outline'), isEmpty);
      expect(document.findAllElements('opml'), hasLength(1));
    });

    test('escapa caracteres especiales en nombre y URL', () async {
      when(() => mockGetSources.execute()).thenAnswer(
        (_) async => [
          NewsSource(
            id: '1',
            name: 'Tom & Jerry <News>',
            feedUrl: 'https://a.com/feed?x=1&y=2',
            addedAt: DateTime(2024),
          ),
        ],
      );

      final result = await buildUseCase().execute();
      // Si el XML no fuera válido (sin escapar & y <), esto lanzaría.
      final document = XmlDocument.parse(result);
      final outline = document.findAllElements('outline').single;

      expect(outline.getAttribute('text'), 'Tom & Jerry <News>');
      expect(outline.getAttribute('xmlUrl'), 'https://a.com/feed?x=1&y=2');
    });
  });
}
