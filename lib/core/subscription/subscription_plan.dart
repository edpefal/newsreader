import 'package:equatable/equatable.dart';

enum SubscriptionPlanType { monthly, annual }

/// Resultado de intentar comprar un plan. Una cancelación del usuario desde la
/// hoja de Apple no es un error: se reporta como [cancelled].
enum PurchaseOutcome { purchased, cancelled }

/// Plan de suscripción ofrecido por la tienda, ya sin tipos del SDK. El precio
/// llega formateado por la tienda para la región del usuario: nunca se escribe
/// a mano.
class SubscriptionPlan extends Equatable {
  /// Identificador del paquete en la oferta de RevenueCat.
  final String id;
  final SubscriptionPlanType type;
  final String priceString;

  /// Días de prueba gratis que se le darían a *este* usuario. `null` si el plan
  /// no tiene prueba o si el usuario ya no es elegible.
  final int? freeTrialDays;

  const SubscriptionPlan({
    required this.id,
    required this.type,
    required this.priceString,
    this.freeTrialDays,
  });

  bool get hasFreeTrial => freeTrialDays != null;

  @override
  List<Object?> get props => [id, type, priceString, freeTrialDays];
}
