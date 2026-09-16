import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/features/summaries/domain/usecases/get_daily_summaries.dart';
import 'package:newsreader/features/summaries/presentation/cubit/summaries_cubit.dart';

class MockGetDailySummaries extends Mock implements GetDailySummaries {}

void main() {
  late MockGetDailySummaries mockGetDailySummaries;

  final tSummary = DailySummary(
    id: '2026-07-09',
    date: DateTime(2026, 7, 9),
    content: 'Resumen de hoy',
    articleCount: 4,
    createdAt: DateTime(2026, 7, 9),
  );

  SummariesCubit buildCubit() => SummariesCubit(mockGetDailySummaries);

  setUp(() {
    mockGetDailySummaries = MockGetDailySummaries();
  });

  group('SummariesCubit', () {
    test('estado inicial es SummariesLoading', () {
      expect(buildCubit().state, const SummariesLoading());
    });

    blocTest<SummariesCubit, SummariesState>(
      'loadSummaries() emite Loaded con los resúmenes ya sincronizados',
      build: () {
        when(() => mockGetDailySummaries.execute())
            .thenAnswer((_) async => [tSummary]);
        return buildCubit();
      },
      act: (cubit) => cubit.loadSummaries(),
      expect: () => [
        const SummariesLoading(),
        SummariesLoaded(summaries: [tSummary]),
      ],
    );

    blocTest<SummariesCubit, SummariesState>(
      'loadSummaries() emite Loaded vacío sin resúmenes sincronizados',
      build: () {
        when(() => mockGetDailySummaries.execute())
            .thenAnswer((_) async => []);
        return buildCubit();
      },
      act: (cubit) => cubit.loadSummaries(),
      expect: () => [
        const SummariesLoading(),
        const SummariesLoaded(summaries: []),
      ],
    );
  });
}
