import 'package:newsreader/core/constants/app_constants.dart';
import 'package:newsreader/core/data/datasources/local/ai_usage_local_datasource.dart';
import 'package:newsreader/core/domain/entities/ai_usage_status.dart';
import 'package:newsreader/core/domain/repositories/ai_usage_repository.dart';

class AiUsageRepositoryImpl implements AiUsageRepository {
  final AiUsageLocalDataSource _dataSource;

  const AiUsageRepositoryImpl(this._dataSource);

  @override
  Future<AiUsageStatus> getStatus() async {
    final model = await _dataSource.get();
    if (model == null) {
      return const AiUsageStatus(
        summariesUsedToday: 0,
        dailyLimit: AppConstants.aiUsageDailySummaryLimit,
      );
    }

    final now = DateTime.now();
    final isToday = model.day.year == now.year &&
        model.day.month == now.month &&
        model.day.day == now.day;

    return AiUsageStatus(
      summariesUsedToday: isToday ? model.summariesUsed : 0,
      dailyLimit: AppConstants.aiUsageDailySummaryLimit,
    );
  }

  @override
  Future<void> recordLocalUsage() => _dataSource.recordLocalUsage();
}
