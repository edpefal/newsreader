import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:newsreader/features/account/presentation/widgets/delete_account_dialog.dart';

import '../../../support/pump_localized_app.dart';

Widget _buildSubject({
  required VoidCallback onConfirm,
  bool showSubscriptionNotice = false,
  VoidCallback? onManageSubscription,
}) {
  return MaterialApp(
    locale: testLocale,
    localizationsDelegates: testLocalizationsDelegates,
    supportedLocales: testSupportedLocales,
    home: Material(
      child: DeleteAccountDialog(
        onConfirm: onConfirm,
        showSubscriptionNotice: showSubscriptionNotice,
        onManageSubscription: onManageSubscription,
      ),
    ),
  );
}

void main() {
  group('DeleteAccountDialog', () {
    testWidgets('muestra el mensaje de advertencia irreversible', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(onConfirm: () {}));

      expect(find.text('Eliminar cuenta'), findsWidgets);
      expect(find.textContaining('irreversible'), findsOneWidget);
    });

    testWidgets('llama onConfirm al pulsar Eliminar cuenta', (tester) async {
      var confirmed = false;
      await tester.pumpWidget(_buildSubject(onConfirm: () => confirmed = true));

      await tester.tap(find.widgetWithText(TextButton, 'Eliminar cuenta'));

      expect(confirmed, isTrue);
    });

    testWidgets('no llama onConfirm al pulsar Cancelar', (tester) async {
      var confirmed = false;
      await tester.pumpWidget(_buildSubject(onConfirm: () => confirmed = true));

      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));

      expect(confirmed, isFalse);
    });

    group('aviso de suscripción', () {
      const notice = 'Eliminar tu cuenta no cancela tu suscripción de Apple';

      testWidgets(
        'un usuario suscrito ve el aviso y la acción para gestionarla',
        (tester) async {
          await tester.pumpWidget(
            _buildSubject(
              onConfirm: () {},
              showSubscriptionNotice: true,
              onManageSubscription: () {},
            ),
          );

          expect(find.textContaining(notice), findsOneWidget);
          expect(find.text('Administrar suscripción'), findsOneWidget);
        },
      );

      testWidgets('un usuario sin suscripción no ve ninguna mención', (
        tester,
      ) async {
        await tester.pumpWidget(_buildSubject(onConfirm: () {}));

        expect(find.textContaining('suscripción'), findsNothing);
        expect(find.text('Administrar suscripción'), findsNothing);
      });

      testWidgets('"Administrar suscripción" llama a la acción', (
        tester,
      ) async {
        var opened = false;
        await tester.pumpWidget(
          _buildSubject(
            onConfirm: () {},
            showSubscriptionNotice: true,
            onManageSubscription: () => opened = true,
          ),
        );

        await tester.tap(find.text('Administrar suscripción'));

        expect(opened, isTrue);
      });

      testWidgets('el aviso no bloquea el borrado', (tester) async {
        var confirmed = false;
        await tester.pumpWidget(
          _buildSubject(
            onConfirm: () => confirmed = true,
            showSubscriptionNotice: true,
            onManageSubscription: () {},
          ),
        );

        await tester.tap(find.widgetWithText(TextButton, 'Eliminar cuenta'));

        expect(confirmed, isTrue);
      });
    });
  });
}
