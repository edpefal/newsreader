import 'dart:convert';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/network/http_client.dart';
import 'package:newsreader/features/sync/domain/usecases/clear_local_user_data.dart';

const _deleteAccountFunctionUrl =
    'https://avyaxzhdilhufyimrzzb.supabase.co/functions/v1/delete-account';

/// Elimina irreversiblemente la cuenta del usuario y todos sus datos
/// asociados. El borrado remoto (Edge Function `delete-account`) SHALL
/// completarse con éxito antes de tocar cualquier dato local o la sesión —
/// si falla, no se limpia nada localmente, dejando la cuenta intacta para
/// reintentar (ver capability `account-deletion`).
class DeleteAccount {
  final HttpClient _httpClient;
  final AuthClient _authClient;
  final ClearLocalUserData _clearLocalUserData;

  const DeleteAccount(
    this._httpClient,
    this._authClient,
    this._clearLocalUserData,
  );

  Future<void> execute() async {
    final accessToken = _authClient.currentAccessToken;
    if (accessToken == null) {
      throw const AccountDeletionException('No hay sesión activa.');
    }

    final responseBody = await _httpClient.post(
      _deleteAccountFunctionUrl,
      headers: {'Authorization': 'Bearer $accessToken'},
      body: '{}',
    );

    final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    if (decoded['success'] != true) {
      throw AccountDeletionException(
        decoded['error'] as String? ??
            'No pudimos eliminar tu cuenta. Intentá de nuevo.',
      );
    }

    await _clearLocalUserData.execute();
    await _authClient.signOut();
  }
}
