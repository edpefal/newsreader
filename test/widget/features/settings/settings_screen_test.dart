import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/config/app_config.dart';
import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/navigation/external_link_launcher.dart';
import 'package:newsreader/core/subscription/paywall_launcher.dart';
import 'package:newsreader/core/subscription/subscription_status_provider.dart';
import 'package:newsreader/features/settings/domain/usecases/restore_purchases.dart';
import 'package:newsreader/features/account/domain/usecases/delete_account.dart';
import 'package:newsreader/features/account/domain/usecases/export_user_data.dart';
import 'package:newsreader/features/settings/presentation/screens/settings_screen.dart';
import 'package:newsreader/features/settings/presentation/widgets/sign_out_unsynced_changes_dialog.dart';
import 'package:newsreader/features/sync/domain/usecases/clear_local_user_data.dart';
import 'package:newsreader/features/sync/domain/usecases/sync_user_data.dart';
import 'package:newsreader/presentation/theme/app_theme.dart';
import 'package:newsreader/presentation/theme/theme_cubit.dart';

import '../../../support/pump_localized_app.dart';

class MockExportUserData extends Mock implements ExportUserData {}

class MockDeleteAccount extends Mock implements DeleteAccount {}

class MockClearLocalUserData extends Mock implements ClearLocalUserData {}

class MockSyncUserData extends Mock implements SyncUserData {}

class MockAuthClient extends Mock implements AuthClient {}

class MockSubscriptionStatusProvider extends Mock
    implements SubscriptionStatusProvider {}

class MockPaywallLauncher extends Mock implements PaywallLauncher {}

class MockRestorePurchases extends Mock implements RestorePurchases {}

class MockExternalLinkLauncher extends Mock implements ExternalLinkLauncher {}

class FakeBuildContext extends Fake implements BuildContext {}

class MockSettingsBox extends Mock implements Box<dynamic> {}

Widget _buildSubject({
  required ExportUserData exportUserData,
  required DeleteAccount deleteAccount,
  required ClearLocalUserData clearLocalUserData,
  required SyncUserData syncUserData,
  required AuthClient authClient,
  required SubscriptionStatusProvider subscriptionStatusProvider,
  PaywallLauncher? paywallLauncher,
  RestorePurchases? restorePurchases,
  ExternalLinkLauncher? externalLinkLauncher,
}) {
  final settingsBox = MockSettingsBox();
  when(
    () => settingsBox.get(any(), defaultValue: any(named: 'defaultValue')),
  ).thenAnswer((invocation) => invocation.namedArguments[#defaultValue]);
  when(() => settingsBox.put(any(), any())).thenAnswer((_) async {});

  return MaterialApp(
    theme: AppTheme.light,
    locale: testLocale,
    localizationsDelegates: testLocalizationsDelegates,
    supportedLocales: testSupportedLocales,
    home: BlocProvider<ThemeCubit>(
      create: (_) => ThemeCubit(settingsBox),
      child: SettingsScreen(
        exportUserData: exportUserData,
        deleteAccount: deleteAccount,
        clearLocalUserData: clearLocalUserData,
        syncUserData: syncUserData,
        authClient: authClient,
        subscriptionStatusProvider: subscriptionStatusProvider,
        paywallLauncher: paywallLauncher ?? MockPaywallLauncher(),
        restorePurchases: restorePurchases ?? MockRestorePurchases(),
        externalLinkLauncher:
            externalLinkLauncher ?? MockExternalLinkLauncher(),
      ),
    ),
  );
}

void main() {
  group('SettingsScreen', () {
    late MockExportUserData exportUserData;
    late MockDeleteAccount deleteAccount;
    late MockClearLocalUserData clearLocalUserData;
    late MockSyncUserData syncUserData;
    late MockAuthClient authClient;
    late MockSubscriptionStatusProvider subscriptionStatusProvider;
    late StreamController<bool> subscriptionChanges;
    late MockPaywallLauncher paywallLauncher;
    late MockRestorePurchases restorePurchases;
    late MockExternalLinkLauncher externalLinkLauncher;

    setUpAll(() {
      registerFallbackValue(FakeBuildContext());
      registerFallbackValue(PaywallTrigger.settings);
    });

    setUp(() {
      subscriptionChanges = StreamController<bool>.broadcast();
      addTearDown(subscriptionChanges.close);
      paywallLauncher = MockPaywallLauncher();
      restorePurchases = MockRestorePurchases();
      externalLinkLauncher = MockExternalLinkLauncher();
      when(() => externalLinkLauncher.open(any())).thenAnswer((_) async {});
      exportUserData = MockExportUserData();
      deleteAccount = MockDeleteAccount();
      clearLocalUserData = MockClearLocalUserData();
      syncUserData = MockSyncUserData();
      authClient = MockAuthClient();
      subscriptionStatusProvider = MockSubscriptionStatusProvider();
      when(() => clearLocalUserData.execute()).thenAnswer((_) async {});
      when(() => syncUserData.execute()).thenAnswer((_) async {});
      when(() => authClient.signOut()).thenAnswer((_) async {});
      when(() => authClient.currentUserEmail).thenReturn('lector@example.com');
      when(() => subscriptionStatusProvider.isSubscribed).thenReturn(false);
      when(
        () => subscriptionStatusProvider.isSubscribedChanges,
      ).thenAnswer((_) => subscriptionChanges.stream);
    });

    testWidgets('muestra la opción de cerrar sesión', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          exportUserData: exportUserData,
          deleteAccount: deleteAccount,
          clearLocalUserData: clearLocalUserData,
          syncUserData: syncUserData,
          authClient: authClient,
          subscriptionStatusProvider: subscriptionStatusProvider,
        ),
      );

      expect(find.text('Cerrar sesión'), findsOneWidget);
    });

    testWidgets(
      'tocar "Cerrar sesión" limpia los datos locales y cierra sesión',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            exportUserData: exportUserData,
            deleteAccount: deleteAccount,
            clearLocalUserData: clearLocalUserData,
            syncUserData: syncUserData,
            authClient: authClient,
            subscriptionStatusProvider: subscriptionStatusProvider,
          ),
        );

        await tester.tap(find.text('Cerrar sesión'));
        await tester.pumpAndSettle();

        verify(() => syncUserData.execute()).called(1);
        verify(() => clearLocalUserData.execute()).called(1);
        verify(() => authClient.signOut()).called(1);
      },
    );

    testWidgets('si el flush falla y el usuario cancela, no cierra sesión', (
      tester,
    ) async {
      when(
        () => syncUserData.execute(),
      ).thenThrow(const CloudSyncException('sin conexión'));

      await tester.pumpWidget(
        _buildSubject(
          exportUserData: exportUserData,
          deleteAccount: deleteAccount,
          clearLocalUserData: clearLocalUserData,
          syncUserData: syncUserData,
          authClient: authClient,
          subscriptionStatusProvider: subscriptionStatusProvider,
        ),
      );

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(find.byType(SignOutUnsyncedChangesDialog), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      verifyNever(() => clearLocalUserData.execute());
      verifyNever(() => authClient.signOut());
    });

    testWidgets(
      'si el flush falla y el usuario confirma, cierra sesión de todos modos',
      (tester) async {
        when(
          () => syncUserData.execute(),
        ).thenThrow(const CloudSyncException('sin conexión'));

        await tester.pumpWidget(
          _buildSubject(
            exportUserData: exportUserData,
            deleteAccount: deleteAccount,
            clearLocalUserData: clearLocalUserData,
            syncUserData: syncUserData,
            authClient: authClient,
            subscriptionStatusProvider: subscriptionStatusProvider,
          ),
        );

        await tester.tap(find.text('Cerrar sesión'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cerrar sesión de todos modos'));
        await tester.pumpAndSettle();

        verify(() => clearLocalUserData.execute()).called(1);
        verify(() => authClient.signOut()).called(1);
      },
    );

    testWidgets('muestra el email de la cuenta autenticada', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          exportUserData: exportUserData,
          deleteAccount: deleteAccount,
          clearLocalUserData: clearLocalUserData,
          syncUserData: syncUserData,
          authClient: authClient,
          subscriptionStatusProvider: subscriptionStatusProvider,
        ),
      );

      expect(find.text('lector@example.com'), findsOneWidget);
    });

    testWidgets(
      'limita el ancho del contenido en pantallas anchas en vez de estirarlo',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(
            exportUserData: exportUserData,
            deleteAccount: deleteAccount,
            clearLocalUserData: clearLocalUserData,
            syncUserData: syncUserData,
            authClient: authClient,
            subscriptionStatusProvider: subscriptionStatusProvider,
          ),
        );

        final size = tester.getSize(
          find.byWidgetPredicate(
            (widget) =>
                widget is ConstrainedBox &&
                widget.constraints.maxWidth == kSettingsMaxContentWidth,
          ),
        );
        expect(size.width, kSettingsMaxContentWidth);
      },
    );

    testWidgets(
      'cuenta Free muestra "Free" y el botón de upgrade como primera sección',
      (tester) async {
        when(() => subscriptionStatusProvider.isSubscribed).thenReturn(false);

        await tester.pumpWidget(
          _buildSubject(
            exportUserData: exportUserData,
            deleteAccount: deleteAccount,
            clearLocalUserData: clearLocalUserData,
            syncUserData: syncUserData,
            authClient: authClient,
            subscriptionStatusProvider: subscriptionStatusProvider,
          ),
        );

        expect(find.text('Free'), findsOneWidget);
        expect(find.text('Obtener Premium'), findsOneWidget);
      },
    );

    testWidgets('cuenta Premium muestra "Premium" sin botón de upgrade', (
      tester,
    ) async {
      when(() => subscriptionStatusProvider.isSubscribed).thenReturn(true);

      await tester.pumpWidget(
        _buildSubject(
          exportUserData: exportUserData,
          deleteAccount: deleteAccount,
          clearLocalUserData: clearLocalUserData,
          syncUserData: syncUserData,
          authClient: authClient,
          subscriptionStatusProvider: subscriptionStatusProvider,
        ),
      );

      expect(find.text('PREMIUM'), findsOneWidget);
      expect(find.text('Obtener Premium'), findsNothing);
    });

    testWidgets('tocar "Obtener Premium" abre el paywall desde Ajustes', (
      tester,
    ) async {
      when(
        () => paywallLauncher.show(any(), trigger: any(named: 'trigger')),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(
        _buildSubject(
          exportUserData: exportUserData,
          deleteAccount: deleteAccount,
          clearLocalUserData: clearLocalUserData,
          syncUserData: syncUserData,
          authClient: authClient,
          subscriptionStatusProvider: subscriptionStatusProvider,
          paywallLauncher: paywallLauncher,
        ),
      );
      await tester.tap(find.text('Obtener Premium'));
      await tester.pumpAndSettle();

      verify(
        () => paywallLauncher.show(any(), trigger: PaywallTrigger.settings),
      ).called(1);
    });

    testWidgets(
      'completar la compra desde el paywall actualiza la sección a Premium',
      (tester) async {
        when(
          () => paywallLauncher.show(any(), trigger: any(named: 'trigger')),
        ).thenAnswer((_) async {
          when(() => subscriptionStatusProvider.isSubscribed).thenReturn(true);
          subscriptionChanges.add(true);
          return true;
        });

        await tester.pumpWidget(
          _buildSubject(
            exportUserData: exportUserData,
            deleteAccount: deleteAccount,
            clearLocalUserData: clearLocalUserData,
            syncUserData: syncUserData,
            authClient: authClient,
            subscriptionStatusProvider: subscriptionStatusProvider,
            paywallLauncher: paywallLauncher,
          ),
        );
        await tester.tap(find.text('Obtener Premium'));
        await tester.pumpAndSettle();

        expect(find.text('PREMIUM'), findsOneWidget);
        expect(find.text('Obtener Premium'), findsNothing);
      },
    );

    testWidgets(
      'usuario Free ve "Restaurar compras" y no ve "Administrar suscripción"',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            exportUserData: exportUserData,
            deleteAccount: deleteAccount,
            clearLocalUserData: clearLocalUserData,
            syncUserData: syncUserData,
            authClient: authClient,
            subscriptionStatusProvider: subscriptionStatusProvider,
          ),
        );

        expect(find.text('Restaurar compras'), findsOneWidget);
        expect(find.text('Administrar suscripción'), findsNothing);
      },
    );

    testWidgets(
      'usuario Premium ve "Administrar suscripción" y "Restaurar compras"',
      (tester) async {
        when(() => subscriptionStatusProvider.isSubscribed).thenReturn(true);

        await tester.pumpWidget(
          _buildSubject(
            exportUserData: exportUserData,
            deleteAccount: deleteAccount,
            clearLocalUserData: clearLocalUserData,
            syncUserData: syncUserData,
            authClient: authClient,
            subscriptionStatusProvider: subscriptionStatusProvider,
          ),
        );

        expect(find.text('Administrar suscripción'), findsOneWidget);
        expect(find.text('Restaurar compras'), findsOneWidget);
      },
    );

    testWidgets('"Administrar suscripción" abre la página de Apple', (
      tester,
    ) async {
      when(() => subscriptionStatusProvider.isSubscribed).thenReturn(true);

      await tester.pumpWidget(
        _buildSubject(
          exportUserData: exportUserData,
          deleteAccount: deleteAccount,
          clearLocalUserData: clearLocalUserData,
          syncUserData: syncUserData,
          authClient: authClient,
          subscriptionStatusProvider: subscriptionStatusProvider,
          externalLinkLauncher: externalLinkLauncher,
        ),
      );
      await tester.tap(find.text('Administrar suscripción'));
      await tester.pumpAndSettle();

      verify(
        () => externalLinkLauncher.open(AppConfig.manageSubscriptionsUrl),
      ).called(1);
    });

    testWidgets('restaurar compras con una suscripción vigente lo confirma', (
      tester,
    ) async {
      when(() => restorePurchases.execute()).thenAnswer((_) async => true);

      await tester.pumpWidget(
        _buildSubject(
          exportUserData: exportUserData,
          deleteAccount: deleteAccount,
          clearLocalUserData: clearLocalUserData,
          syncUserData: syncUserData,
          authClient: authClient,
          subscriptionStatusProvider: subscriptionStatusProvider,
          restorePurchases: restorePurchases,
        ),
      );
      await tester.tap(find.text('Restaurar compras'));
      await tester.pumpAndSettle();

      verify(() => restorePurchases.execute()).called(1);
      expect(find.text('Compras restauradas.'), findsOneWidget);
    });

    testWidgets(
      'restaurar compras sin ninguna suscripción informa que no hay nada '
      'que restaurar y el estado no cambia',
      (tester) async {
        when(() => restorePurchases.execute()).thenAnswer((_) async => false);

        await tester.pumpWidget(
          _buildSubject(
            exportUserData: exportUserData,
            deleteAccount: deleteAccount,
            clearLocalUserData: clearLocalUserData,
            syncUserData: syncUserData,
            authClient: authClient,
            subscriptionStatusProvider: subscriptionStatusProvider,
            restorePurchases: restorePurchases,
          ),
        );
        await tester.tap(find.text('Restaurar compras'));
        await tester.pumpAndSettle();

        expect(
          find.text('No encontramos compras para restaurar.'),
          findsOneWidget,
        );
        expect(find.text('Free'), findsOneWidget);
      },
    );

    testWidgets('si restaurar falla muestra el error localizado', (
      tester,
    ) async {
      when(() => restorePurchases.execute()).thenThrow(
        const SubscriptionException(AppErrorCode.restoreFailed, 'storeProblem'),
      );

      await tester.pumpWidget(
        _buildSubject(
          exportUserData: exportUserData,
          deleteAccount: deleteAccount,
          clearLocalUserData: clearLocalUserData,
          syncUserData: syncUserData,
          authClient: authClient,
          subscriptionStatusProvider: subscriptionStatusProvider,
          restorePurchases: restorePurchases,
        ),
      );
      await tester.tap(find.text('Restaurar compras'));
      await tester.pumpAndSettle();

      expect(
        find.text('No pudimos restaurar tus compras. Intenta de nuevo.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'eliminar cuenta como suscriptor muestra el aviso de la suscripción',
      (tester) async {
        when(() => subscriptionStatusProvider.isSubscribed).thenReturn(true);

        await tester.pumpWidget(
          _buildSubject(
            exportUserData: exportUserData,
            deleteAccount: deleteAccount,
            clearLocalUserData: clearLocalUserData,
            syncUserData: syncUserData,
            authClient: authClient,
            subscriptionStatusProvider: subscriptionStatusProvider,
            externalLinkLauncher: externalLinkLauncher,
          ),
        );
        await tester.tap(find.text('Eliminar cuenta'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('no cancela tu suscripción de Apple'),
          findsOneWidget,
        );
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Administrar suscripción'),
          ),
        );
        verify(
          () => externalLinkLauncher.open(AppConfig.manageSubscriptionsUrl),
        ).called(1);
      },
    );

    testWidgets(
      'eliminar cuenta sin suscripción no menciona ninguna suscripción',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            exportUserData: exportUserData,
            deleteAccount: deleteAccount,
            clearLocalUserData: clearLocalUserData,
            syncUserData: syncUserData,
            authClient: authClient,
            subscriptionStatusProvider: subscriptionStatusProvider,
          ),
        );
        await tester.tap(find.text('Eliminar cuenta'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.textContaining('suscripción'),
          ),
          findsNothing,
        );
      },
    );
  });
}
