/// Abstracción sobre el proveedor de suscripciones (Superwall). Sigue la
/// regla de abstracciones del proyecto: ningún SDK de terceros se importa
/// directo en `domain/`/`presentation/` — mismo patrón que `AuthClient`.
abstract class SubscriptionStatusProvider {
  /// Estado local (cacheado por el SDK) de si el usuario tiene una
  /// suscripción activa. Prioriza velocidad/funcionar offline sobre ser la
  /// fuente de verdad — eso lo es la tabla `entitlements` del backend, que
  /// `summarize-articles` consulta de forma independiente.
  bool get isSubscribed;

  /// Identifica al usuario ante el proveedor de suscripciones con el mismo
  /// `user_id` de Supabase Auth, inmediatamente después de un login exitoso.
  Future<void> identify(String userId);

  /// Desvincula al usuario identificado (logout o borrado de cuenta). Sin
  /// esto, si otra cuenta inicia sesión en el mismo dispositivo, el
  /// proveedor podría arrastrar por un instante el estado de suscripción de
  /// la cuenta anterior hasta el próximo `identify()`.
  Future<void> reset();

  /// Muestra el paywall remoto. Si el usuario completa la compra, ejecuta
  /// [onSubscribed] automáticamente a continuación, sin que el usuario
  /// tenga que repetir la acción original.
  Future<void> showPaywall({required Future<void> Function() onSubscribed});
}
