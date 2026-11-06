import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/navigation/external_link_launcher.dart';
import 'package:newsreader/core/observability/telemetry_client.dart';
import 'package:newsreader/core/subscription/paywall_launcher.dart';
import 'package:newsreader/core/subscription/subscription_plan.dart';
import 'package:newsreader/core/subscription/subscription_status_provider.dart';
import 'package:newsreader/features/settings/domain/usecases/restore_purchases.dart';
import 'package:newsreader/features/sync/domain/usecases/sync_entitlement.dart';
import 'package:newsreader/presentation/paywall/app_paywall_launcher.dart';
import 'package:newsreader/presentation/paywall/paywall_screen.dart';
import 'package:newsreader/presentation/theme/app_theme.dart';

import '../../../support/pump_localized_app.dart';

class MockSubscriptionStatusProvider extends Mock
    implements SubscriptionStatusProvider {}

class MockSyncEntitlement extends Mock implements SyncEntitlement {}

class MockRestorePurchases extends Mock implements RestorePurchases {}

class MockTelemetryClient extends Mock implements TelemetryClient {}

class MockExternalLinkLauncher extends Mock implements ExternalLinkLauncher {}

const _monthly = SubscriptionPlan(
  id: r'$rc_monthly',
  type: SubscriptionPlanType.monthly,
  priceString: r'$2.99',
);
const _annual = SubscriptionPlan(
  id: r'$rc_annual',
  type: SubscriptionPlanType.annual,
  priceString: r'$24.99',
);

void main() {
  late MockSubscriptionStatusProvider provider;
  late MockSyncEntitlement syncEntitlement;
  late MockRestorePurchases restorePurchases;
  late MockTelemetryClient telemetry;
  late AppPaywallLauncher launcher;

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
    ).thenAnswer((_) async => [_monthly, _annual]);
    when(() => syncEntitlement.execute()).thenAnswer((_) async => true);
    launcher = AppPaywallLauncher(
      provider,
      syncEntitlement,
      restorePurchases,
      telemetry,
      MockExternalLinkLauncher(),
    );
  });

  /// Monta una app con un `Navigator` anidado (como el panel derecho del
  /// master-detail) que contiene el botón que abre el paywall.
  Future<void> pumpHost(
    WidgetTester tester, {
    required Size size,
    required void Function(bool) onResult,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: testLocale,
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        home: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async => onResult(
                    await launcher.show(
                      context,
                      trigger: PaywallTrigger.settings,
                    ),
                  ),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('bajo 840dp se presenta como pantalla completa, sin diálogo', (
    tester,
  ) async {
    await pumpHost(tester, size: const Size(400, 900), onResult: (_) {});

    expect(find.byType(PaywallScreen), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    final screen = tester.widget<PaywallScreen>(find.byType(PaywallScreen));
    expect(screen.presentation, PaywallPresentation.fullScreen);
  });

  testWidgets('desde 840dp se presenta como diálogo centrado', (tester) async {
    await pumpHost(tester, size: const Size(1000, 900), onResult: (_) {});

    expect(find.byType(Dialog), findsOneWidget);
    final screen = tester.widget<PaywallScreen>(find.byType(PaywallScreen));
    expect(screen.presentation, PaywallPresentation.dialog);
  });

  testWidgets('justo en 840dp ya es diálogo', (tester) async {
    await pumpHost(tester, size: const Size(840, 900), onResult: (_) {});

    expect(find.byType(Dialog), findsOneWidget);
  });

  testWidgets(
    'se monta en el navegador raíz, no dentro del navegador anidado del panel',
    (tester) async {
      await pumpHost(tester, size: const Size(400, 900), onResult: (_) {});

      final rootNavigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      final paywallNavigator = Navigator.of(
        tester.element(find.byType(PaywallScreen)),
      );
      expect(paywallNavigator, same(rootNavigator));
    },
  );

  testWidgets('cerrar sin comprar devuelve false y registra el cierre', (
    tester,
  ) async {
    bool? result;
    await pumpHost(
      tester,
      size: const Size(400, 900),
      onResult: (r) => result = r,
    );

    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
    verify(() => telemetry.trackEvent('paywall_dismissed')).called(1);
    verify(
      () => telemetry.trackEvent(
        'paywall_viewed',
        properties: {'trigger': 'settings'},
      ),
    ).called(1);
  });

  testWidgets('comprar devuelve true', (tester) async {
    when(
      () => provider.purchase(any()),
    ).thenAnswer((_) async => PurchaseOutcome.purchased);
    bool? result;
    await pumpHost(
      tester,
      size: const Size(400, 1400),
      onResult: (r) => result = r,
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    verify(() => syncEntitlement.execute()).called(1);
  });
}
