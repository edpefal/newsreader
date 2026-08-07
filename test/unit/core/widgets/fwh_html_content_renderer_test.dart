import 'package:flutter_test/flutter_test.dart';

import 'package:newsreader/core/widgets/fwh_html_content_renderer.dart';

void main() {
  group('normalizeYoutubeUrl', () {
    test('quita el parámetro origin de una URL /embed/<id>', () {
      final result = normalizeYoutubeUrl(
        'https://www.youtube.com/embed/VIDEO_ID?origin=https://sitio-original.com',
      );

      expect(result, 'https://www.youtube.com/embed/VIDEO_ID');
    });

    test('convierte el formato deprecado /v/<id> a /embed/<id>', () {
      final result = normalizeYoutubeUrl(
        'https://www.youtube.com/v/VIDEO_ID',
      );

      expect(result, 'https://www.youtube.com/embed/VIDEO_ID');
    });

    test('convierte un link corto youtu.be/<id> a /embed/<id>', () {
      final result = normalizeYoutubeUrl('https://youtu.be/VIDEO_ID');

      expect(result, 'https://www.youtube.com/embed/VIDEO_ID');
    });

    test('conserva otros parámetros de query que no sean origin', () {
      final result = normalizeYoutubeUrl(
        'https://www.youtube.com/embed/VIDEO_ID?origin=https://x.com&autoplay=1',
      );

      expect(result, 'https://www.youtube.com/embed/VIDEO_ID?autoplay=1');
    });

    test('retorna null para una URL de un dominio que no es YouTube', () {
      final result = normalizeYoutubeUrl(
        'https://open.spotify.com/embed/episode/abc123',
      );

      expect(result, isNull);
    });

    test('retorna null para una URL de YouTube sin videoId reconocible', () {
      final result = normalizeYoutubeUrl('https://www.youtube.com/');

      expect(result, isNull);
    });
  });
}
