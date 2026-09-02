import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/ai/summary_generator.dart';
import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/observability/telemetry_client.dart';
import 'package:newsreader/core/subscription/subscription_status_provider.dart';
import 'package:newsreader/features/summaries/domain/usecases/generate_daily_summary.dart';
import 'package:newsreader/features/summaries/domain/usecases/get_daily_summaries.dart';

part 'summaries_state.dart';

class SummariesCubit extends Cubit<SummariesState> {
  final GetDailySummaries _getDailySummaries;
  final GenerateDailySummary _generateDailySummary;
  final SubscriptionStatusProvider _subscriptionStatusProvider;
  final TelemetryClient _observabilityClient;

  SummariesCubit(
    this._getDailySummaries,
    this._generateDailySummary,
    this._subscriptionStatusProvider,
    this._observabilityClient,
  ) : super(const SummariesLoading());

  Future<void> loadSummaries() async {
    emit(const SummariesLoading());
    final summaries = await _getDailySummaries.execute();
    final hasArticlesToday = await _generateDailySummary.countTodayArticles() > 0;
    final alreadyGeneratedToday = await _generateDailySummary.hasGeneratedToday();
    emit(SummariesLoaded(
      summaries: summaries,
      canGenerateToday: hasArticlesToday && !alreadyGeneratedToday,
      alreadyGeneratedToday: alreadyGeneratedToday,
    ));
  }

  /// Antes de disparar la generación, chequea el estado local de
  /// suscripción: si no hay suscripción activa, muestra el paywall de
  /// Superwall en vez de generar. `onSubscribed` vuelve a chequear
  /// `isSubscribed` antes de generar -- Superwall solo debería invocarlo
  /// tras una compra completada, pero una config remota incorrecta del
  /// paywall (`feature_gating: non_gated`) puede dispararlo igual al cerrar
  /// el paywall sin comprar, así que no alcanza con confiar en que el
  /// callback se haya ejecutado.
  Future<void> generateTodaySummary(String language) async {
    if (!_subscriptionStatusProvider.isSubscribed) {
      await _subscriptionStatusProvider.showPaywall(
        onSubscribed: () async {
          if (!_subscriptionStatusProvider.isSubscribed) return;
          await _generate(language);
        },
      );
      return;
    }
    await _generate(language);
  }

  Future<void> _generate(String language) async {
    final current = state;
    final summaries = switch (current) {
      SummariesLoaded(:final summaries) => summaries,
      SummaryGenerating(:final summaries) => summaries,
      SummaryGenerationError(:final summaries) => summaries,
      SummariesLoading() => const <DailySummary>[],
    };

    emit(SummaryGenerating(summaries));
    try {
      final generated = await _generateDailySummary.execute(language: language);
      final updated = [
        generated,
        ...summaries.where((s) => s.id != generated.id),
      ]..sort((a, b) => b.date.compareTo(a.date));
      emit(SummariesLoaded(
        summaries: updated,
        canGenerateToday: false,
        alreadyGeneratedToday: true,
      ));
    } on NoArticlesTodayException {
      emit(SummaryGenerationError(
        summaries: summaries,
        canGenerateToday: false,
        code: AppErrorCode.noArticlesToday,
      ));
    } on DailySummaryAlreadyGeneratedException {
      // Estado esperado y alcanzable por diseño (una segunda solicitud
      // concurrente ganó la carrera del lado del backend, o el chequeo local
      // quedó stale), no un bug -- no se reporta a observability, igual que
      // NoArticlesTodayException más arriba.
      emit(SummaryGenerationError(
        summaries: summaries,
        canGenerateToday: false,
        code: AppErrorCode.dailySummaryAlreadyGenerated,
      ));
    } catch (e, st) {
      final code = e is SummaryGenerationException
          ? e.code
          : AppErrorCode.generationFailed;
      // dailySummaryAlreadyGenerated es un estado esperado y alcanzable por
      // diseño (el backend rechazó una segunda generación del día), no un
      // bug -- no se reporta a Sentry, igual que NoArticlesTodayException
      // más arriba.
      if (code != AppErrorCode.dailySummaryAlreadyGenerated) {
        _observabilityClient.captureException(e, st);
      }
      final hasArticlesToday = await _generateDailySummary.countTodayArticles() > 0;
      final alreadyGeneratedToday = code == AppErrorCode.dailySummaryAlreadyGenerated ||
          await _generateDailySummary.hasGeneratedToday();
      emit(SummaryGenerationError(
        summaries: summaries,
        canGenerateToday: hasArticlesToday && !alreadyGeneratedToday,
        code: code,
      ));
    }
  }
}
