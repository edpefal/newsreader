import 'package:newsreader/core/subscription/subscription_plan.dart';

/// Abstracción sobre el proveedor de suscripciones (RevenueCat). Sigue la
/// regla de abstracciones del proyecto: ningún SDK de terceros se importa
/// directo en `domain/`/`presentation/` — mismo patrón que `AuthClient`.
abstract class SubscriptionStatusProvider {
  /// Estado local (cacheado por el SDK) de si el usuario tiene una
  /// suscripción activa. Prioriza velocidad/funcionar offline sobre ser la
  /// fuente de verdad — eso lo es la tabla `entitlements` del backend, que
  /// `summarize-article` y `generate-daily-summaries` consultan de forma
  /// independiente.
  bool get isSubscribed;

  /// Emite cada vez que cambia [isSubscribed] (compra, restauración,
  /// expiración, login/logout), para que la UI se reconstruya.
  Stream<bool> get isSubscribedChanges;

  /// Identifica al usuario ante el proveedor de suscripciones con el mismo
  /// `user_id` de Supabase Auth, inmediatamente después de un login exitoso.
  Future<void> identify(String userId);

  /// Desvincula al usuario identificado (logout o borrado de cuenta). Sin
  /// esto, si otra cuenta inicia sesión en el mismo dispositivo, el
  /// proveedor podría arrastrar por un instante el estado de suscripción de
  /// la cuenta anterior hasta el próximo `identify()`.
  Future<void> reset();

  /// Planes (mensual y anual) con los precios de la tienda. Lanza
  /// `SubscriptionException` si no se pueden obtener.
  Future<List<SubscriptionPlan>> getPlans();

  /// Compra [plan]. Devuelve [PurchaseOutcome.cancelled] si el usuario cancela
  /// el pago; lanza `SubscriptionException` si la compra falla.
  Future<PurchaseOutcome> purchase(SubscriptionPlan plan);

  /// Restaura las compras del Apple ID. Devuelve si, tras restaurar, el usuario
  /// quedó con una suscripción activa. Lanza `SubscriptionException` si falla.
  Future<bool> restore();
}
