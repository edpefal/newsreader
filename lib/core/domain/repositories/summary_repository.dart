import 'package:newsreader/core/domain/entities/daily_summary.dart';

abstract class SummaryRepository {
  Future<List<DailySummary>> getAll();
  Future<void> save(DailySummary summary);
  Future<DailySummary?> getByDate(DateTime date);
}
