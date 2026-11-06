import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/config/app_config.dart';
import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/navigation/external_link_launcher.dart';
import 'package:newsreader/core/subscription/subscription_plan.dart';
import 'package:newsreader/presentation/paywall/cubit/paywall_cubit.dart';
import 'package:newsreader/presentation/paywall/cubit/paywall_state.dart';
import 'package:newsreader/presentation/paywall/paywall_screen.dart';
import 'package:newsreader/presentation/paywall/widgets/plan_option_card.dart';
import 'package:newsreader/presentation/theme/app_theme.dart';

import '../../../support/pump_localized_app.dart';

class MockPaywallCubit extends MockCubit<PaywallState>
    implements PaywallCubit {}

class MockExternalLinkLauncher extends Mock implements ExternalLinkLauncher {}

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

PaywallState _ready({
  List<SubscriptionPlan> plans = const [_monthly, _annualWithTrial],
  String? selected = r'$rc_annual',
  PaywallStatus status = PaywallStatus.ready,
  AppErrorCode? errorCode,
  bool restoreFoundNothing = false,
}) => PaywallState(
  status: status,
  plans: plans,
  selectedPlanId: selected,
  errorCode: errorCode,
  restoreFoundNothing: restoreFoundNothing,
);

void main() {
  late MockPaywallCubit cubit;
  late MockExternalLinkLauncher launcher;

  setUp(() {
    cubit = MockPaywallCubit();
    launcher = MockExternalLinkLauncher();
    when(() => launcher.open(any())).thenAnswer((_) async {});
    when(() => cubit.loadPlans()).thenAnswer((_) async {});
    when(() => cubit.purchase()).thenAnswer((_) async {});
    when(() => cubit.restore()).thenAnswer((_) async {});
    when(() => cubit.selectPlan(any())).thenReturn(null);
  });

  Future<void> pumpPaywall(
    WidgetTester tester,
    PaywallState state, {
    PaywallPresentation presentation = PaywallPresentation.fullScreen,
    Stream<PaywallState>? stream,
    Size size = const Size(600, 1400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    whenListen(
      cubit,
      stream ?? const Stream<PaywallState>.empty(),
      initialState: state,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: testLocale,
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider<PaywallCubit>.value(
                      value: cubit,
                      child: PaywallScreen(
                        externalLinkLauncher: launcher,
                        presentation: presentation,
                      ),
                    ),
                  ),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    // No `pumpAndSettle`: el estado de carga tiene una animación infinita.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  group('estados', () {
    testWidgets('cargando muestra un indicador y ningún botón de compra', (
      tester,
    ) async {
      await pumpPaywall(tester, const PaywallState());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('error de ofertas muestra el mensaje y "Reintentar", sin '
        'botones de compra', (tester) async {
      await pumpPaywall(
        tester,
        const PaywallState(
          status: PaywallStatus.error,
          errorCode: AppErrorCode.subscriptionOffersUnavailable,
        ),
      );

      expect(
        find.text(
          'No pudimos cargar los planes de suscripción. Revisa tu conexión e '
          'intenta de nuevo.',
        ),
        findsOneWidget,
      );
      expect(find.byType(FilledButton), findsNothing);

      await tester.tap(find.text('Reintentar'));
      verify(() => cubit.loadPlans()).called(1);
    });

    testWidgets('muestra ambos planes con el precio de la tienda', (
      tester,
    ) async {
      await pumpPaywall(tester, _ready());

      expect(find.text('Reevo Premium'), findsOneWidget);
      expect(find.text('Mensual'), findsOneWidget);
      expect(find.text('Anual'), findsOneWidget);
      expect(find.text(r'$2.99 / mes'), findsOneWidget);
      expect(find.text(r'$24.99 / año'), findsOneWidget);
    });

    testWidgets('plan anual elegible: indica los 7 días gratis y cuándo se '
        'cobra', (tester) async {
      await pumpPaywall(tester, _ready());

      expect(find.text('7 días gratis'), findsOneWidget);
      expect(find.text('Empezar prueba gratis de 7 días'), findsOneWidget);
      expect(
        find.textContaining('Después de tu prueba gratis de 7 días'),
        findsOneWidget,
      );
      expect(find.textContaining(r'$24.99 al año'), findsOneWidget);
    });

    testWidgets('usuario no elegible: plan anual a precio completo, sin '
        'mencionar prueba', (tester) async {
      await pumpPaywall(
        tester,
        _ready(plans: const [_monthly, _annualNoTrial]),
      );

      expect(find.textContaining('gratis'), findsNothing);
      expect(find.text('Suscribirme'), findsOneWidget);
      expect(find.textContaining('se renueva automáticamente'), findsOneWidget);
    });

    testWidgets('muestra el texto de renovación, los enlaces legales y '
        '"Restaurar compras"', (tester) async {
      await pumpPaywall(tester, _ready(selected: r'$rc_monthly'));

      expect(find.textContaining(r'$2.99 al mes'), findsOneWidget);
      expect(find.text('Términos de servicio'), findsOneWidget);
      expect(find.text('Política de privacidad'), findsOneWidget);
      expect(find.text('Restaurar compras'), findsOneWidget);
    });

    testWidgets('los enlaces legales abren las páginas estables', (
      tester,
    ) async {
      await pumpPaywall(tester, _ready());

      await tester.tap(find.text('Términos de servicio'));
      await tester.tap(find.text('Política de privacidad'));

      verify(() => launcher.open(AppConfig.termsUrl)).called(1);
      verify(() => launcher.open(AppConfig.privacyUrl)).called(1);
    });

    testWidgets('una compra fallida muestra el error y deja comprar de nuevo', (
      tester,
    ) async {
      await pumpPaywall(tester, _ready(errorCode: AppErrorCode.purchaseFailed));

      expect(
        find.text('No se pudo completar la compra. Intenta de nuevo.'),
        findsOneWidget,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    });

    testWidgets('restaurar sin compras informa que no se encontró nada y '
        'el paywall sigue abierto', (tester) async {
      await pumpPaywall(tester, _ready(restoreFoundNothing: true));

      expect(
        find.text('No encontramos compras para restaurar.'),
        findsOneWidget,
      );
      expect(find.byType(PaywallScreen), findsOneWidget);
    });

    testWidgets('durante la compra los botones quedan deshabilitados', (
      tester,
    ) async {
      await pumpPaywall(tester, _ready(status: PaywallStatus.purchasing));

      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Restaurar compras'),
            )
            .onPressed,
        isNull,
      );
    });
  });

  group('acciones', () {
    testWidgets('tocar el botón principal compra el plan seleccionado', (
      tester,
    ) async {
      await pumpPaywall(tester, _ready());

      await tester.tap(find.byType(FilledButton));

      verify(() => cubit.purchase()).called(1);
    });

    testWidgets('tocar "Restaurar compras" restaura', (tester) async {
      await pumpPaywall(tester, _ready());

      await tester.tap(find.text('Restaurar compras'));

      verify(() => cubit.restore()).called(1);
    });

    testWidgets('elegir el plan mensual lo selecciona', (tester) async {
      await pumpPaywall(tester, _ready());

      await tester.tap(find.text('Mensual'));

      verify(() => cubit.selectPlan(r'$rc_monthly')).called(1);
    });

    testWidgets('al quedar suscrito el paywall se cierra devolviendo true', (
      tester,
    ) async {
      bool? result;
      whenListen(
        cubit,
        Stream.fromIterable([_ready(status: PaywallStatus.subscribed)]),
        initialState: _ready(),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: testLocale,
          localizationsDelegates: testLocalizationsDelegates,
          supportedLocales: testSupportedLocales,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider<PaywallCubit>.value(
                      value: cubit,
                      child: PaywallScreen(
                        externalLinkLauncher: launcher,
                        presentation: PaywallPresentation.fullScreen,
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.byType(PaywallScreen), findsNothing);
    });

    testWidgets('cerrar con la X devuelve null (sin suscripción)', (
      tester,
    ) async {
      await pumpPaywall(tester, _ready());

      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();

      expect(find.byType(PaywallScreen), findsNothing);
    });
  });

  group('presentación', () {
    testWidgets('pantalla completa: sin diálogo', (tester) async {
      await pumpPaywall(tester, _ready(), size: const Size(400, 800));

      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(PlanOptionCard), findsNWidgets(2));
    });

    testWidgets('diálogo: usa Dialog y el contenido no ocupa toda la ventana', (
      tester,
    ) async {
      await pumpPaywall(
        tester,
        _ready(),
        presentation: PaywallPresentation.dialog,
        size: const Size(1200, 900),
      );

      expect(find.byType(Dialog), findsOneWidget);
      final width = tester.getSize(find.byType(PlanOptionCard).first).width;
      expect(width, lessThanOrEqualTo(kPaywallMaxContentWidth));
    });

    testWidgets('en un ancho de iPad el contenido no excede el máximo', (
      tester,
    ) async {
      await pumpPaywall(tester, _ready(), size: const Size(1200, 900));

      final width = tester.getSize(find.byType(PlanOptionCard).first).width;
      expect(width, lessThanOrEqualTo(kPaywallMaxContentWidth));
    });
  });
}
