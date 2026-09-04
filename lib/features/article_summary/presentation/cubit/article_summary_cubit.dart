import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/ai/article_summary_generator.dart';
import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/entities/article_summary.dart';
import 'package:newsreader/core/domain/repositories/ai_usage_repository.dart';
import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/observability/telemetry_client.dart';
import 'package:newsreader/features/article_summary/domain/usecases/generate_article_summary.dart';

part 'article_summary_state.dart';

/// Cubit del bottom sheet de resumen+menciones de un artículo. Un cubit por
/// apertura del bottom sheet (no singleton, a diferencia de `SummariesCubit`):
/// se crea con el `Article` puntual que se está mostrando.
///
/// El chequeo de suscripción/cupo gratis/paywall NO vive acá: ocurre antes,
/// en el botón que abre el bottom sheet (`ReaderScreen._onSummaryPressed`,
/// mismo lugar donde `SummariesCubit` resuelve el paywall antes de generar)
/// -- para cuando este cubit se invoca, el acceso (suscripción activa o
/// cupo diario gratis disponible) ya está garantizado.
class ArticleSummaryCubit extends Cubit<ArticleSummaryState> {
  final GenerateArticleSummary _generateArticleSummary;
  final AiUsageRepository _aiUsageRepository;
  final TelemetryClient _observabilityClient;

  ArticleSummaryCubit(
    this._generateArticleSummary,
    this._aiUsageRepository,
    this._observabilityClient,
  ) : super(const ArticleSummaryLoading());

  Future<void> generate(Article article, String language) async {
    emit(const ArticleSummaryLoading());
    _observabilityClient.trackEvent('summary_requested');
    try {
      final summary = await _generateArticleSummary.execute(
        article,
        language: language,
      );
      final remaining = await _remainingToday();
      emit(ArticleSummaryLoaded(summary, remainingToday: remaining));
    } catch (e, st) {
      final code = e is ArticleSummaryGenerationException
          ? e.code
          : AppErrorCode.generationFailed;
      // El límite diario alcanzado es un estado esperado y alcanzable por
      // diseño, no un bug -- estado propio (ver ArticleSummaryLimitReached),
      // sin reportarse a Sentry, igual que antes.
      if (code == AppErrorCode.aiUsageLimitReached) {
        final status = await _aiUsageRepository.getStatus();
        emit(ArticleSummaryLimitReached(dailyLimit: status.dailyLimit));
        return;
      }
      _observabilityClient.captureException(e, st);
      final remaining = await _remainingToday();
      emit(ArticleSummaryError(code, remainingToday: remaining));
    }
  }

  Future<int> _remainingToday() async =>
      (await _aiUsageRepository.getStatus()).remaining;
}
