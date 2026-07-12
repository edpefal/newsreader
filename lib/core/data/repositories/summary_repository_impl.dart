import 'package:newsreader/core/data/datasources/local/summary_local_datasource.dart';
import 'package:newsreader/core/data/models/daily_summary_model.dart';
import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/domain/repositories/summary_repository.dart';

class SummaryRepositoryImpl implements SummaryRepository {
  final SummaryLocalDataSource _dataSource;

  const SummaryRepositoryImpl(this._dataSource);

  @override
  Future<List<DailySummary>> getAll() async {
    final models = await _dataSource.getAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> save(DailySummary summary) =>
      _dataSource.save(DailySummaryModel.fromEntity(summary));

  @override
  Future<DailySummary?> getByDate(DateTime date) async {
    final model = await _dataSource.getByDate(date);
    return model?.toEntity();
  }
}
