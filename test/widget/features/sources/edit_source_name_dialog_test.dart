import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:newsreader/features/sources/presentation/widgets/edit_source_name_dialog.dart';

Widget _buildSubject({
  String initialName = 'Newsletter A',
  required void Function(String) onSave,
}) {
  return MaterialApp(
    home: Material(
      child: EditSourceNameDialog(
        initialName: initialName,
        onSave: onSave,
      ),
    ),
  );
}

void main() {
  group('EditSourceNameDialog', () {
    testWidgets('muestra el nombre actual en el campo de texto', (tester) async {
      await tester.pumpWidget(
        _buildSubject(initialName: 'Mi Newsletter', onSave: (_) {}),
      );

      expect(find.widgetWithText(TextField, 'Mi Newsletter'), findsOneWidget);
    });

    testWidgets('botón Guardar deshabilitado cuando el campo está vacío',
        (tester) async {
      await tester.pumpWidget(_buildSubject(onSave: (_) {}));

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Guardar'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('botón Guardar habilitado cuando hay texto', (tester) async {
      await tester.pumpWidget(_buildSubject(onSave: (_) {}));

      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Guardar'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('llama onSave con el nombre recortado al guardar',
        (tester) async {
      String? saved;
      await tester.pumpWidget(
        _buildSubject(onSave: (name) => saved = name),
      );

      await tester.enterText(find.byType(TextField), '  Nuevo Nombre  ');
      await tester.pump();
      await tester.tap(find.widgetWithText(TextButton, 'Guardar'));

      expect(saved, 'Nuevo Nombre');
    });

    testWidgets('no llama onSave al pulsar Cancelar', (tester) async {
      var called = false;
      await tester.pumpWidget(
        _buildSubject(onSave: (_) => called = true),
      );

      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));

      expect(called, isFalse);
    });
  });
}
