import 'package:newsreader/core/constants/app_constants.dart';
import 'package:newsreader/core/data/datasources/local/ai_usage_local_datasource.dart';
import 'package:newsreader/core/domain/entities/ai_usage_status.dart';
import 'package:newsreader/core/domain/repositories/ai_usage_repository.dart';
import 'package:newsreader/core/subscription/subscription_status_provider.dart';

class AiUsageRepositoryImpl implements AiUsageRepository {
  final AiUsageLocalDataSource _dataSource;
  final SubscriptionStatusProvider _subscriptionStatusProvider;

  const AiUsageRepositoryImpl(this._dataSource, this._subscriptionStatusProvider);

  /// 25 con suscripción activa, 2 sin ella (ver capability
  /// `ai-usage-budget`) -- ambos casos comparten el mismo contador diario,
  /// solo cambia contra qué límite se compara.
  int get _dailyLimit => _subscriptionStatusProvider.isSubscribed
      ? AppConstants.aiUsageDailySummaryLimit
      : AppConstants.aiUsageFreeTierDailyLimit;

  @override
  Future<AiUsageStatus> getStatus() async {
    final model = await _dataSource.get();
    if (model == null) {
      return AiUsageStatus(
        summariesUsedToday: 0,
        dailyLimit: _dailyLimit,
      );
    }

    final now = DateTime.now();
    final isToday = model.day.year == now.year &&
        model.day.month == now.month &&
        model.day.day == now.day;

    return AiUsageStatus(
      summariesUsedToday: isToday ? model.summariesUsed : 0,
      dailyLimit: _dailyLimit,
    );
  }

  @override
  Future<void> recordLocalUsage() => _dataSource.recordLocalUsage();
}
