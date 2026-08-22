import 'dart:convert';

import 'package:newsreader/core/ai/summary_generator.dart';
import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/config/app_config.dart';
import 'package:newsreader/core/constants/app_constants.dart';
import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/network/http_client.dart';
import 'package:newsreader/core/observability/observability_client.dart';

/// Genera resúmenes vía una Supabase Edge Function que hace de proxy a la
/// API de Gemini. La key real de Gemini vive como secret del lado del
/// backend; esta app se autentica con el access token de la sesión activa
/// del usuario (no con el anon key público), y el backend exige que sea una
/// sesión real (ver require-authenticated-session-for-summary-and-email-feed).
String get _summarizeFunctionUrl =>
    '${AppConfig.supabaseUrl}/functions/v1/summarize-articles';

class GeminiSummaryGenerator implements SummaryGenerator {
  final HttpClient _httpClient;
  final AuthClient _authClient;
  final ObservabilityClient _observabilityClient;

  const GeminiSummaryGenerator(
    this._httpClient,
    this._authClient,
    this._observabilityClient,
  );

  @override
  Future<String> summarize(
    List<ArticleExcerpt> articles, {
    required String language,
  }) async {
    if (articles.isEmpty) {
      throw const SummaryGenerationException(AppErrorCode.noArticlesToday);
    }

    final accessToken = _authClient.currentAccessToken;
    if (accessToken == null) {
      throw const SummaryGenerationException(AppErrorCode.noActiveSession);
    }

    try {
      final responseBody = await _httpClient.post(
        _summarizeFunctionUrl,
        // El default de HttpClient (feedFetchTimeout, 10s) está pensado para
        // fetch de feeds RSS; resumir varios artículos con contenido completo
        // vía Gemini puede tardar más.
        timeout: AppConstants.summaryGenerationTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'articles': articles
              .map((a) => {
                    'title': a.title,
                    'excerpt': a.excerpt,
                    'sourceName': a.sourceName,
                  })
              .toList(),
          'language': language,
        }),
      );

      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final summary = decoded['summary'];
      if (summary is! String || summary.trim().isEmpty) {
        if (decoded['error'] == 'ai_usage_limit_reached') {
          throw const SummaryGenerationException(
            AppErrorCode.aiUsageLimitReached,
          );
        }
        throw const SummaryGenerationException(AppErrorCode.generationFailed);
      }
      return summary.trim();
    } on SummaryGenerationException {
      rethrow;
    } catch (e, st) {
      _observabilityClient.captureException(e, st);
      throw const SummaryGenerationException(AppErrorCode.unknown);
    }
  }
}
