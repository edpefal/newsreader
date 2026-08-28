import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/ai/article_summary_generator.dart';
import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/entities/article_summary.dart';
import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/observability/observability_client.dart';
import 'package:newsreader/features/article_summary/domain/usecases/generate_article_summary.dart';

part 'article_summary_state.dart';

/// Cubit del bottom sheet de resumen+menciones de un artículo. Un cubit por
/// apertura del bottom sheet (no singleton, a diferencia de `SummariesCubit`):
/// se crea con el `Article` puntual que se está mostrando.
///
/// El chequeo de suscripción/paywall NO vive acá: ocurre antes, en el
/// botón que abre el bottom sheet (mismo lugar donde `SummariesView`
/// resuelve el paywall antes de llamar al cubit) -- para cuando este cubit
/// se invoca, la suscripción activa ya está garantizada.
class ArticleSummaryCubit extends Cubit<ArticleSummaryState> {
  final GenerateArticleSummary _generateArticleSummary;
  final ObservabilityClient _observabilityClient;

  ArticleSummaryCubit(
    this._generateArticleSummary,
    this._observabilityClient,
  ) : super(const ArticleSummaryLoading());

  Future<void> generate(Article article, String language) async {
    emit(const ArticleSummaryLoading());
    try {
      final summary = await _generateArticleSummary.execute(
        article,
        language: language,
      );
      emit(ArticleSummaryLoaded(summary));
    } catch (e, st) {
      final code = e is ArticleSummaryGenerationException
          ? e.code
          : AppErrorCode.generationFailed;
      // aiUsageLimitReached es un estado esperado y alcanzable por diseño,
      // no un bug -- no se reporta a Sentry, igual que en SummariesCubit.
      if (code != AppErrorCode.aiUsageLimitReached) {
        _observabilityClient.captureException(e, st);
      }
      emit(ArticleSummaryError(code));
    }
  }
}
