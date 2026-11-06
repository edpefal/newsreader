import 'package:purchases_flutter/purchases_flutter.dart';

/// Superficie mínima del SDK de RevenueCat que usa
/// `RevenueCatSubscriptionStatusProvider`. Existe para poder simular el SDK
/// (sus métodos son estáticos) en los tests del provider. Los errores del SDK
/// llegan como `PlatformException`; el provider los traduce.
abstract class PurchasesGateway {
  /// Configura el SDK. No hace llamadas de red, así que no bloquea el arranque.
  Future<void> configure(String apiKey);

  /// Si el entitlement `pro` está activo según la caché del SDK (o la red si
  /// no hay caché).
  Future<bool> hasProEntitlement();

  /// Avisa cada vez que `CustomerInfo` cambia, con el estado del entitlement.
  void addProEntitlementListener(void Function(bool hasPro) listener);

  /// Devuelve si el entitlement `pro` quedó activo para el usuario identificado.
  Future<bool> logIn(String userId);

  /// Vuelve a un usuario anónimo. Devuelve si el entitlement `pro` sigue activo.
  Future<bool> logOut();

  /// Paquetes de la oferta actual; vacío si no hay oferta actual.
  Future<List<Package>> currentOfferingPackages();

  /// Elegibilidad de cada producto para su oferta de introducción.
  Future<Map<String, IntroEligibility>> introEligibility(
    List<String> productIds,
  );

  /// Compra [package]. Devuelve si el entitlement `pro` quedó activo.
  Future<bool> purchasePackage(Package package);

  /// Restaura las compras. Devuelve si el entitlement `pro` quedó activo.
  Future<bool> restorePurchases();
}
