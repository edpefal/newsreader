import 'dart:convert';

import 'package:newsreader/core/ai/article_summary_generator.dart';
import 'package:newsreader/core/ai/mention_enricher.dart';
import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/config/app_config.dart';
import 'package:newsreader/core/constants/app_constants.dart';
import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/network/http_client.dart';
import 'package:newsreader/core/observability/observability_client.dart';

/// Genera el resumen de un artículo individual + sus menciones crudas vía
/// la Edge Function `summarize-article` (mismo patrón de auth/cuota que
/// `GeminiSummaryGenerator`, prompt y formato de respuesta distintos -- ver
/// design.md de add-article-summary-mentions).
String get _summarizeArticleFunctionUrl =>
    '${AppConfig.supabaseUrl}/functions/v1/summarize-article';

class GeminiArticleSummaryGenerator implements ArticleSummaryGenerator {
  final HttpClient _httpClient;
  final AuthClient _authClient;
  final ObservabilityClient _observabilityClient;

  const GeminiArticleSummaryGenerator(
    this._httpClient,
    this._authClient,
    this._observabilityClient,
  );

  @override
  Future<ArticleSummaryResult> summarizeArticle(
    String title,
    String content, {
    required String language,
  }) async {
    final accessToken = _authClient.currentAccessToken;
    if (accessToken == null) {
      throw const ArticleSummaryGenerationException(
        AppErrorCode.noActiveSession,
      );
    }

    try {
      final responseBody = await _httpClient.post(
        _summarizeArticleFunctionUrl,
        timeout: AppConstants.summaryGenerationTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'title': title,
          'content': content,
          'language': language,
        }),
      );

      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final summary = decoded['summary'];
      final rawMentions = decoded['mentions'];
      if (summary is! String ||
          summary.trim().isEmpty ||
          rawMentions is! List) {
        if (decoded['error'] == 'ai_usage_limit_reached') {
          throw const ArticleSummaryGenerationException(
            AppErrorCode.aiUsageLimitReached,
          );
        }
        throw const ArticleSummaryGenerationException(
          AppErrorCode.generationFailed,
        );
      }

      final mentions = rawMentions.cast<Map<String, dynamic>>().map((m) => (
            type: MentionTypeWireFormat.fromWireValue(m['type'] as String),
            name: m['name'] as String,
          ));

      return (summary: summary.trim(), mentions: mentions.toList());
    } on ArticleSummaryGenerationException {
      rethrow;
    } catch (e, st) {
      _observabilityClient.captureException(e, st);
      throw const ArticleSummaryGenerationException(AppErrorCode.unknown);
    }
  }
}
