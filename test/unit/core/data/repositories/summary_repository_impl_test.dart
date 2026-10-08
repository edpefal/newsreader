import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/data/datasources/local/summary_local_datasource.dart';
import 'package:newsreader/core/data/models/daily_summary_model.dart';
import 'package:newsreader/core/data/repositories/summary_repository_impl.dart';

class MockSummaryLocalDataSource extends Mock implements SummaryLocalDataSource {}

DailySummaryModel _summary(String id) => DailySummaryModel(
      id: id,
      date: DateTime(2026),
      content: 'Contenido $id',
      articleCount: 3,
      createdAt: DateTime(2026),
    );

void main() {
  late MockSummaryLocalDataSource mockDataSource;
  late SummaryRepositoryImpl sut;

  setUp(() {
    mockDataSource = MockSummaryLocalDataSource();
    sut = SummaryRepositoryImpl(mockDataSource);
  });

  group('getById', () {
    test('devuelve el resumen cuando existe', () async {
      when(() => mockDataSource.getAll())
          .thenAnswer((_) async => [_summary('sm1'), _summary('sm2')]);

      final result = await sut.getById('sm2');

      expect(result?.id, 'sm2');
    });

    test('devuelve null cuando no existe', () async {
      when(() => mockDataSource.getAll())
          .thenAnswer((_) async => [_summary('sm1')]);

      final result = await sut.getById('missing');

      expect(result, isNull);
    });
  });

  group('dismiss', () {
    test('devuelve el resumen actualizado con su dismissedAt', () async {
      final dismissedAt = DateTime(2026, 1, 2);
      final model = _summary('sm1')..dismissedAt = dismissedAt;
      when(() => mockDataSource.dismiss('sm1')).thenAnswer((_) async => model);

      final result = await sut.dismiss('sm1');

      expect(result?.id, 'sm1');
      expect(result?.dismissedAt, dismissedAt);
    });

    test('devuelve null si no hay nada que descartar', () async {
      when(() => mockDataSource.dismiss('sm1')).thenAnswer((_) async => null);

      expect(await sut.dismiss('sm1'), isNull);
    });
  });

  group('watchAll', () {
    test('mapea cada emisión del datasource a entidades', () async {
      when(() => mockDataSource.watchAll()).thenAnswer(
        (_) => Stream.value([_summary('sm1'), _summary('sm2')]),
      );

      final emitted = await sut.watchAll().first;

      expect(emitted.map((s) => s.id), ['sm1', 'sm2']);
    });
  });

  test('fromEntity/toEntity conservan dismissedAt', () {
    final model = _summary('sm1')..dismissedAt = DateTime(2026, 3, 4);

    expect(DailySummaryModel.fromEntity(model.toEntity()).dismissedAt,
        DateTime(2026, 3, 4));
  });
}
