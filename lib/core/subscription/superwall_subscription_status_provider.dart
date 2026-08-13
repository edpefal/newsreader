import 'dart:async';

import 'package:superwallkit_flutter/superwallkit_flutter.dart';

import 'package:newsreader/core/subscription/subscription_status_provider.dart';

/// Placement configurado en el dashboard de Superwall para el paywall del
/// resumen diario. El copy/diseño del paywall en sí se arma remoto, desde
/// el dashboard — acá solo se referencia el nombre del placement.
const _dailySummaryPlacement = 'daily_summary';

class SuperwallSubscriptionStatusProvider implements SubscriptionStatusProvider {
  bool _isSubscribed = false;
  StreamSubscription<SubscriptionStatus>? _subscription;

  SuperwallSubscriptionStatusProvider() {
    _subscription = Superwall.shared.subscriptionStatus.listen((status) {
      _isSubscribed = status.isActive;
    });
  }

  @override
  bool get isSubscribed => _isSubscribed;

  /// Cancela la suscripción al stream de estado. Se registra como
  /// singleton de por vida de la app, así que en la práctica no hace falta
  /// llamarlo, pero se expone para no dejar el `StreamSubscription` sin
  /// forma de cerrarse.
  void dispose() => _subscription?.cancel();

  @override
  Future<void> identify(String userId) => Superwall.shared.identify(userId);

  @override
  Future<void> reset() => Superwall.shared.reset();

  @override
  Future<void> showPaywall({
    required Future<void> Function() onSubscribed,
  }) {
    // `registerPlacement` consulta las audience filters configuradas en el
    // dashboard: si el usuario ya tiene acceso, corre `feature` directo sin
    // mostrar nada; si no, muestra el paywall y solo corre `feature` si
    // completa la compra. Cubre a la vez el gate y el "seguir sin que el
    // usuario tenga que tocar el botón de nuevo" pedidos en tasks.md.
    return Superwall.shared.registerPlacement(
      _dailySummaryPlacement,
      feature: onSubscribed,
    );
  }
}
