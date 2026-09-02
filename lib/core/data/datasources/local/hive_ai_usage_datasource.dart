import 'package:hive_ce/hive.dart';

import 'package:newsreader/core/data/datasources/local/ai_usage_local_datasource.dart';
import 'package:newsreader/core/data/models/ai_usage_daily_model.dart';

class HiveAiUsageDatasource implements AiUsageLocalDataSource {
  // Una sola fila (la del usuario activo), igual que `ai_usage_daily` en el
  // servidor -- no hace falta más de una key en la box.
  static const _key = 'current';

  final Box<AiUsageDailyModel> _box;

  const HiveAiUsageDatasource(this._box);

  @override
  Future<AiUsageDailyModel?> get() async => _box.get(_key);

  @override
  Future<void> applyRemote(AiUsageDailyModel model) async =>
      _box.put(_key, model);

  @override
  Future<void> recordLocalUsage() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = _box.get(_key);
    final isToday = current != null &&
        current.day.year == today.year &&
        current.day.month == today.month &&
        current.day.day == today.day;
    final summariesUsed = (isToday ? current.summariesUsed : 0) + 1;
    await _box.put(
      _key,
      AiUsageDailyModel(day: today, summariesUsed: summariesUsed),
    );
  }
}
