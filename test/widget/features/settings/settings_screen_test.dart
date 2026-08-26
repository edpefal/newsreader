import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/auth/auth_client.dart';
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

class MockSettingsBox extends Mock implements Box<dynamic> {}

Widget _buildSubject({
  required ExportUserData exportUserData,
  required DeleteAccount deleteAccount,
  required ClearLocalUserData clearLocalUserData,
  required AuthClient authClient,
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

    setUp(() {
      exportUserData = MockExportUserData();
      deleteAccount = MockDeleteAccount();
      clearLocalUserData = MockClearLocalUserData();
      authClient = MockAuthClient();
      when(() => clearLocalUserData.execute()).thenAnswer((_) async {});
      when(() => authClient.signOut()).thenAnswer((_) async {});
    });

    testWidgets('muestra la opción de cerrar sesión', (tester) async {
      await tester.pumpWidget(_buildSubject(
        exportUserData: exportUserData,
        deleteAccount: deleteAccount,
        clearLocalUserData: clearLocalUserData,
        authClient: authClient,
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
      ));

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      verify(() => clearLocalUserData.execute()).called(1);
      verify(() => authClient.signOut()).called(1);
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
  });
}
