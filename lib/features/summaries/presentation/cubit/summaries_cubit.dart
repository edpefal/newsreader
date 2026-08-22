import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/observability/observability_client.dart';
import 'package:newsreader/core/subscription/subscription_status_provider.dart';
import 'package:newsreader/features/summaries/domain/usecases/generate_daily_summary.dart';
import 'package:newsreader/features/summaries/domain/usecases/get_daily_summaries.dart';

part 'summaries_state.dart';

class SummariesCubit extends Cubit<SummariesState> {
  final GetDailySummaries _getDailySummaries;
  final GenerateDailySummary _generateDailySummary;
  final SubscriptionStatusProvider _subscriptionStatusProvider;
  final ObservabilityClient _observabilityClient;

  SummariesCubit(
    this._getDailySummaries,
    this._generateDailySummary,
    this._subscriptionStatusProvider,
    this._observabilityClient,
  ) : super(const SummariesLoading());

  Future<void> loadSummaries() async {
    emit(const SummariesLoading());
    final summaries = await _getDailySummaries.execute();
    final canGenerateToday = await _generateDailySummary.countTodayArticles() > 0;
    emit(SummariesLoaded(summaries: summaries, canGenerateToday: canGenerateToday));
  }

  /// Antes de disparar la generación, chequea el estado local de
  /// suscripción: si no hay suscripción activa, muestra el paywall de
  /// Superwall en vez de generar. Si el usuario completa la compra desde
  /// el paywall, la generación se dispara automáticamente a continuación.
  Future<void> generateTodaySummary() async {
    if (!_subscriptionStatusProvider.isSubscribed) {
      await _subscriptionStatusProvider.showPaywall(
        onSubscribed: _generate,
      );
      return;
    }
    await _generate();
  }

  Future<void> _generate() async {
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
        code: AppErrorCode.noArticlesToday,
      ));
    } catch (e, st) {
      _observabilityClient.captureException(e, st);
      final canGenerateToday = await _generateDailySummary.countTodayArticles() > 0;
      emit(SummaryGenerationError(
        summaries: summaries,
        canGenerateToday: canGenerateToday,
        code: AppErrorCode.generationFailed,
      ));
    }
  }
}
