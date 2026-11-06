import 'package:newsreader/core/observability/telemetry_client.dart';
import 'package:newsreader/core/subscription/subscription_status_provider.dart';
import 'package:newsreader/features/sync/domain/usecases/sync_entitlement.dart';

/// Restaura las compras del Apple ID y, si hay una suscripción vigente,
/// sincroniza `entitlements` en el backend. Lo usan Ajustes y el paywall, para
/// que ambos registren `restore_completed` y sincronicen igual.
class RestorePurchases {
  final SubscriptionStatusProvider _subscriptionStatusProvider;
  final SyncEntitlement _syncEntitlement;
  final TelemetryClient _telemetryClient;

  const RestorePurchases(
    this._subscriptionStatusProvider,
    this._syncEntitlement,
    this._telemetryClient,
  );

  /// Devuelve si se encontró una suscripción vigente. Lanza
  /// `SubscriptionException` si la restauración falla.
  Future<bool> execute() async {
    final found = await _subscriptionStatusProvider.restore();
    _telemetryClient.trackEvent(
      'restore_completed',
      properties: {'found': found},
    );
    if (found) await _syncEntitlement.execute();
    return found;
  }
}
