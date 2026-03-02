import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:newsreader/features/sources/presentation/widgets/delete_source_dialog.dart';

Widget _buildSubject({
  String sourceName = 'Newsletter A',
  required VoidCallback onConfirm,
}) {
  return MaterialApp(
    home: Material(
      child: DeleteSourceDialog(
        sourceName: sourceName,
        onConfirm: onConfirm,
      ),
    ),
  );
}

void main() {
  group('DeleteSourceDialog', () {
    testWidgets('muestra el nombre de la fuente en el mensaje', (tester) async {
      await tester.pumpWidget(
        _buildSubject(sourceName: 'Mi Newsletter', onConfirm: () {}),
      );

      expect(find.textContaining('Mi Newsletter'), findsOneWidget);
      expect(
        find.textContaining(
          'También se eliminarán sus artículos no guardados como favoritos.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('llama onConfirm al pulsar Eliminar', (tester) async {
      var confirmed = false;
      await tester.pumpWidget(
        _buildSubject(onConfirm: () => confirmed = true),
      );

      await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));

      expect(confirmed, isTrue);
    });

    testWidgets('no llama onConfirm al pulsar Cancelar', (tester) async {
      var confirmed = false;
      await tester.pumpWidget(
        _buildSubject(onConfirm: () => confirmed = true),
      );

      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));

      expect(confirmed, isFalse);
    });
  });
}
