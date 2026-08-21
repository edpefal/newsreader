import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:newsreader/features/account/presentation/widgets/delete_account_dialog.dart';

import '../../../support/pump_localized_app.dart';

Widget _buildSubject({required VoidCallback onConfirm}) {
  return MaterialApp(
    locale: testLocale,
    localizationsDelegates: testLocalizationsDelegates,
    supportedLocales: testSupportedLocales,
    home: Material(child: DeleteAccountDialog(onConfirm: onConfirm)),
  );
}

void main() {
  group('DeleteAccountDialog', () {
    testWidgets('muestra el mensaje de advertencia irreversible',
        (tester) async {
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
  });
}
