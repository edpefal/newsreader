import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/domain/repositories/summary_repository.dart';
import 'package:newsreader/features/summaries/domain/usecases/get_daily_summaries.dart';

class MockSummaryRepository extends Mock implements SummaryRepository {}

void main() {
  late MockSummaryRepository mockRepo;
  late GetDailySummaries sut;

  setUp(() {
    mockRepo = MockSummaryRepository();
    sut = GetDailySummaries(mockRepo);
  });

  test('delega en el repositorio y devuelve el orden que retorna', () async {
    final summaries = [
      DailySummary(
        id: '2026-07-09',
        date: DateTime(2026, 7, 9),
        content: 'Resumen de ayer',
        articleCount: 3,
        createdAt: DateTime(2026, 7, 9),
      ),
      DailySummary(
        id: '2026-07-08',
        date: DateTime(2026, 7, 8),
        content: 'Resumen de antes',
        articleCount: 5,
        createdAt: DateTime(2026, 7, 8),
      ),
    ];
    when(() => mockRepo.getAll()).thenAnswer((_) async => summaries);

    final result = await sut.execute();

    expect(result, summaries);
  });
}
