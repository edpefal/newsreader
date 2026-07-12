import 'dart:convert';

import 'package:newsreader/core/ai/summary_generator.dart';
import 'package:newsreader/core/network/http_client.dart';

/// Genera resúmenes vía una Supabase Edge Function que hace de proxy a la
/// API de Gemini. La key real de Gemini vive como secret del lado del
/// backend; esta app solo se autentica con el anon key público de Supabase,
/// que está pensado para embeberse en clientes distribuidos.
const _summarizeFunctionUrl =
    'https://avyaxzhdilhufyimrzzb.supabase.co/functions/v1/summarize-articles';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF2eWF4emhkaWxodWZ5aW1yenpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM3OTE1MTMsImV4cCI6MjA5OTM2NzUxM30.LfgL2Arsth-br6qoAUzbAYhMFtiVCXnrnpoWU59Xzh0';

class GeminiSummaryGenerator implements SummaryGenerator {
  final HttpClient _httpClient;

  const GeminiSummaryGenerator(this._httpClient);

  @override
  Future<String> summarize(List<ArticleExcerpt> articles) async {
    if (articles.isEmpty) {
      throw const SummaryGenerationException('No hay artículos para resumir.');
    }

    try {
      final responseBody = await _httpClient.post(
        _summarizeFunctionUrl,
        headers: const {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_supabaseAnonKey',
        },
        body: jsonEncode({
          'articles': articles
              .map((a) => {
                    'title': a.title,
                    'excerpt': a.excerpt,
                    'sourceName': a.sourceName,
                  })
              .toList(),
        }),
      );

      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final summary = decoded['summary'];
      if (summary is! String || summary.trim().isEmpty) {
        throw SummaryGenerationException(
          decoded['error'] as String? ?? 'Respuesta inválida del backend.',
        );
      }
      return summary.trim();
    } on SummaryGenerationException {
      rethrow;
    } catch (e) {
      throw SummaryGenerationException(e.toString());
    }
  }
}
