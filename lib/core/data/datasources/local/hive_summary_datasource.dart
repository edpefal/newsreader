import 'package:hive_ce/hive.dart';

import 'package:newsreader/core/data/datasources/local/summary_local_datasource.dart';
import 'package:newsreader/core/data/models/daily_summary_model.dart';
import 'package:newsreader/core/utils/date_key.dart';

class HiveSummaryDatasource implements SummaryLocalDataSource {
  final Box<DailySummaryModel> _box;

  const HiveSummaryDatasource(this._box);

  @override
  Future<List<DailySummaryModel>> getAll() async => _sortedValues();

  List<DailySummaryModel> _sortedValues() =>
      _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));

  @override
  Future<void> save(DailySummaryModel model) async {
    model.updatedAt = DateTime.now();
    await _box.put(dateKey(model.date), model);
  }

  @override
  Future<DailySummaryModel?> getByDate(DateTime date) async =>
      _box.get(dateKey(date));

  @override
  Future<List<DailySummaryModel>> getChangedSince(DateTime? since) async =>
      _box.values
          .where((s) => since == null || (s.updatedAt?.isAfter(since) ?? true))
          .toList();

  @override
  Future<void> applyRemote(DailySummaryModel model) async {
    final existing = _box.get(dateKey(model.date));
    if (model.sourceBlocks == null && existing?.sourceBlocks != null) {
      model.sourceBlocks = existing!.sourceBlocks;
    }
    // Un remoto sin `dismissed_at` no pisa un descarte local aún no subido.
    if (model.dismissedAt == null && existing?.dismissedAt != null) {
      model.dismissedAt = existing!.dismissedAt;
    }
    await _box.put(dateKey(model.date), model);
  }

  @override
  Future<DailySummaryModel?> dismiss(String id) async {
    for (final model in _box.values) {
      if (model.id != id) continue;
      if (model.dismissedAt != null) return null;
      final now = DateTime.now();
      model.dismissedAt = now;
      model.updatedAt = now;
      await _box.put(dateKey(model.date), model);
      return model;
    }
    return null;
  }

  @override
  Stream<List<DailySummaryModel>> watchAll() =>
      _box.watch().map((_) => _sortedValues());

  @override
  Future<void> clearAll() async => _box.clear();
}
