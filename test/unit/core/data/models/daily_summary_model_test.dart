import 'package:flutter_test/flutter_test.dart';

import 'package:newsreader/core/data/models/daily_summary_model.dart';
import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/domain/entities/summary_source_block.dart';

void main() {
  group('DailySummaryModel', () {
    test('fromEntity/toEntity preservan sourceBlocks', () {
      final entity = DailySummary(
        id: '2026-08-10',
        date: DateTime(2026, 8, 10),
        content: 'Fuente A\nPárrafo A',
        articleCount: 2,
        createdAt: DateTime(2026, 8, 10, 9),
        sourceBlocks: const [
          SummarySourceBlock(
            sourceId: 's1',
            sourceName: 'Fuente A',
            articleIds: ['a1', 'a2'],
          ),
        ],
      );

      final model = DailySummaryModel.fromEntity(entity);
      final roundTripped = model.toEntity();

      expect(roundTripped.sourceBlocks, entity.sourceBlocks);
    });

    test('toEntity() sobre un modelo sin sourceBlocks (dato viejo) no falla',
        () {
      final model = DailySummaryModel(
        id: '2026-08-01',
        date: DateTime(2026, 8, 1),
        content: 'Contenido viejo',
        articleCount: 1,
        createdAt: DateTime(2026, 8, 1),
      );

      final entity = model.toEntity();

      expect(entity.sourceBlocks, isNull);
    });
  });
}
