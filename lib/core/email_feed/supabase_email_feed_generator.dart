import 'dart:convert';

import 'package:newsreader/core/email_feed/email_feed_generator.dart';
import 'package:newsreader/core/network/http_client.dart';

/// Llama a la Supabase Edge Function que genera una dirección de email y su
/// feed RSS correspondiente. Mismo patrón que GeminiSummaryGenerator: la app
/// solo se autentica con el anon key público de Supabase.
const _createFeedFunctionUrl =
    'https://avyaxzhdilhufyimrzzb.supabase.co/functions/v1/create-feed';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF2eWF4emhkaWxodWZ5aW1yenpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM3OTE1MTMsImV4cCI6MjA5OTM2NzUxM30.LfgL2Arsth-br6qoAUzbAYhMFtiVCXnrnpoWU59Xzh0';

class SupabaseEmailFeedGenerator implements EmailFeedGenerator {
  final HttpClient _httpClient;

  const SupabaseEmailFeedGenerator(this._httpClient);

  @override
  Future<GeneratedEmailFeed> generate({String? label}) async {
    try {
      final responseBody = await _httpClient.post(
        _createFeedFunctionUrl,
        headers: const {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_supabaseAnonKey',
        },
        body: jsonEncode({if (label != null) 'label': label}),
      );

      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final email = decoded['email'];
      final feedUrl = decoded['feedUrl'];
      if (email is! String || email.isEmpty || feedUrl is! String || feedUrl.isEmpty) {
        throw EmailFeedGenerationException(
          decoded['error'] as String? ?? 'Respuesta inválida del backend.',
        );
      }
      return (email: email, feedUrl: feedUrl);
    } on EmailFeedGenerationException {
      rethrow;
    } catch (e) {
      throw EmailFeedGenerationException(e.toString());
    }
  }
}
