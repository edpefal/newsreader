import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:newsreader/core/widgets/paper_texture.dart';

void main() {
  group('PaperBackground', () {
    testWidgets('renders its child without altering its layout', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PaperBackground(
            child: SizedBox(
              width: 200,
              height: 100,
              child: Center(child: Text('contenido')),
            ),
          ),
        ),
      );

      expect(find.text('contenido'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      final sizedBoxFinder = find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.width == 200,
      );
      final size = tester.getSize(sizedBoxFinder);
      expect(size, const Size(200, 100));
    });

    Color dotColorFor(WidgetTester tester) {
      final customPaint = tester.widget<CustomPaint>(
        find.byKey(const Key('paperTextureCustomPaint')),
      );
      return (customPaint.painter as dynamic).dotColor as Color;
    }

    // Dos `testWidgets` separados en vez de dos `pumpWidget` en el mismo
    // test: reusar el mismo `tester` con dos MaterialApp de brightness
    // distinto dentro de un único test no siempre re-resuelve el Theme
    // heredado (comportamiento del binding de test, no del widget bajo
    // prueba), así que cada brightness se verifica en aislamiento.
    testWidgets('usa puntos negros de bajo alpha en light', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          home: const PaperBackground(child: SizedBox.shrink()),
        ),
      );

      expect(dotColorFor(tester), const Color(0x08000000));
    });

    testWidgets('usa puntos claros de bajo alpha en dark', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: const PaperBackground(child: SizedBox.shrink()),
        ),
      );

      expect(dotColorFor(tester), const Color(0x14FFFFFF));
    });
  });
}
