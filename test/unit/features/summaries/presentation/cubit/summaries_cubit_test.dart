import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/features/summaries/domain/usecases/get_latest_daily_summary.dart';
import 'package:newsreader/features/summaries/presentation/cubit/summaries_cubit.dart';

class MockGetLatestDailySummary extends Mock implements GetLatestDailySummary {}

void main() {
  late MockGetLatestDailySummary mockGetLatestDailySummary;

  final tSummary = DailySummary(
    id: '2026-07-09',
    date: DateTime(2026, 7, 9),
    content: 'Resumen de hoy',
    articleCount: 4,
    createdAt: DateTime(2026, 7, 9),
  );

  SummariesCubit buildCubit() => SummariesCubit(mockGetLatestDailySummary);

  setUp(() {
    mockGetLatestDailySummary = MockGetLatestDailySummary();
  });

  group('SummariesCubit', () {
    test('estado inicial es SummariesLoading', () {
      expect(buildCubit().state, const SummariesLoading());
    });

    blocTest<SummariesCubit, SummariesState>(
      'loadSummaries() emite Loaded con el resumen más reciente',
      build: () {
        when(() => mockGetLatestDailySummary.execute())
            .thenAnswer((_) async => tSummary);
        return buildCubit();
      },
      act: (cubit) => cubit.loadSummaries(),
      expect: () => [
        const SummariesLoading(),
        SummariesLoaded(summary: tSummary),
      ],
    );

    blocTest<SummariesCubit, SummariesState>(
      'loadSummaries() emite Loaded sin resumen cuando no hay ninguno',
      build: () {
        when(() => mockGetLatestDailySummary.execute())
            .thenAnswer((_) async => null);
        return buildCubit();
      },
      act: (cubit) => cubit.loadSummaries(),
      expect: () => [
        const SummariesLoading(),
        const SummariesLoaded(summary: null),
      ],
    );
  });
}
