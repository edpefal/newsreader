import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/domain/repositories/summary_repository.dart';

/// El resumen de fecha más reciente, o `null` si todavía no hay ninguno.
/// Los anteriores siguen guardados y sincronizados, pero la app ya no los
/// expone (ver capability `daily-summaries`).
class GetLatestDailySummary {
  final SummaryRepository _repository;

  const GetLatestDailySummary(this._repository);

  Future<DailySummary?> execute() async {
    final summaries = await _repository.getAll();
    if (summaries.isEmpty) return null;
    return summaries.reduce((a, b) => b.date.isAfter(a.date) ? b : a);
  }
}
