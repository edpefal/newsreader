import 'dart:convert';

import 'package:newsreader/core/ai/mention_enricher.dart';
import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/config/app_config.dart';
import 'package:newsreader/core/constants/app_constants.dart';
import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/network/http_client.dart';
import 'package:newsreader/core/observability/observability_client.dart';

/// Enriquece menciones vía la Edge Function `enrich-mentions`, que proxea a
/// Google Books/iTunes Search del lado del servidor (ver design.md). A
/// diferencia de `GeminiSummaryGenerator`, esta llamada no consume
/// presupuesto de IA -- no invoca a Gemini.
String get _enrichMentionsFunctionUrl =>
    '${AppConfig.supabaseUrl}/functions/v1/enrich-mentions';

class RemoteMentionEnricher implements MentionEnricher {
  final HttpClient _httpClient;
  final AuthClient _authClient;
  final ObservabilityClient _observabilityClient;

  const RemoteMentionEnricher(
    this._httpClient,
    this._authClient,
    this._observabilityClient,
  );

  @override
  Future<List<EnrichedMention>> enrich(List<RawMention> mentions) async {
    if (mentions.isEmpty) return [];

    final accessToken = _authClient.currentAccessToken;
    if (accessToken == null) {
      throw const MentionEnrichmentException(AppErrorCode.noActiveSession);
    }

    try {
      final responseBody = await _httpClient.post(
        _enrichMentionsFunctionUrl,
        timeout: AppConstants.summaryGenerationTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'mentions': mentions
              .map((m) => {'type': m.type.wireValue, 'name': m.name})
              .toList(),
        }),
      );

      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final rawMentions = decoded['mentions'];
      if (rawMentions is! List) {
        throw const MentionEnrichmentException(AppErrorCode.generationFailed);
      }
      return rawMentions
          .cast<Map<String, dynamic>>()
          .map((m) => (
                type: MentionTypeWireFormat.fromWireValue(m['type'] as String),
                name: m['name'] as String,
                imageUrl: m['imageUrl'] as String?,
                link: m['link'] as String?,
              ))
          .toList();
    } on MentionEnrichmentException {
      rethrow;
    } catch (e, st) {
      _observabilityClient.captureException(e, st);
      throw const MentionEnrichmentException(AppErrorCode.unknown);
    }
  }
}
