import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/subscription/subscription_status_provider.dart';
import 'package:newsreader/features/account/domain/usecases/delete_account.dart';
import 'package:newsreader/features/account/domain/usecases/export_user_data.dart';
import 'package:newsreader/features/settings/presentation/screens/settings_screen.dart';
import 'package:newsreader/features/sync/domain/usecases/clear_local_user_data.dart';
import 'package:newsreader/presentation/theme/theme_cubit.dart';

import '../../../support/pump_localized_app.dart';

class MockExportUserData extends Mock implements ExportUserData {}

class MockDeleteAccount extends Mock implements DeleteAccount {}

class MockClearLocalUserData extends Mock implements ClearLocalUserData {}

class MockAuthClient extends Mock implements AuthClient {}

class MockSubscriptionStatusProvider extends Mock
    implements SubscriptionStatusProvider {}

class MockSettingsBox extends Mock implements Box<dynamic> {}

Widget _buildSubject({
  required ExportUserData exportUserData,
  required DeleteAccount deleteAccount,
  required ClearLocalUserData clearLocalUserData,
  required AuthClient authClient,
  required SubscriptionStatusProvider subscriptionStatusProvider,
}) {
  final settingsBox = MockSettingsBox();
  when(() => settingsBox.get(any(), defaultValue: any(named: 'defaultValue')))
      .thenAnswer((invocation) => invocation.namedArguments[#defaultValue]);
  when(() => settingsBox.put(any(), any())).thenAnswer((_) async {});

  return MaterialApp(
    locale: testLocale,
    localizationsDelegates: testLocalizationsDelegates,
    supportedLocales: testSupportedLocales,
    home: BlocProvider<ThemeCubit>(
      create: (_) => ThemeCubit(settingsBox),
      child: SettingsScreen(
        exportUserData: exportUserData,
        deleteAccount: deleteAccount,
        clearLocalUserData: clearLocalUserData,
        authClient: authClient,
        subscriptionStatusProvider: subscriptionStatusProvider,
      ),
    ),
  );
}

void main() {
  group('SettingsScreen', () {
    late MockExportUserData exportUserData;
    late MockDeleteAccount deleteAccount;
    late MockClearLocalUserData clearLocalUserData;
    late MockAuthClient authClient;
    late MockSubscriptionStatusProvider subscriptionStatusProvider;

    setUp(() {
      exportUserData = MockExportUserData();
      deleteAccount = MockDeleteAccount();
      clearLocalUserData = MockClearLocalUserData();
      authClient = MockAuthClient();
      subscriptionStatusProvider = MockSubscriptionStatusProvider();
      when(() => clearLocalUserData.execute()).thenAnswer((_) async {});
      when(() => authClient.signOut()).thenAnswer((_) async {});
      when(() => authClient.currentUserEmail)
          .thenReturn('lector@example.com');
      when(() => subscriptionStatusProvider.isSubscribed).thenReturn(false);
    });

    testWidgets('muestra la opción de cerrar sesión', (tester) async {
      await tester.pumpWidget(_buildSubject(
        exportUserData: exportUserData,
        deleteAccount: deleteAccount,
        clearLocalUserData: clearLocalUserData,
        authClient: authClient,
        subscriptionStatusProvider: subscriptionStatusProvider,
      ));

      expect(find.text('Cerrar sesión'), findsOneWidget);
    });

    testWidgets(
        'tocar "Cerrar sesión" limpia los datos locales y cierra sesión',
        (tester) async {
      await tester.pumpWidget(_buildSubject(
        exportUserData: exportUserData,
        deleteAccount: deleteAccount,
        clearLocalUserData: clearLocalUserData,
        authClient: authClient,
        subscriptionStatusProvider: subscriptionStatusProvider,
      ));

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      verify(() => clearLocalUserData.execute()).called(1);
      verify(() => authClient.signOut()).called(1);
    });

    testWidgets('muestra el email de la cuenta autenticada', (tester) async {
      await tester.pumpWidget(_buildSubject(
        exportUserData: exportUserData,
        deleteAccount: deleteAccount,
        clearLocalUserData: clearLocalUserData,
        authClient: authClient,
        subscriptionStatusProvider: subscriptionStatusProvider,
      ));

      expect(find.text('lector@example.com'), findsOneWidget);
    });

    testWidgets(
        'limita el ancho del contenido en pantallas anchas en vez de estirarlo',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildSubject(
        exportUserData: exportUserData,
        deleteAccount: deleteAccount,
        clearLocalUserData: clearLocalUserData,
        authClient: authClient,
        subscriptionStatusProvider: subscriptionStatusProvider,
      ));

      final size = tester.getSize(
        find.byWidgetPredicate(
          (widget) =>
              widget is ConstrainedBox &&
              widget.constraints.maxWidth == kSettingsMaxContentWidth,
        ),
      );
      expect(size.width, kSettingsMaxContentWidth);
    });

    testWidgets(
        'cuenta Free muestra "Free" y el botón de upgrade como primera sección',
        (tester) async {
      when(() => subscriptionStatusProvider.isSubscribed).thenReturn(false);

      await tester.pumpWidget(_buildSubject(
        exportUserData: exportUserData,
        deleteAccount: deleteAccount,
        clearLocalUserData: clearLocalUserData,
        authClient: authClient,
        subscriptionStatusProvider: subscriptionStatusProvider,
      ));

      expect(find.text('Free'), findsOneWidget);
      expect(find.text('Obtener Premium'), findsOneWidget);
    });

    testWidgets('cuenta Premium muestra "Premium" sin botón de upgrade',
        (tester) async {
      when(() => subscriptionStatusProvider.isSubscribed).thenReturn(true);

      await tester.pumpWidget(_buildSubject(
        exportUserData: exportUserData,
        deleteAccount: deleteAccount,
        clearLocalUserData: clearLocalUserData,
        authClient: authClient,
        subscriptionStatusProvider: subscriptionStatusProvider,
      ));

      expect(find.text('Premium'), findsOneWidget);
      expect(find.text('Obtener Premium'), findsNothing);
    });

    testWidgets('tocar "Obtener Premium" dispara el paywall', (tester) async {
      when(() => subscriptionStatusProvider.isSubscribed).thenReturn(false);
      when(
        () => subscriptionStatusProvider.showPaywall(
          onSubscribed: any(named: 'onSubscribed'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(_buildSubject(
        exportUserData: exportUserData,
        deleteAccount: deleteAccount,
        clearLocalUserData: clearLocalUserData,
        authClient: authClient,
        subscriptionStatusProvider: subscriptionStatusProvider,
      ));
      await tester.tap(find.text('Obtener Premium'));
      await tester.pumpAndSettle();

      verify(
        () => subscriptionStatusProvider.showPaywall(
          onSubscribed: any(named: 'onSubscribed'),
        ),
      ).called(1);
    });

    testWidgets(
        'completar la compra desde el paywall actualiza la sección a Premium',
        (tester) async {
      when(() => subscriptionStatusProvider.isSubscribed).thenReturn(false);
      when(
        () => subscriptionStatusProvider.showPaywall(
          onSubscribed: any(named: 'onSubscribed'),
        ),
      ).thenAnswer((invocation) async {
        when(() => subscriptionStatusProvider.isSubscribed).thenReturn(true);
        final onSubscribed = invocation.namedArguments[#onSubscribed]
            as Future<void> Function();
        await onSubscribed();
      });

      await tester.pumpWidget(_buildSubject(
        exportUserData: exportUserData,
        deleteAccount: deleteAccount,
        clearLocalUserData: clearLocalUserData,
        authClient: authClient,
        subscriptionStatusProvider: subscriptionStatusProvider,
      ));
      await tester.tap(find.text('Obtener Premium'));
      await tester.pumpAndSettle();

      expect(find.text('Premium'), findsOneWidget);
      expect(find.text('Obtener Premium'), findsNothing);
    });
  });
}
