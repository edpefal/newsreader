import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/data/datasources/local/source_local_datasource.dart';
import 'package:newsreader/core/data/models/news_source_model.dart';
import 'package:newsreader/core/data/repositories/source_repository_impl.dart';

class MockSourceLocalDataSource extends Mock implements SourceLocalDataSource {}

NewsSourceModel _source(String id) => NewsSourceModel(
      id: id,
      name: 'Source $id',
      feedUrl: 'https://example.com/$id/feed',
      addedAt: DateTime(2026),
    );

void main() {
  late MockSourceLocalDataSource mockLocal;
  late SourceRepositoryImpl sut;

  setUp(() {
    mockLocal = MockSourceLocalDataSource();
    sut = SourceRepositoryImpl(mockLocal);
  });

  group('getSourceById', () {
    test('devuelve la fuente cuando existe', () async {
      when(() => mockLocal.getSources())
          .thenAnswer((_) async => [_source('s1'), _source('s2')]);

      final result = await sut.getSourceById('s2');

      expect(result?.id, 's2');
    });

    test('devuelve null cuando no existe', () async {
      when(() => mockLocal.getSources())
          .thenAnswer((_) async => [_source('s1')]);

      final result = await sut.getSourceById('missing');

      expect(result, isNull);
    });
  });
}
