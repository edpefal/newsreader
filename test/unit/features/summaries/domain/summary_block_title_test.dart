import 'package:flutter_test/flutter_test.dart';

import 'package:newsreader/features/summaries/domain/summary_block_title.dart';

void main() {
  group('normalizeSummaryBlockTitle', () {
    test('quita la etiqueta "Fuente:" en español', () {
      expect(normalizeSummaryBlockTitle('Fuente: TechCrunch'), 'TechCrunch');
    });

    test('no distingue mayúsculas de minúsculas en la etiqueta', () {
      expect(normalizeSummaryBlockTitle('fuente: TechCrunch'), 'TechCrunch');
      expect(normalizeSummaryBlockTitle('FUENTE: TechCrunch'), 'TechCrunch');
    });

    test('quita la etiqueta "Source:" en inglés', () {
      expect(normalizeSummaryBlockTitle('Source: Stratechery'), 'Stratechery');
    });

    test('quita "Source :" del francés (espacio antes de los dos puntos)', () {
      expect(normalizeSummaryBlockTitle('Source : Stratechery'), 'Stratechery');
    });

    test('tolera espacios sobrantes alrededor', () {
      expect(
        normalizeSummaryBlockTitle('  Fuente:   TechCrunch  '),
        'TechCrunch',
      );
    });

    test('un título sin etiqueta queda igual', () {
      expect(normalizeSummaryBlockTitle('TechCrunch'), 'TechCrunch');
    });

    test('una fuente con dos puntos que no empieza con la etiqueta no se altera',
        () {
      expect(
        normalizeSummaryBlockTitle('Reuters: World News'),
        'Reuters: World News',
      );
    });

    test('una palabra que solo empieza como la etiqueta no se altera', () {
      expect(normalizeSummaryBlockTitle('Fuentes: Varias'), 'Fuentes: Varias');
      expect(normalizeSummaryBlockTitle('Sourcery: Daily'), 'Sourcery: Daily');
    });

    test('si solo hay la etiqueta, devuelve el título original', () {
      expect(normalizeSummaryBlockTitle('Fuente:'), 'Fuente:');
      expect(normalizeSummaryBlockTitle('Source :   '), 'Source :');
    });
  });
}
