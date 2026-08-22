import 'package:newsreader/core/ai_usage/ai_usage_policy.dart';
import 'package:newsreader/core/constants/app_constants.dart';
import 'package:newsreader/core/sync/cloud_sync_client.dart';

/// Lee `ai_usage_daily` reusando `CloudSyncClient` (mismo mecanismo genérico
/// ya usado para `sources`/`articles`/`daily_summaries`, bajo la misma RLS
/// `select_own`) en vez de un edge function nuevo. No se cachea en Hive: se
/// pide fresco cada vez, porque el valor cambia del lado del servidor sin
/// que el cliente lo sepa.
class SupabaseAiUsagePolicy implements AiUsagePolicy {
  final CloudSyncClient _cloudSyncClient;

  const SupabaseAiUsagePolicy(this._cloudSyncClient);

  @override
  Future<AiUsageStatus> getStatus() async {
    final rows = await _cloudSyncClient.fetchChangedSince(
      'ai_usage_daily',
      null,
    );

    const wordLimit = AppConstants.aiUsageDailyWordLimit;
    if (rows.isEmpty) {
      return AiUsageStatus(
        wordsUsed: 0,
        wordLimit: wordLimit,
        resetsAt: _nextResetAfter(DateTime.now().toUtc()),
      );
    }

    final row = rows.single;
    final day = DateTime.parse(row['day'] as String);
    return AiUsageStatus(
      wordsUsed: row['words_used'] as int,
      wordLimit: wordLimit,
      resetsAt: _nextResetAfter(day),
    );
  }

  /// El presupuesto resetea a medianoche UTC del día siguiente al `day`
  /// registrado (día del servidor, no el local del usuario -- ver design.md).
  static DateTime _nextResetAfter(DateTime day) =>
      DateTime.utc(day.year, day.month, day.day + 1);
}
