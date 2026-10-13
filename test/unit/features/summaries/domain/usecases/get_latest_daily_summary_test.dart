import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/domain/repositories/summary_repository.dart';
import 'package:newsreader/features/summaries/domain/usecases/get_latest_daily_summary.dart';

class MockSummaryRepository extends Mock implements SummaryRepository {}

DailySummary _summary(int day) => DailySummary(
      id: '2026-07-$day',
      date: DateTime(2026, 7, day),
      content: 'Resumen del $day',
      articleCount: 3,
      createdAt: DateTime(2026, 7, day),
    );

void main() {
  late MockSummaryRepository mockRepo;
  late GetLatestDailySummary sut;

  setUp(() {
    mockRepo = MockSummaryRepository();
    sut = GetLatestDailySummary(mockRepo);
  });

  test('devuelve null cuando no hay resúmenes', () async {
    when(() => mockRepo.getAll()).thenAnswer((_) async => []);

    expect(await sut.execute(), isNull);
  });

  test('devuelve el único resumen existente', () async {
    final only = _summary(9);
    when(() => mockRepo.getAll()).thenAnswer((_) async => [only]);

    expect(await sut.execute(), only);
  });

  test('devuelve el de fecha más reciente sin depender del orden', () async {
    final latest = _summary(9);
    when(() => mockRepo.getAll()).thenAnswer(
      (_) async => [_summary(7), latest, _summary(8)],
    );

    expect(await sut.execute(), latest);
  });
}
