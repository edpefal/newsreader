import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/features/summaries/domain/usecases/generate_daily_summary.dart';
import 'package:newsreader/features/summaries/domain/usecases/get_daily_summaries.dart';

part 'summaries_state.dart';

class SummariesCubit extends Cubit<SummariesState> {
  final GetDailySummaries _getDailySummaries;
  final GenerateDailySummary _generateDailySummary;

  SummariesCubit(this._getDailySummaries, this._generateDailySummary)
      : super(const SummariesLoading());

  Future<void> loadSummaries() async {
    emit(const SummariesLoading());
    final summaries = await _getDailySummaries.execute();
    final canGenerateToday = await _generateDailySummary.countTodayArticles() > 0;
    emit(SummariesLoaded(summaries: summaries, canGenerateToday: canGenerateToday));
  }

  Future<void> generateTodaySummary() async {
    final current = state;
    final summaries = switch (current) {
      SummariesLoaded(:final summaries) => summaries,
      SummaryGenerating(:final summaries) => summaries,
      SummaryGenerationError(:final summaries) => summaries,
      SummariesLoading() => const <DailySummary>[],
    };

    emit(SummaryGenerating(summaries));
    try {
      final generated = await _generateDailySummary.execute();
      final updated = [
        generated,
        ...summaries.where((s) => s.id != generated.id),
      ]..sort((a, b) => b.date.compareTo(a.date));
      emit(SummariesLoaded(summaries: updated, canGenerateToday: true));
    } on NoArticlesTodayException {
      emit(SummaryGenerationError(
        summaries: summaries,
        canGenerateToday: false,
        message: 'No hay artículos nuevos hoy para resumir.',
      ));
    } catch (e) {
      final canGenerateToday = await _generateDailySummary.countTodayArticles() > 0;
      emit(SummaryGenerationError(
        summaries: summaries,
        canGenerateToday: canGenerateToday,
        message: 'No se pudo generar el resumen. Intentá de nuevo.',
      ));
    }
  }
}
