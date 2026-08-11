import 'dart:convert';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/config/app_config.dart';
import 'package:newsreader/core/email_feed/email_feed_generator.dart';
import 'package:newsreader/core/network/http_client.dart';

/// Llama a la Supabase Edge Function que genera una dirección de email y su
/// feed RSS correspondiente. Se autentica con el access token de la sesión
/// activa del usuario (no con el anon key público); el backend exige que sea
/// una sesión real (ver require-authenticated-session-for-summary-and-email-feed).
String get _createFeedFunctionUrl =>
    '${AppConfig.supabaseUrl}/functions/v1/create-feed';

class SupabaseEmailFeedGenerator implements EmailFeedGenerator {
  final HttpClient _httpClient;
  final AuthClient _authClient;

  const SupabaseEmailFeedGenerator(this._httpClient, this._authClient);

  @override
  Future<GeneratedEmailFeed> generate({String? label}) async {
    final accessToken = _authClient.currentAccessToken;
    if (accessToken == null) {
      throw const EmailFeedGenerationException('Se requiere sesión activa.');
    }

    try {
      final responseBody = await _httpClient.post(
        _createFeedFunctionUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
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
