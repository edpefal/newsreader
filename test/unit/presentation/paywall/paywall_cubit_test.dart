import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/observability/telemetry_client.dart';
import 'package:newsreader/core/subscription/paywall_launcher.dart';
import 'package:newsreader/core/subscription/subscription_plan.dart';
import 'package:newsreader/core/subscription/subscription_status_provider.dart';
import 'package:newsreader/features/settings/domain/usecases/restore_purchases.dart';
import 'package:newsreader/features/sync/domain/usecases/sync_entitlement.dart';
import 'package:newsreader/presentation/paywall/cubit/paywall_cubit.dart';
import 'package:newsreader/presentation/paywall/cubit/paywall_state.dart';

class MockSubscriptionStatusProvider extends Mock
    implements SubscriptionStatusProvider {}

class MockSyncEntitlement extends Mock implements SyncEntitlement {}

class MockRestorePurchases extends Mock implements RestorePurchases {}

class MockTelemetryClient extends Mock implements TelemetryClient {}

const _monthly = SubscriptionPlan(
  id: r'$rc_monthly',
  type: SubscriptionPlanType.monthly,
  priceString: r'$2.99',
);
const _annualWithTrial = SubscriptionPlan(
  id: r'$rc_annual',
  type: SubscriptionPlanType.annual,
  priceString: r'$24.99',
  freeTrialDays: 7,
);
const _annualNoTrial = SubscriptionPlan(
  id: r'$rc_annual',
  type: SubscriptionPlanType.annual,
  priceString: r'$24.99',
);

const _readyState = PaywallState(
  status: PaywallStatus.ready,
  plans: [_monthly, _annualWithTrial],
  selectedPlanId: r'$rc_annual',
);

void main() {
  late MockSubscriptionStatusProvider provider;
  late MockSyncEntitlement syncEntitlement;
  late MockRestorePurchases restorePurchases;
  late MockTelemetryClient telemetry;

  PaywallCubit build({PaywallTrigger trigger = PaywallTrigger.settings}) =>
      PaywallCubit(
        provider,
        syncEntitlement,
        restorePurchases,
        telemetry,
        trigger,
      );

  setUpAll(() {
    registerFallbackValue(_monthly);
  });

  setUp(() {
    provider = MockSubscriptionStatusProvider();
    syncEntitlement = MockSyncEntitlement();
    restorePurchases = MockRestorePurchases();
    telemetry = MockTelemetryClient();

    when(
      () => provider.getPlans(),
    ).thenAnswer((_) async => [_monthly, _annualWithTrial]);
    when(() => syncEntitlement.execute()).thenAnswer((_) async => true);
  });

  group('start', () {
    blocTest<PaywallCubit, PaywallState>(
      'carga los planes y preselecciona el anual',
      build: build,
      act: (cubit) => cubit.start(),
      expect: () => [const PaywallState(), _readyState],
    );

    blocTest<PaywallCubit, PaywallState>(
      'registra paywall_viewed con el origen que lo abrió',
      build: () => build(trigger: PaywallTrigger.articleSummary),
      act: (cubit) => cubit.start(),
      verify: (_) {
        verify(
          () => telemetry.trackEvent(
            'paywall_viewed',
            properties: {'trigger': 'article_summary'},
          ),
        ).called(1);
      },
    );

    blocTest<PaywallCubit, PaywallState>(
      'sin plan anual preselecciona el primero',
      build: () {
        when(() => provider.getPlans()).thenAnswer((_) async => [_monthly]);
        return build();
      },
      act: (cubit) => cubit.start(),
      expect: () => [
        const PaywallState(),
        const PaywallState(
          status: PaywallStatus.ready,
          plans: [_monthly],
          selectedPlanId: r'$rc_monthly',
        ),
      ],
    );

    blocTest<PaywallCubit, PaywallState>(
      'si no hay ofertas muestra el error y no deja comprar',
      build: () {
        when(() => provider.getPlans()).thenThrow(
          const SubscriptionException(
            AppErrorCode.subscriptionOffersUnavailable,
            'networkError',
          ),
        );
        return build();
      },
      act: (cubit) async {
        await cubit.start();
        await cubit.purchase();
      },
      expect: () => [
        const PaywallState(),
        const PaywallState(
          status: PaywallStatus.error,
          errorCode: AppErrorCode.subscriptionOffersUnavailable,
        ),
      ],
      verify: (_) => verifyNever(() => provider.purchase(any())),
    );

    blocTest<PaywallCubit, PaywallState>(
      'reintentar tras el error vuelve a cargar y muestra los planes',
      build: () {
        var attempts = 0;
        when(() => provider.getPlans()).thenAnswer((_) async {
          attempts++;
          if (attempts == 1) {
            throw const SubscriptionException(
              AppErrorCode.subscriptionOffersUnavailable,
              'networkError',
            );
          }
          return [_monthly, _annualWithTrial];
        });
        return build();
      },
      act: (cubit) async {
        await cubit.start();
        await cubit.loadPlans();
      },
      expect: () => [
        const PaywallState(),
        const PaywallState(
          status: PaywallStatus.error,
          errorCode: AppErrorCode.subscriptionOffersUnavailable,
        ),
        const PaywallState(),
        _readyState,
      ],
    );
  });

  group('selectPlan', () {
    blocTest<PaywallCubit, PaywallState>(
      'cambia el plan seleccionado',
      build: build,
      act: (cubit) async {
        await cubit.start();
        cubit.selectPlan(r'$rc_monthly');
      },
      expect: () => [
        const PaywallState(),
        _readyState,
        _readyState.copyWith(selectedPlanId: r'$rc_monthly'),
      ],
    );
  });

  group('purchase', () {
    blocTest<PaywallCubit, PaywallState>(
      'compra exitosa sincroniza el entitlement y cierra suscrito',
      build: () {
        when(
          () => provider.purchase(any()),
        ).thenAnswer((_) async => PurchaseOutcome.purchased);
        return build();
      },
      act: (cubit) async {
        await cubit.start();
        await cubit.purchase();
      },
      expect: () => [
        const PaywallState(),
        _readyState,
        _readyState.copyWith(status: PaywallStatus.purchasing),
        _readyState.copyWith(status: PaywallStatus.subscribed),
      ],
      verify: (_) {
        verify(() => provider.purchase(_annualWithTrial)).called(1);
        verify(() => syncEntitlement.execute()).called(1);
        verify(
          () => telemetry.trackEvent(
            'purchase_completed',
            properties: {'plan': 'annual', 'is_trial': true},
          ),
        ).called(1);
      },
    );

    blocTest<PaywallCubit, PaywallState>(
      'sin prueba, purchase_completed informa is_trial = false',
      build: () {
        when(
          () => provider.getPlans(),
        ).thenAnswer((_) async => [_monthly, _annualNoTrial]);
        when(
          () => provider.purchase(any()),
        ).thenAnswer((_) async => PurchaseOutcome.purchased);
        return build();
      },
      act: (cubit) async {
        await cubit.start();
        cubit.selectPlan(r'$rc_monthly');
        await cubit.purchase();
      },
      verify: (_) {
        verify(
          () => telemetry.trackEvent(
            'purchase_completed',
            properties: {'plan': 'monthly', 'is_trial': false},
          ),
        ).called(1);
      },
    );

    blocTest<PaywallCubit, PaywallState>(
      'cancelar el pago deja el paywall abierto, sin error ni evento de fallo',
      build: () {
        when(
          () => provider.purchase(any()),
        ).thenAnswer((_) async => PurchaseOutcome.cancelled);
        return build();
      },
      act: (cubit) async {
        await cubit.start();
        await cubit.purchase();
      },
      expect: () => [
        const PaywallState(),
        _readyState,
        _readyState.copyWith(status: PaywallStatus.purchasing),
        _readyState,
      ],
      verify: (_) {
        verifyNever(() => syncEntitlement.execute());
        verifyNever(
          () => telemetry.trackEvent(
            'purchase_failed',
            properties: any(named: 'properties'),
          ),
        );
        verifyNever(
          () => telemetry.trackEvent(
            'purchase_completed',
            properties: any(named: 'properties'),
          ),
        );
      },
    );

    blocTest<PaywallCubit, PaywallState>(
      'un fallo real muestra el error y registra purchase_failed con el código',
      build: () {
        when(() => provider.purchase(any())).thenThrow(
          const SubscriptionException(
            AppErrorCode.purchaseFailed,
            'storeProblemError',
          ),
        );
        return build();
      },
      act: (cubit) async {
        await cubit.start();
        await cubit.purchase();
      },
      expect: () => [
        const PaywallState(),
        _readyState,
        _readyState.copyWith(status: PaywallStatus.purchasing),
        _readyState.copyWith(errorCode: AppErrorCode.purchaseFailed),
      ],
      verify: (_) {
        verify(
          () => telemetry.trackEvent(
            'purchase_failed',
            properties: {'error_code': 'storeProblemError'},
          ),
        ).called(1);
        verifyNever(() => syncEntitlement.execute());
      },
    );

    blocTest<PaywallCubit, PaywallState>(
      'si falla la sincronización igual cierra suscrito (el SDK ya lo confirmó)',
      build: () {
        when(
          () => provider.purchase(any()),
        ).thenAnswer((_) async => PurchaseOutcome.purchased);
        when(() => syncEntitlement.execute()).thenAnswer((_) async => false);
        return build();
      },
      act: (cubit) async {
        await cubit.start();
        await cubit.purchase();
      },
      expect: () => [
        const PaywallState(),
        _readyState,
        _readyState.copyWith(status: PaywallStatus.purchasing),
        _readyState.copyWith(status: PaywallStatus.subscribed),
      ],
    );

    blocTest<PaywallCubit, PaywallState>(
      'un segundo toque durante la compra no la repite',
      build: () {
        when(() => provider.purchase(any())).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return PurchaseOutcome.cancelled;
        });
        return build();
      },
      act: (cubit) async {
        await cubit.start();
        final first = cubit.purchase();
        await cubit.purchase();
        await first;
      },
      verify: (_) => verify(() => provider.purchase(any())).called(1),
    );
  });

  group('restore', () {
    blocTest<PaywallCubit, PaywallState>(
      'con una suscripción vigente cierra suscrito',
      build: () {
        when(() => restorePurchases.execute()).thenAnswer((_) async => true);
        return build();
      },
      act: (cubit) async {
        await cubit.start();
        await cubit.restore();
      },
      expect: () => [
        const PaywallState(),
        _readyState,
        _readyState.copyWith(status: PaywallStatus.restoring),
        _readyState.copyWith(status: PaywallStatus.subscribed),
      ],
    );

    blocTest<PaywallCubit, PaywallState>(
      'sin compras que restaurar informa y deja el paywall abierto',
      build: () {
        when(() => restorePurchases.execute()).thenAnswer((_) async => false);
        return build();
      },
      act: (cubit) async {
        await cubit.start();
        await cubit.restore();
      },
      expect: () => [
        const PaywallState(),
        _readyState,
        _readyState.copyWith(status: PaywallStatus.restoring),
        _readyState.copyWith(restoreFoundNothing: true),
      ],
    );

    blocTest<PaywallCubit, PaywallState>(
      'un fallo muestra el error de restauración',
      build: () {
        when(() => restorePurchases.execute()).thenThrow(
          const SubscriptionException(
            AppErrorCode.restoreFailed,
            'storeProblemError',
          ),
        );
        return build();
      },
      act: (cubit) async {
        await cubit.start();
        await cubit.restore();
      },
      expect: () => [
        const PaywallState(),
        _readyState,
        _readyState.copyWith(status: PaywallStatus.restoring),
        _readyState.copyWith(errorCode: AppErrorCode.restoreFailed),
      ],
    );
  });

  group('cierre', () {
    test(
      'cerrar sin comprar ni restaurar registra paywall_dismissed',
      () async {
        final cubit = build();
        await cubit.start();

        await cubit.close();

        verify(() => telemetry.trackEvent('paywall_dismissed')).called(1);
      },
    );

    test('cerrar tras comprar no registra paywall_dismissed', () async {
      when(
        () => provider.purchase(any()),
      ).thenAnswer((_) async => PurchaseOutcome.purchased);
      final cubit = build();
      await cubit.start();
      await cubit.purchase();

      await cubit.close();

      verifyNever(() => telemetry.trackEvent('paywall_dismissed'));
    });

    test('cerrar tras restaurar no registra paywall_dismissed', () async {
      when(() => restorePurchases.execute()).thenAnswer((_) async => true);
      final cubit = build();
      await cubit.start();
      await cubit.restore();

      await cubit.close();

      verifyNever(() => telemetry.trackEvent('paywall_dismissed'));
    });
  });
}
