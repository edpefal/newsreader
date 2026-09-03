import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/data/datasources/local/hive_daily_summary_free_usage_datasource.dart';
import 'package:newsreader/core/data/models/daily_summary_free_usage_model.dart';

class MockBox extends Mock implements Box<DailySummaryFreeUsageModel> {}

void main() {
  late MockBox mockBox;
  late HiveDailySummaryFreeUsageDatasource datasource;

  setUpAll(() {
    registerFallbackValue(
      DailySummaryFreeUsageModel(weekStart: DateTime(2024), used: false),
    );
  });

  setUp(() {
    mockBox = MockBox();
    datasource = HiveDailySummaryFreeUsageDatasource(mockBox);
    when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
  });

  group('weekStartOf', () {
    test('un lunes devuelve el mismo día a medianoche', () {
      // 2026-07-06 es lunes.
      final result =
          HiveDailySummaryFreeUsageDatasource.weekStartOf(DateTime(2026, 7, 6, 15, 30));

      expect(result, DateTime(2026, 7, 6));
    });

    test('un domingo devuelve el lunes de esa misma semana', () {
      // 2026-07-12 es domingo, la semana empezó el lunes 2026-07-06.
      final result =
          HiveDailySummaryFreeUsageDatasource.weekStartOf(DateTime(2026, 7, 12));

      expect(result, DateTime(2026, 7, 6));
    });
  });

  group('get / applyRemote', () {
    test('get() devuelve lo que hay en la única key de la box', () async {
      final model =
          DailySummaryFreeUsageModel(weekStart: DateTime(2026, 7, 6), used: true);
      when(() => mockBox.get('current')).thenReturn(model);

      expect(await datasource.get(), model);
    });

    test('applyRemote() reemplaza la copia local', () async {
      final model =
          DailySummaryFreeUsageModel(weekStart: DateTime(2026, 7, 6), used: true);

      await datasource.applyRemote(model);

      verify(() => mockBox.put('current', model)).called(1);
    });
  });

  group('recordLocalUsage', () {
    test('marca used=true con el lunes de la semana calendario en curso', () async {
      await datasource.recordLocalUsage();

      final captured =
          verify(() => mockBox.put('current', captureAny())).captured.single
              as DailySummaryFreeUsageModel;
      expect(captured.used, isTrue);
      expect(
        captured.weekStart,
        HiveDailySummaryFreeUsageDatasource.weekStartOf(DateTime.now()),
      );
    });
  });
}
