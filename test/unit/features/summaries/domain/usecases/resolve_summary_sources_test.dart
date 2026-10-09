import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/core/domain/repositories/source_repository.dart';
import 'package:newsreader/features/summaries/domain/usecases/resolve_summary_sources.dart';

class MockSourceRepository extends Mock implements SourceRepository {}

NewsSource _source(String id) => NewsSource(
  id: id,
  name: 'Fuente $id',
  feedUrl: 'https://example.com/$id.xml',
  iconUrl: 'https://example.com/$id.png',
  addedAt: DateTime(2026, 7, 1),
);

void main() {
  late MockSourceRepository repository;
  late ResolveSummarySources useCase;

  setUp(() {
    repository = MockSourceRepository();
    useCase = ResolveSummarySources(repository);
  });

  test('devuelve todas las fuentes cuando existen', () async {
    when(
      () => repository.getSourceById('s1'),
    ).thenAnswer((_) async => _source('s1'));
    when(
      () => repository.getSourceById('s2'),
    ).thenAnswer((_) async => _source('s2'));

    final result = await useCase.execute(['s1', 's2']);

    expect(result.keys, ['s1', 's2']);
    expect(result['s2']!.iconUrl, 'https://example.com/s2.png');
  });

  test('descarta en silencio los ids que no existen', () async {
    when(
      () => repository.getSourceById('s1'),
    ).thenAnswer((_) async => _source('s1'));
    when(
      () => repository.getSourceById('borrada'),
    ).thenAnswer((_) async => null);

    final result = await useCase.execute(['s1', 'borrada']);

    expect(result.keys, ['s1']);
  });

  test('con lista vacía no consulta el repositorio', () async {
    final result = await useCase.execute([]);

    expect(result, isEmpty);
    verifyNever(() => repository.getSourceById(any()));
  });
}
