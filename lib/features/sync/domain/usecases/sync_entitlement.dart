import 'package:newsreader/core/sync/cloud_sync_client.dart';

/// Refleja en el backend el estado de la suscripción justo después de una
/// compra o restauración, antes de la acción que dependía de ella (por ejemplo,
/// generar el resumen de un artículo): así `summarize-article` no responde 403
/// por la carrera con el webhook del proveedor.
///
/// Mejor esfuerzo: si falla (sin red), no se propaga. El estado local viene del
/// SDK, así que el usuario ya figura como suscriptor, y el webhook repara
/// `entitlements` cuando llegue el aviso.
class SyncEntitlement {
  final CloudSyncClient _cloudSyncClient;

  const SyncEntitlement(this._cloudSyncClient);

  /// Devuelve si el backend quedó sincronizado.
  Future<bool> execute() async {
    try {
      await _cloudSyncClient.syncEntitlement();
      return true;
    } catch (_) {
      return false;
    }
  }
}
