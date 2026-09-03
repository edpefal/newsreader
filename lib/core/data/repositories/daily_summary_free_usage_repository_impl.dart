import 'package:newsreader/core/data/datasources/local/daily_summary_free_usage_local_datasource.dart';
import 'package:newsreader/core/data/datasources/local/hive_daily_summary_free_usage_datasource.dart';
import 'package:newsreader/core/domain/entities/daily_summary_free_usage_status.dart';
import 'package:newsreader/core/domain/repositories/daily_summary_free_usage_repository.dart';

class DailySummaryFreeUsageRepositoryImpl
    implements DailySummaryFreeUsageRepository {
  final DailySummaryFreeUsageLocalDataSource _dataSource;

  const DailySummaryFreeUsageRepositoryImpl(this._dataSource);

  @override
  Future<DailySummaryFreeUsageStatus> getStatus() async {
    final model = await _dataSource.get();
    final currentWeekStart =
        HiveDailySummaryFreeUsageDatasource.weekStartOf(DateTime.now());
    if (model == null) {
      return DailySummaryFreeUsageStatus(
        usedThisWeek: false,
        weekStart: currentWeekStart,
      );
    }

    final isCurrentWeek = model.weekStart.year == currentWeekStart.year &&
        model.weekStart.month == currentWeekStart.month &&
        model.weekStart.day == currentWeekStart.day;

    return DailySummaryFreeUsageStatus(
      usedThisWeek: isCurrentWeek ? model.used : false,
      weekStart: currentWeekStart,
    );
  }

  @override
  Future<void> recordLocalUsage() => _dataSource.recordLocalUsage();
}
