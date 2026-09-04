import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/constants/app_constants.dart';
import 'package:newsreader/core/data/datasources/local/ai_usage_local_datasource.dart';
import 'package:newsreader/core/data/models/ai_usage_daily_model.dart';
import 'package:newsreader/core/data/repositories/ai_usage_repository_impl.dart';
import 'package:newsreader/core/subscription/subscription_status_provider.dart';

class MockAiUsageLocalDataSource extends Mock
    implements AiUsageLocalDataSource {}

class MockSubscriptionStatusProvider extends Mock
    implements SubscriptionStatusProvider {}

void main() {
  late MockAiUsageLocalDataSource mockDataSource;
  late MockSubscriptionStatusProvider mockSubscriptionStatusProvider;
  late AiUsageRepositoryImpl sut;

  setUp(() {
    mockDataSource = MockAiUsageLocalDataSource();
    mockSubscriptionStatusProvider = MockSubscriptionStatusProvider();
    when(() => mockSubscriptionStatusProvider.isSubscribed).thenReturn(true);
    sut = AiUsageRepositoryImpl(mockDataSource, mockSubscriptionStatusProvider);
  });

  group('getStatus', () {
    test('sin consumo previo, devuelve 0 usados y el límite vigente', () async {
      when(() => mockDataSource.get()).thenAnswer((_) async => null);

      final status = await sut.getStatus();

      expect(status.summariesUsedToday, 0);
      expect(status.dailyLimit, AppConstants.aiUsageDailySummaryLimit);
      expect(status.remaining, AppConstants.aiUsageDailySummaryLimit);
    });

    test('con consumo de hoy, lo refleja en el restante', () async {
      final today = DateTime.now();
      when(() => mockDataSource.get()).thenAnswer(
        (_) async => AiUsageDailyModel(
          day: DateTime(today.year, today.month, today.day),
          summariesUsed: 20,
        ),
      );

      final status = await sut.getStatus();

      expect(status.summariesUsedToday, 20);
      expect(status.remaining, AppConstants.aiUsageDailySummaryLimit - 20);
    });

    test('con consumo de un día distinto a hoy, lo trata como 0', () async {
      when(() => mockDataSource.get()).thenAnswer(
        (_) async => AiUsageDailyModel(day: DateTime(2000, 1, 1), summariesUsed: 20),
      );

      final status = await sut.getStatus();

      expect(status.summariesUsedToday, 0);
      expect(status.remaining, AppConstants.aiUsageDailySummaryLimit);
    });

    test('con suscripción activa, el límite vigente es 25', () async {
      when(() => mockDataSource.get()).thenAnswer((_) async => null);
      when(() => mockSubscriptionStatusProvider.isSubscribed).thenReturn(true);

      final status = await sut.getStatus();

      expect(status.dailyLimit, AppConstants.aiUsageDailySummaryLimit);
    });

    test('sin suscripción activa, el límite vigente es el del free tier', () async {
      when(() => mockDataSource.get()).thenAnswer((_) async => null);
      when(() => mockSubscriptionStatusProvider.isSubscribed).thenReturn(false);

      final status = await sut.getStatus();

      expect(status.dailyLimit, AppConstants.aiUsageFreeTierDailyLimit);
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
