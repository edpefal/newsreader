import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/data/datasources/local/daily_summary_free_usage_local_datasource.dart';
import 'package:newsreader/core/data/datasources/local/hive_daily_summary_free_usage_datasource.dart';
import 'package:newsreader/core/data/models/daily_summary_free_usage_model.dart';
import 'package:newsreader/core/data/repositories/daily_summary_free_usage_repository_impl.dart';

class MockDailySummaryFreeUsageLocalDataSource extends Mock
    implements DailySummaryFreeUsageLocalDataSource {}

void main() {
  late MockDailySummaryFreeUsageLocalDataSource mockDataSource;
  late DailySummaryFreeUsageRepositoryImpl sut;

  setUp(() {
    mockDataSource = MockDailySummaryFreeUsageLocalDataSource();
    sut = DailySummaryFreeUsageRepositoryImpl(mockDataSource);
  });

  group('getStatus', () {
    test('sin uso previo, devuelve cupo disponible', () async {
      when(() => mockDataSource.get()).thenAnswer((_) async => null);

      final status = await sut.getStatus();

      expect(status.usedThisWeek, isFalse);
      expect(status.available, isTrue);
    });

    test('con uso registrado de la semana calendario en curso, refleja el uso', () async {
      final currentWeekStart =
          HiveDailySummaryFreeUsageDatasource.weekStartOf(DateTime.now());
      when(() => mockDataSource.get()).thenAnswer(
        (_) async =>
            DailySummaryFreeUsageModel(weekStart: currentWeekStart, used: true),
      );

      final status = await sut.getStatus();

      expect(status.usedThisWeek, isTrue);
      expect(status.available, isFalse);
    });

    test('con uso de una semana calendario distinta, lo trata como disponible', () async {
      when(() => mockDataSource.get()).thenAnswer(
        (_) async =>
            DailySummaryFreeUsageModel(weekStart: DateTime(2000, 1, 3), used: true),
      );

      final status = await sut.getStatus();

      expect(status.usedThisWeek, isFalse);
      expect(status.available, isTrue);
    });
  });

  group('recordLocalUsage', () {
    test('delega en el datasource local', () async {
      when(() => mockDataSource.recordLocalUsage()).thenAnswer((_) async {});

      await sut.recordLocalUsage();

      verify(() => mockDataSource.recordLocalUsage()).called(1);
    });
  });
}
