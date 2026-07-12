import 'package:hive_ce/hive.dart';

import 'package:newsreader/core/data/datasources/local/summary_local_datasource.dart';
import 'package:newsreader/core/data/models/daily_summary_model.dart';
import 'package:newsreader/core/utils/date_key.dart';

class HiveSummaryDatasource implements SummaryLocalDataSource {
  final Box<DailySummaryModel> _box;

  const HiveSummaryDatasource(this._box);

  @override
  Future<List<DailySummaryModel>> getAll() async {
    final summaries = _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return summaries;
  }

  @override
  Future<void> save(DailySummaryModel model) async =>
      _box.put(dateKey(model.date), model);

  @override
  Future<DailySummaryModel?> getByDate(DateTime date) async =>
      _box.get(dateKey(date));
}
