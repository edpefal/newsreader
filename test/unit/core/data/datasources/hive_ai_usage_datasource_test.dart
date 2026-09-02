import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/data/datasources/local/hive_ai_usage_datasource.dart';
import 'package:newsreader/core/data/models/ai_usage_daily_model.dart';

class MockBox extends Mock implements Box<AiUsageDailyModel> {}

void main() {
  late MockBox mockBox;
  late HiveAiUsageDatasource datasource;

  setUpAll(() {
    registerFallbackValue(
      AiUsageDailyModel(day: DateTime(2024), summariesUsed: 0),
    );
  });

  setUp(() {
    mockBox = MockBox();
    datasource = HiveAiUsageDatasource(mockBox);
    when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
  });

  group('get / applyRemote', () {
    test('get() devuelve lo que hay en la única key de la box', () async {
      final model = AiUsageDailyModel(day: DateTime(2024, 5, 1), summariesUsed: 3);
      when(() => mockBox.get('current')).thenReturn(model);

      expect(await datasource.get(), model);
    });

    test('applyRemote() reemplaza la copia local', () async {
      final model = AiUsageDailyModel(day: DateTime(2024, 5, 1), summariesUsed: 3);

      await datasource.applyRemote(model);

      verify(() => mockBox.put('current', model)).called(1);
    });
  });

  group('recordLocalUsage', () {
    test('sin consumo previo, arranca en 1 con el día de hoy', () async {
      when(() => mockBox.get('current')).thenReturn(null);
      final today = DateTime.now();

      await datasource.recordLocalUsage();

      final captured =
          verify(() => mockBox.put('current', captureAny())).captured.single
              as AiUsageDailyModel;
      expect(captured.summariesUsed, 1);
      expect(captured.day.year, today.year);
      expect(captured.day.month, today.month);
      expect(captured.day.day, today.day);
    });

    test('con consumo previo de hoy, incrementa en 1', () async {
      final today = DateTime.now();
      when(() => mockBox.get('current')).thenReturn(
        AiUsageDailyModel(
          day: DateTime(today.year, today.month, today.day),
          summariesUsed: 4,
        ),
      );

      await datasource.recordLocalUsage();

      final captured =
          verify(() => mockBox.put('current', captureAny())).captured.single
              as AiUsageDailyModel;
      expect(captured.summariesUsed, 5);
    });

    test('con consumo previo de otro día, resetea a 1', () async {
      when(() => mockBox.get('current')).thenReturn(
        AiUsageDailyModel(day: DateTime(2000, 1, 1), summariesUsed: 20),
      );

      await datasource.recordLocalUsage();

      final captured =
          verify(() => mockBox.put('current', captureAny())).captured.single
              as AiUsageDailyModel;
      expect(captured.summariesUsed, 1);
    });
  });
}
