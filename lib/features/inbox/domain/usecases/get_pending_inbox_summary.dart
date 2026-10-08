import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/domain/repositories/summary_repository.dart';
import 'package:newsreader/core/utils/is_local_today.dart';

/// Resumen diario de hoy (fecha local) que aún no se abrió ni se descartó, o
/// `null`. No usa `getByDate`: la caja se indexa por `dateKey` en UTC, que
/// para husos al este de UTC cae en el día anterior.
class GetPendingInboxSummary {
  final SummaryRepository _repository;

  const GetPendingInboxSummary(this._repository);

  Future<DailySummary?> execute() async =>
      fromSummaries(await _repository.getAll());

  /// Emite el resumen pendiente cada vez que cambia el almacenamiento local.
  Stream<DailySummary?> watch() =>
      _repository.watchAll().map((summaries) => fromSummaries(summaries));

  /// Misma regla sobre una lista ya cargada (la usa el `Stream` del cubit).
  DailySummary? fromSummaries(List<DailySummary> summaries, {DateTime? now}) {
    for (final summary in summaries) {
      if (summary.dismissedAt == null && isLocalToday(summary.date, now: now)) {
        return summary;
      }
    }
    return null;
  }
}
