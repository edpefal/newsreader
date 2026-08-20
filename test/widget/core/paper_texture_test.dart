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
  });
}
