import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/observability/telemetry_client.dart';
import 'package:newsreader/core/subscription/paywall_launcher.dart';
import 'package:newsreader/core/subscription/subscription_plan.dart';
import 'package:newsreader/core/subscription/subscription_status_provider.dart';
import 'package:newsreader/features/settings/domain/usecases/restore_purchases.dart';
import 'package:newsreader/features/sync/domain/usecases/sync_entitlement.dart';
import 'package:newsreader/presentation/paywall/cubit/paywall_state.dart';

class PaywallCubit extends Cubit<PaywallState> {
  final SubscriptionStatusProvider _subscriptionStatusProvider;
  final SyncEntitlement _syncEntitlement;
  final RestorePurchases _restorePurchases;
  final TelemetryClient _telemetryClient;
  final PaywallTrigger _trigger;

  /// Se vuelve `true` al comprar o restaurar con éxito; decide si al cerrar el
  /// paywall se registra `paywall_dismissed`.
  bool _didSubscribe = false;

  PaywallCubit(
    this._subscriptionStatusProvider,
    this._syncEntitlement,
    this._restorePurchases,
    this._telemetryClient,
    this._trigger,
  ) : super(const PaywallState());

  /// Registra la vista del paywall y carga los planes.
  Future<void> start() {
    _telemetryClient.trackEvent(
      'paywall_viewed',
      properties: {'trigger': _trigger.analyticsName},
    );
    return loadPlans();
  }

  Future<void> loadPlans() async {
    emit(const PaywallState());
    try {
      final plans = await _subscriptionStatusProvider.getPlans();
      emit(
        PaywallState(
          status: PaywallStatus.ready,
          plans: plans,
          selectedPlanId: _defaultPlan(plans).id,
        ),
      );
    } on SubscriptionException catch (e) {
      emit(PaywallState(status: PaywallStatus.error, errorCode: e.code));
    }
  }

  /// Preselecciona el anual: es el plan que ofrece la prueba gratis.
  static SubscriptionPlan _defaultPlan(List<SubscriptionPlan> plans) {
    return plans.firstWhere(
      (p) => p.type == SubscriptionPlanType.annual,
      orElse: () => plans.first,
    );
  }

  void selectPlan(String planId) {
    if (state.isBusy) return;
    emit(state.copyWith(selectedPlanId: planId, clearError: true));
  }

  Future<void> purchase() async {
    final plan = state.selectedPlan;
    if (plan == null || state.isBusy || state.status != PaywallStatus.ready) {
      return;
    }
    emit(state.copyWith(status: PaywallStatus.purchasing, clearError: true));
    try {
      final outcome = await _subscriptionStatusProvider.purchase(plan);
      if (outcome == PurchaseOutcome.cancelled) {
        // Cancelar el pago no es un fallo: el paywall sigue abierto sin error.
        emit(state.copyWith(status: PaywallStatus.ready));
        return;
      }
      _telemetryClient.trackEvent(
        'purchase_completed',
        properties: {'plan': plan.type.name, 'is_trial': plan.hasFreeTrial},
      );
      await _finishSubscribed();
    } on SubscriptionException catch (e) {
      _telemetryClient.trackEvent(
        'purchase_failed',
        properties: {'error_code': e.reason},
      );
      emit(state.copyWith(status: PaywallStatus.ready, errorCode: e.code));
    }
  }

  Future<void> restore() async {
    if (state.isBusy || state.status != PaywallStatus.ready) return;
    emit(state.copyWith(status: PaywallStatus.restoring, clearError: true));
    try {
      final found = await _restorePurchases.execute();
      if (found) {
        _didSubscribe = true;
        emit(
          state.copyWith(status: PaywallStatus.subscribed, clearError: true),
        );
      } else {
        emit(
          state.copyWith(
            status: PaywallStatus.ready,
            restoreFoundNothing: true,
          ),
        );
      }
    } on SubscriptionException catch (e) {
      emit(state.copyWith(status: PaywallStatus.ready, errorCode: e.code));
    }
  }

  /// Tras una compra, sincroniza `entitlements` antes de cerrar para que la
  /// acción que dependía de la suscripción no choque con el gate del servidor.
  /// Si falla, no se bloquea: el estado local ya viene del SDK y el webhook
  /// repara el servidor. (La restauración sincroniza dentro de
  /// [RestorePurchases].)
  Future<void> _finishSubscribed() async {
    _didSubscribe = true;
    await _syncEntitlement.execute();
    emit(state.copyWith(status: PaywallStatus.subscribed, clearError: true));
  }

  @override
  Future<void> close() {
    if (!_didSubscribe) {
      _telemetryClient.trackEvent('paywall_dismissed');
    }
    return super.close();
  }
}
