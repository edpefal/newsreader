import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/data/datasources/local/hive_summary_datasource.dart';
import 'package:newsreader/core/data/models/daily_summary_model.dart';
import 'package:newsreader/core/utils/date_key.dart';

class MockBox extends Mock implements Box<DailySummaryModel> {}

DailySummaryModel _summary({
  List<Map<dynamic, dynamic>>? sourceBlocks,
  DateTime? date,
}) =>
    DailySummaryModel(
      id: 'summary-1',
      date: date ?? DateTime(2026, 9, 9),
      content: 'contenido',
      articleCount: 3,
      createdAt: DateTime(2026, 9, 9),
      sourceBlocks: sourceBlocks,
    );

void main() {
  late MockBox mockBox;
  late HiveSummaryDatasource datasource;

  setUpAll(() {
    registerFallbackValue(_summary());
  });

  setUp(() {
    mockBox = MockBox();
    datasource = HiveSummaryDatasource(mockBox);
    when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
  });

  group('applyRemote', () {
    final blocks = [
      {
        'sourceId': 's1',
        'sourceName': 'Fuente 1',
        'articleIds': ['a1', 'a2'],
      },
    ];

    test('un remoto con sourceBlocks se aplica tal cual', () async {
      final remote = _summary(sourceBlocks: blocks);
      when(() => mockBox.get(dateKey(remote.date))).thenReturn(null);

      await datasource.applyRemote(remote);

      verify(() => mockBox.put(dateKey(remote.date), remote)).called(1);
      expect(remote.sourceBlocks, blocks);
    });

    test(
        'un remoto sin sourceBlocks no borra el sourceBlocks local ya existente',
        () async {
      final existingLocal = _summary(sourceBlocks: blocks);
      final remoteWithoutBlocks = _summary(sourceBlocks: null);
      when(() => mockBox.get(dateKey(remoteWithoutBlocks.date)))
          .thenReturn(existingLocal);

      await datasource.applyRemote(remoteWithoutBlocks);

      expect(remoteWithoutBlocks.sourceBlocks, blocks);
      verify(() => mockBox.put(dateKey(remoteWithoutBlocks.date), remoteWithoutBlocks))
          .called(1);
    });

    test(
        'un remoto sin sourceBlocks y sin registro local previo queda en null',
        () async {
      final remoteWithoutBlocks = _summary(sourceBlocks: null);
      when(() => mockBox.get(dateKey(remoteWithoutBlocks.date)))
          .thenReturn(null);

      await datasource.applyRemote(remoteWithoutBlocks);

      expect(remoteWithoutBlocks.sourceBlocks, isNull);
    });
  });
}
