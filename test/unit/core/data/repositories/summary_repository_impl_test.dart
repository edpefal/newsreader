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
}
