import 'package:newsreader/core/data/models/daily_summary_model.dart';

abstract class SummaryLocalDataSource {
  Future<List<DailySummaryModel>> getAll();
  Future<void> save(DailySummaryModel model);
  Future<DailySummaryModel?> getByDate(DateTime date);
}
