import 'package:hive_ce/hive.dart';

import 'package:newsreader/core/data/datasources/local/daily_summary_free_usage_local_datasource.dart';
import 'package:newsreader/core/data/models/daily_summary_free_usage_model.dart';

class HiveDailySummaryFreeUsageDatasource
    implements DailySummaryFreeUsageLocalDataSource {
  // Una sola fila (la del usuario activo), igual que
  // `HiveAiUsageDatasource` -- no hace falta más de una key en la box.
  static const _key = 'current';

  final Box<DailySummaryFreeUsageModel> _box;

  const HiveDailySummaryFreeUsageDatasource(this._box);

  /// Lunes de la semana calendario que contiene [date], a medianoche --
  /// mismo criterio que `date_trunc('week', current_date)` en Postgres
  /// (semana ISO, empieza en lunes).
  static DateTime weekStartOf(DateTime date) {
    final midnight = DateTime(date.year, date.month, date.day);
    return midnight.subtract(Duration(days: midnight.weekday - 1));
  }

  @override
  Future<DailySummaryFreeUsageModel?> get() async => _box.get(_key);

  @override
  Future<void> applyRemote(DailySummaryFreeUsageModel model) async =>
      _box.put(_key, model);

  @override
  Future<void> recordLocalUsage() async {
    final currentWeekStart = weekStartOf(DateTime.now());
    await _box.put(
      _key,
      DailySummaryFreeUsageModel(weekStart: currentWeekStart, used: true),
    );
  }
}
