import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/subscription/purchases_gateway.dart';
import 'package:newsreader/core/subscription/revenuecat_subscription_status_provider.dart';
import 'package:newsreader/core/subscription/subscription_plan.dart';

class MockPurchasesGateway extends Mock implements PurchasesGateway {}

const _context = PresentedOfferingContext('default', null, null);

Package _package(
  String id,
  PackageType type,
  String productId,
  String price, {
  IntroductoryPrice? intro,
}) => Package(
  id,
  type,
  StoreProduct(productId, '', id, 9.99, price, 'USD', introductoryPrice: intro),
  _context,
);

final _monthly = _package(
  r'$rc_monthly',
  PackageType.monthly,
  'reevo.monthly',
  r'$2.99',
);

Package _annual({IntroductoryPrice? intro}) => _package(
  r'$rc_annual',
  PackageType.annual,
  'reevo.annual',
  r'$24.99',
  intro: intro,
);

const _weekTrial = IntroductoryPrice(0, r'$0.00', 'P1W', 1, PeriodUnit.week, 1);

IntroEligibility _eligibility(IntroEligibilityStatus status) =>
    IntroEligibility.fromJson({'status': status.index, 'description': ''});

PlatformException _sdkError(PurchasesErrorCode code) =>
    PlatformException(code: code.index.toString());

void main() {
  late MockPurchasesGateway gateway;
  late void Function(bool) emitFromSdk;

  RevenueCatSubscriptionStatusProvider build({String? apiKey = 'appl_key'}) =>
      RevenueCatSubscriptionStatusProvider(gateway: gateway, apiKey: apiKey);

  setUpAll(() {
    registerFallbackValue(_monthly);
  });

  setUp(() {
    gateway = MockPurchasesGateway();
    when(() => gateway.configure(any())).thenAnswer((_) async {});
    when(() => gateway.hasProEntitlement()).thenAnswer((_) async => false);
    when(() => gateway.addProEntitlementListener(any())).thenAnswer((inv) {
      emitFromSdk = inv.positionalArguments.first as void Function(bool);
    });
    when(() => gateway.logIn(any())).thenAnswer((_) async => false);
    when(() => gateway.logOut()).thenAnswer((_) async => false);
  });

  group('sin llave (Android)', () {
    test('no configura el SDK y el usuario figura sin suscripción', () async {
      final provider = build(apiKey: null);

      await provider.init();
      await provider.identify('user-1');
      await provider.reset();

      expect(provider.isSubscribed, isFalse);
      verifyNever(() => gateway.configure(any()));
      verifyNever(() => gateway.logIn(any()));
      verifyNever(() => gateway.logOut());
    });

    test('los planes no están disponibles', () async {
      final provider = build(apiKey: null);
      await provider.init();

      expect(
        provider.getPlans(),
        throwsA(
          isA<SubscriptionException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.subscriptionOffersUnavailable,
          ),
        ),
      );
    });
  });

  group('estado de suscripción', () {
    test('configura el SDK con la llave de la plataforma', () async {
      await build().init();

      verify(() => gateway.configure('appl_key')).called(1);
    });

    test('el estado inicial sale de la caché del SDK', () async {
      when(() => gateway.hasProEntitlement()).thenAnswer((_) async => true);
      final provider = build();

      await provider.init();
      await Future<void>.delayed(Duration.zero);

      expect(provider.isSubscribed, isTrue);
    });

    test('sin caché ni red, arranca sin suscripción y sin lanzar', () async {
      when(
        () => gateway.hasProEntitlement(),
      ).thenThrow(_sdkError(PurchasesErrorCode.networkError));
      final provider = build();

      await provider.init();
      await Future<void>.delayed(Duration.zero);

      expect(provider.isSubscribed, isFalse);
    });

    test(
      'el listener del SDK actualiza el estado y avisa del cambio',
      () async {
        final provider = build();
        await provider.init();
        final emitted = <bool>[];
        provider.isSubscribedChanges.listen(emitted.add);

        emitFromSdk(true);
        emitFromSdk(true);
        emitFromSdk(false);
        await Future<void>.delayed(Duration.zero);

        expect(provider.isSubscribed, isFalse);
        expect(emitted, [true, false]);
      },
    );
  });

  group('identidad', () {
    test('identify hace logIn con el user_id de Supabase', () async {
      when(() => gateway.logIn('user-1')).thenAnswer((_) async => true);
      final provider = build();
      await provider.init();

      await provider.identify('user-1');

      verify(() => gateway.logIn('user-1')).called(1);
      expect(provider.isSubscribed, isTrue);
    });

    test('identify no lanza si logIn falla (sin red)', () async {
      when(
        () => gateway.logIn(any()),
      ).thenThrow(_sdkError(PurchasesErrorCode.networkError));
      final provider = build();
      await provider.init();

      await provider.identify('user-1');

      expect(provider.isSubscribed, isFalse);
    });

    test('reset hace logOut y deja el estado sin suscripción', () async {
      when(() => gateway.logIn('user-1')).thenAnswer((_) async => true);
      final provider = build();
      await provider.init();
      await provider.identify('user-1');

      await provider.reset();

      verify(() => gateway.logOut()).called(1);
      expect(provider.isSubscribed, isFalse);
    });

    test(
      'reset no lanza si el SDK rechaza logOut de un usuario anónimo',
      () async {
        when(
          () => gateway.logOut(),
        ).thenThrow(_sdkError(PurchasesErrorCode.logOutWithAnonymousUserError));
        final provider = build();
        await provider.init();

        await provider.reset();

        expect(provider.isSubscribed, isFalse);
      },
    );

    test('un logIn fallido se reintenta antes de comprar', () async {
      var logInAttempts = 0;
      when(() => gateway.logIn('user-1')).thenAnswer((_) async {
        logInAttempts++;
        if (logInAttempts == 1) {
          throw _sdkError(PurchasesErrorCode.networkError);
        }
        return false;
      });
      when(
        () => gateway.currentOfferingPackages(),
      ).thenAnswer((_) async => [_monthly]);
      when(() => gateway.purchasePackage(any())).thenAnswer((_) async => true);
      final provider = build();
      await provider.init();
      await provider.identify('user-1');
      final plans = await provider.getPlans();

      await provider.purchase(plans.single);

      expect(logInAttempts, 2);
    });

    test('tras reset ya no se reintenta ningún logIn', () async {
      when(
        () => gateway.logIn(any()),
      ).thenThrow(_sdkError(PurchasesErrorCode.networkError));
      when(
        () => gateway.currentOfferingPackages(),
      ).thenAnswer((_) async => [_monthly]);
      when(() => gateway.purchasePackage(any())).thenAnswer((_) async => true);
      final provider = build();
      await provider.init();
      await provider.identify('user-1');
      await provider.reset();
      final plans = await provider.getPlans();

      await provider.purchase(plans.single);

      verify(() => gateway.logIn('user-1')).called(1);
    });
  });

  group('getPlans', () {
    test('devuelve mensual y anual con el precio de la tienda', () async {
      when(
        () => gateway.currentOfferingPackages(),
      ).thenAnswer((_) async => [_annual(), _monthly]);
      final provider = build();
      await provider.init();

      final plans = await provider.getPlans();

      expect(plans, [
        const SubscriptionPlan(
          id: r'$rc_monthly',
          type: SubscriptionPlanType.monthly,
          priceString: r'$2.99',
        ),
        const SubscriptionPlan(
          id: r'$rc_annual',
          type: SubscriptionPlanType.annual,
          priceString: r'$24.99',
        ),
      ]);
    });

    test('ofrece la prueba gratis solo a quien es elegible', () async {
      when(
        () => gateway.currentOfferingPackages(),
      ).thenAnswer((_) async => [_monthly, _annual(intro: _weekTrial)]);
      when(() => gateway.introEligibility(['reevo.annual'])).thenAnswer(
        (_) async => {
          'reevo.annual': _eligibility(
            IntroEligibilityStatus.introEligibilityStatusEligible,
          ),
        },
      );
      final provider = build();
      await provider.init();

      final plans = await provider.getPlans();

      expect(plans.last.freeTrialDays, 7);
      expect(plans.last.hasFreeTrial, isTrue);
      expect(plans.first.hasFreeTrial, isFalse);
    });

    test('un usuario no elegible ve el plan sin prueba', () async {
      when(
        () => gateway.currentOfferingPackages(),
      ).thenAnswer((_) async => [_monthly, _annual(intro: _weekTrial)]);
      when(() => gateway.introEligibility(any())).thenAnswer(
        (_) async => {
          'reevo.annual': _eligibility(
            IntroEligibilityStatus.introEligibilityStatusIneligible,
          ),
        },
      );
      final provider = build();
      await provider.init();

      final plans = await provider.getPlans();

      expect(plans.last.freeTrialDays, isNull);
    });

    test(
      'si falla la consulta de elegibilidad, muestra los planes sin prueba',
      () async {
        when(
          () => gateway.currentOfferingPackages(),
        ).thenAnswer((_) async => [_monthly, _annual(intro: _weekTrial)]);
        when(
          () => gateway.introEligibility(any()),
        ).thenThrow(_sdkError(PurchasesErrorCode.networkError));
        final provider = build();
        await provider.init();

        final plans = await provider.getPlans();

        expect(plans, hasLength(2));
        expect(plans.last.freeTrialDays, isNull);
      },
    );

    test('una oferta de introducción de pago no es prueba gratis', () async {
      const paidIntro = IntroductoryPrice(
        0.99,
        r'$0.99',
        'P1M',
        1,
        PeriodUnit.month,
        1,
      );
      when(
        () => gateway.currentOfferingPackages(),
      ).thenAnswer((_) async => [_annual(intro: paidIntro)]);
      final provider = build();
      await provider.init();

      final plans = await provider.getPlans();

      expect(plans.single.freeTrialDays, isNull);
      verifyNever(() => gateway.introEligibility(any()));
    });

    test('sin paquetes disponibles, lanza offersUnavailable', () async {
      when(
        () => gateway.currentOfferingPackages(),
      ).thenAnswer((_) async => const []);
      final provider = build();
      await provider.init();

      expect(
        provider.getPlans(),
        throwsA(
          isA<SubscriptionException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.subscriptionOffersUnavailable,
          ),
        ),
      );
    });

    test('un error del SDK se traduce a offersUnavailable', () async {
      when(
        () => gateway.currentOfferingPackages(),
      ).thenThrow(_sdkError(PurchasesErrorCode.networkError));
      final provider = build();
      await provider.init();

      expect(
        provider.getPlans(),
        throwsA(
          isA<SubscriptionException>()
              .having(
                (e) => e.code,
                'code',
                AppErrorCode.subscriptionOffersUnavailable,
              )
              .having((e) => e.reason, 'reason', 'networkError'),
        ),
      );
    });

    test('un código de error no numérico no rompe la traducción', () async {
      when(
        () => gateway.currentOfferingPackages(),
      ).thenThrow(PlatformException(code: 'channel-error'));
      final provider = build();
      await provider.init();

      expect(
        provider.getPlans(),
        throwsA(
          isA<SubscriptionException>().having(
            (e) => e.reason,
            'reason',
            'unknownError',
          ),
        ),
      );
    });
  });

  group('purchase', () {
    late RevenueCatSubscriptionStatusProvider provider;
    late SubscriptionPlan plan;

    setUp(() async {
      when(
        () => gateway.currentOfferingPackages(),
      ).thenAnswer((_) async => [_monthly]);
      provider = build();
      await provider.init();
      plan = (await provider.getPlans()).single;
    });

    test('compra exitosa deja al usuario suscrito', () async {
      when(() => gateway.purchasePackage(any())).thenAnswer((_) async => true);

      final outcome = await provider.purchase(plan);

      expect(outcome, PurchaseOutcome.purchased);
      expect(provider.isSubscribed, isTrue);
    });

    test('cancelar la compra no es un error ni concede acceso', () async {
      when(
        () => gateway.purchasePackage(any()),
      ).thenThrow(_sdkError(PurchasesErrorCode.purchaseCancelledError));

      final outcome = await provider.purchase(plan);

      expect(outcome, PurchaseOutcome.cancelled);
      expect(provider.isSubscribed, isFalse);
    });

    test(
      'un fallo de la tienda lanza purchaseFailed con el código del SDK',
      () async {
        when(
          () => gateway.purchasePackage(any()),
        ).thenThrow(_sdkError(PurchasesErrorCode.storeProblemError));

        expect(
          provider.purchase(plan),
          throwsA(
            isA<SubscriptionException>()
                .having((e) => e.code, 'code', AppErrorCode.purchaseFailed)
                .having((e) => e.reason, 'reason', 'storeProblemError'),
          ),
        );
      },
    );

    test('un fallo de red se clasifica como network', () async {
      when(
        () => gateway.purchasePackage(any()),
      ).thenThrow(_sdkError(PurchasesErrorCode.networkError));

      expect(
        provider.purchase(plan),
        throwsA(
          isA<SubscriptionException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.network,
          ),
        ),
      );
    });

    test(
      'si el entitlement no queda activo, la compra se trata como fallo',
      () async {
        when(
          () => gateway.purchasePackage(any()),
        ).thenAnswer((_) async => false);

        expect(provider.purchase(plan), throwsA(isA<SubscriptionException>()));
        expect(provider.isSubscribed, isFalse);
      },
    );

    test('un plan que no viene de getPlans falla sin llamar al SDK', () async {
      const unknown = SubscriptionPlan(
        id: 'otro',
        type: SubscriptionPlanType.monthly,
        priceString: r'$1',
      );

      await expectLater(
        provider.purchase(unknown),
        throwsA(isA<SubscriptionException>()),
      );
      verifyNever(() => gateway.purchasePackage(any()));
    });
  });

  group('restore', () {
    test(
      'devuelve true y deja suscrito cuando hay una suscripción vigente',
      () async {
        when(() => gateway.restorePurchases()).thenAnswer((_) async => true);
        final provider = build();
        await provider.init();

        expect(await provider.restore(), isTrue);
        expect(provider.isSubscribed, isTrue);
      },
    );

    test('devuelve false cuando no hay compras que restaurar', () async {
      when(() => gateway.restorePurchases()).thenAnswer((_) async => false);
      final provider = build();
      await provider.init();

      expect(await provider.restore(), isFalse);
      expect(provider.isSubscribed, isFalse);
    });

    test('un fallo lanza restoreFailed', () async {
      when(
        () => gateway.restorePurchases(),
      ).thenThrow(_sdkError(PurchasesErrorCode.storeProblemError));
      final provider = build();
      await provider.init();

      expect(
        provider.restore(),
        throwsA(
          isA<SubscriptionException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.restoreFailed,
          ),
        ),
      );
    });
  });
}
