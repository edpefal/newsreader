import 'package:equatable/equatable.dart';

import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/subscription/subscription_plan.dart';

enum PaywallStatus {
  /// Obteniendo los planes de la tienda.
  loading,

  /// Planes cargados; el usuario puede elegir y comprar.
  ready,

  /// No se pudieron obtener los planes. Sin botones de compra; solo reintentar.
  error,

  /// Compra en curso (hoja de Apple abierta o confirmándose).
  purchasing,

  /// Restauración en curso.
  restoring,

  /// El usuario quedó suscrito (compró o restauró): el paywall se cierra.
  subscribed,
}

class PaywallState extends Equatable {
  final PaywallStatus status;
  final List<SubscriptionPlan> plans;
  final String? selectedPlanId;

  /// Error de la última acción: la carga de planes en [PaywallStatus.error], o
  /// una compra/restauración fallida con los planes aún visibles.
  final AppErrorCode? errorCode;

  /// La última restauración terminó sin encontrar ninguna suscripción.
  final bool restoreFoundNothing;

  const PaywallState({
    this.status = PaywallStatus.loading,
    this.plans = const [],
    this.selectedPlanId,
    this.errorCode,
    this.restoreFoundNothing = false,
  });

  SubscriptionPlan? get selectedPlan {
    for (final plan in plans) {
      if (plan.id == selectedPlanId) return plan;
    }
    return null;
  }

  bool get isBusy =>
      status == PaywallStatus.purchasing || status == PaywallStatus.restoring;

  PaywallState copyWith({
    PaywallStatus? status,
    List<SubscriptionPlan>? plans,
    String? selectedPlanId,
    AppErrorCode? errorCode,
    bool clearError = false,
    bool restoreFoundNothing = false,
  }) {
    return PaywallState(
      status: status ?? this.status,
      plans: plans ?? this.plans,
      selectedPlanId: selectedPlanId ?? this.selectedPlanId,
      errorCode: clearError ? null : errorCode ?? this.errorCode,
      restoreFoundNothing: restoreFoundNothing,
    );
  }

  @override
  List<Object?> get props => [
    status,
    plans,
    selectedPlanId,
    errorCode,
    restoreFoundNothing,
  ];
}
