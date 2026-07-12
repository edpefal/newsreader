import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/domain/repositories/summary_repository.dart';

class GetDailySummaries {
  final SummaryRepository _repository;

  const GetDailySummaries(this._repository);

  Future<List<DailySummary>> execute() => _repository.getAll();
}
