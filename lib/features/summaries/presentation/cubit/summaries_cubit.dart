import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/ai/summary_generator.dart';
import 'package:newsreader/core/ai_usage/ai_usage_policy.dart';
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
  final AiUsagePolicy _aiUsagePolicy;

  SummariesCubit(
    this._getDailySummaries,
    this._generateDailySummary,
    this._subscriptionStatusProvider,
    this._observabilityClient,
    this._aiUsagePolicy,
  ) : super(const SummariesLoading());

  Future<void> loadSummaries() async {
    emit(const SummariesLoading());
    final summaries = await _getDailySummaries.execute();
    final canGenerateToday = await _generateDailySummary.countTodayArticles() > 0;
    final usage = await _aiUsagePolicy.getStatus();
    emit(SummariesLoaded(
      summaries: summaries,
      canGenerateToday: canGenerateToday,
      usage: usage,
    ));
  }

  /// `true` cuando ya existe un resumen de hoy y regenerar no traería
  /// artículos nuevos -- la pantalla usa esto para decidir si pedir
  /// confirmación antes de invocar `generateTodaySummary`.
  Future<bool> wouldRegenerateWithSameArticles() =>
      _generateDailySummary.wouldRegenerateWithSameArticles();

  /// Antes de disparar la generación, chequea el estado local de
  /// suscripción: si no hay suscripción activa, muestra el paywall de
  /// Superwall en vez de generar. Si el usuario completa la compra desde
  /// el paywall, la generación se dispara automáticamente a continuación.
  Future<void> generateTodaySummary(String language) async {
    if (!_subscriptionStatusProvider.isSubscribed) {
      await _subscriptionStatusProvider.showPaywall(
        onSubscribed: () => _generate(language),
      );
      return;
    }
    await _generate(language);
  }

  Future<void> _generate(String language) async {
    final current = state;
    final (summaries, usage) = switch (current) {
      SummariesLoaded(:final summaries, :final usage) => (summaries, usage),
      SummaryGenerating(:final summaries, :final usage) => (summaries, usage),
      SummaryGenerationError(:final summaries, :final usage) => (
          summaries,
          usage,
        ),
      SummariesLoading() => (const <DailySummary>[], await _aiUsagePolicy.getStatus()),
    };

    emit(SummaryGenerating(summaries, usage));
    try {
      final generated = await _generateDailySummary.execute(language: language);
      final updated = [
        generated,
        ...summaries.where((s) => s.id != generated.id),
      ]..sort((a, b) => b.date.compareTo(a.date));
      // La generación exitosa consumió palabras del presupuesto del lado
      // del servidor -- se vuelve a pedir el estado para que el medidor
      // refleje el nuevo consumo, en vez de mostrar el valor stale de antes
      // de generar.
      final refreshedUsage = await _aiUsagePolicy.getStatus();
      emit(SummariesLoaded(
        summaries: updated,
        canGenerateToday: true,
        usage: refreshedUsage,
      ));
    } on NoArticlesTodayException {
      emit(SummaryGenerationError(
        summaries: summaries,
        canGenerateToday: false,
        code: AppErrorCode.noArticlesToday,
        usage: usage,
      ));
    } catch (e, st) {
      final code = e is SummaryGenerationException
          ? e.code
          : AppErrorCode.generationFailed;
      // aiUsageLimitReached es un estado esperado y alcanzable por diseño
      // (el usuario llegó a su presupuesto diario de IA), no un bug -- no
      // se reporta a Sentry, igual que NoArticlesTodayException más arriba.
      if (code != AppErrorCode.aiUsageLimitReached) {
        _observabilityClient.captureException(e, st);
      }
      final canGenerateToday = await _generateDailySummary.countTodayArticles() > 0;
      // El chequeo de presupuesto ocurre antes de invocar a Gemini: si la
      // falla pasó después de ese chequeo (ej. Gemini caído), las palabras
      // ya se descontaron server-side, así que igual conviene refrescar.
      final refreshedUsage = await _aiUsagePolicy.getStatus();
      emit(SummaryGenerationError(
        summaries: summaries,
        canGenerateToday: canGenerateToday,
        code: code,
        usage: refreshedUsage,
      ));
    }
  }
}
