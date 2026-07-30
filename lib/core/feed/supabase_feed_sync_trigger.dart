import 'dart:convert';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/feed/feed_sync_trigger.dart';
import 'package:newsreader/core/network/http_client.dart';

const _syncFeedsFunctionUrl =
    'https://avyaxzhdilhufyimrzzb.supabase.co/functions/v1/sync-feeds';

/// `sync-feeds` procesa hasta 20 fuentes de forma secuencial del lado del
/// servidor (con hasta 10s de timeout cada una si un feed no responde), así
/// que puede tardar bastante más que el timeout HTTP default de 10s
/// (`AppConstants.feedFetchTimeout`, pensado para un fetch de un solo feed).
/// Sin este timeout explícito, el cliente corta la conexión antes de que la
/// función responda y lo reporta como error de red, aunque sí haya
/// conexión.
const _syncFeedsTimeout = Duration(seconds: 90);

/// Llama a la Edge Function `sync-feeds` autenticada con el JWT del usuario
/// actual (no el anon key): el servidor usa ese token para identificar de
/// quién son las fuentes a sincronizar en modo on-demand.
class SupabaseFeedSyncTrigger implements FeedSyncTrigger {
  final HttpClient _httpClient;
  final AuthClient _authClient;

  const SupabaseFeedSyncTrigger(this._httpClient, this._authClient);

  @override
  Future<FeedSyncResult> execute() async {
    final accessToken = _authClient.currentAccessToken;
    if (accessToken == null) {
      return const FeedSyncResult(synced: 0, failedSourceIds: []);
    }

    try {
      final responseBody = await _httpClient.post(
        _syncFeedsFunctionUrl,
        headers: {'Authorization': 'Bearer $accessToken'},
        body: '{}',
        timeout: _syncFeedsTimeout,
      );

      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final failedSourceIds = (decoded['failedSourceIds'] as List<dynamic>?)
              ?.cast<String>() ??
          const [];

      return FeedSyncResult(
        synced: decoded['synced'] as int? ?? 0,
        failedSourceIds: failedSourceIds,
      );
    } on NetworkException {
      return const FeedSyncResult(
        synced: 0,
        failedSourceIds: [],
        isNetworkError: true,
      );
    } on TimeoutException {
      return const FeedSyncResult(
        synced: 0,
        failedSourceIds: [],
        isNetworkError: true,
      );
    } catch (e) {
      throw FeedSyncException(e.toString());
    }
  }
}
