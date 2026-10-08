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
  DateTime? dismissedAt,
}) =>
    DailySummaryModel(
      id: 'summary-1',
      date: date ?? DateTime(2026, 9, 9),
      content: 'contenido',
      articleCount: 3,
      createdAt: DateTime(2026, 9, 9),
      sourceBlocks: sourceBlocks,
      dismissedAt: dismissedAt,
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

  group('applyRemote: dismissedAt', () {
    test('un remoto sin dismissedAt conserva el descarte local aún no subido',
        () async {
      final local = _summary(dismissedAt: DateTime(2026, 9, 9, 12));
      final remote = _summary();
      when(() => mockBox.get(dateKey(remote.date))).thenReturn(local);

      await datasource.applyRemote(remote);

      expect(remote.dismissedAt, DateTime(2026, 9, 9, 12));
    });

    test('un remoto con dismissedAt se aplica tal cual', () async {
      final remote = _summary(dismissedAt: DateTime(2026, 9, 9, 15));
      when(() => mockBox.get(dateKey(remote.date))).thenReturn(_summary());

      await datasource.applyRemote(remote);

      expect(remote.dismissedAt, DateTime(2026, 9, 9, 15));
    });
  });

  group('dismiss', () {
    test('setea dismissedAt y updatedAt a ahora y persiste', () async {
      final model = _summary();
      when(() => mockBox.values).thenReturn([model]);
      final before = DateTime.now();

      final result = await datasource.dismiss('summary-1');

      expect(result, same(model));
      expect(model.dismissedAt!.isBefore(before), isFalse);
      expect(model.updatedAt, model.dismissedAt);
      verify(() => mockBox.put(dateKey(model.date), model)).called(1);
    });

    test('es idempotente: un resumen ya descartado no se reescribe', () async {
      final dismissedAt = DateTime(2026, 9, 9, 12);
      final model = _summary(dismissedAt: dismissedAt);
      when(() => mockBox.values).thenReturn([model]);

      final result = await datasource.dismiss('summary-1');

      expect(result, isNull);
      expect(model.dismissedAt, dismissedAt);
      verifyNever(() => mockBox.put(any(), any()));
    });

    test('un id inexistente no escribe nada', () async {
      when(() => mockBox.values).thenReturn([_summary()]);

      final result = await datasource.dismiss('otro');

      expect(result, isNull);
      verifyNever(() => mockBox.put(any(), any()));
    });
  });

  group('watchAll', () {
    test('emite la lista ordenada (más reciente primero) ante cada cambio',
        () async {
      final older = _summary(date: DateTime(2026, 9, 8));
      final newer = _summary(date: DateTime(2026, 9, 9));
      when(() => mockBox.values).thenReturn([older, newer]);
      when(() => mockBox.watch())
          .thenAnswer((_) => Stream.value(BoxEvent('k', null, false)));

      final emitted = await datasource.watchAll().first;

      expect(emitted, [newer, older]);
    });
  });
}
