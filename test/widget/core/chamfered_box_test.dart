import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:newsreader/core/widgets/chamfered_box.dart';

void main() {
  group('ChamferedBox', () {
    testWidgets('renders its child with the default chamfer', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChamferedBox(
            child: SizedBox(width: 40, height: 40, child: ColoredBox(
              color: Colors.black,
            )),
          ),
        ),
      );

      expect(find.byType(ChamferedBox), findsOneWidget);
      expect(find.byType(ClipPath), findsOneWidget);
    });

    testWidgets('renders with a custom chamferSize', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChamferedBox(
            chamferSize: 20,
            child: SizedBox(width: 60, height: 60),
          ),
        ),
      );

      expect(find.byType(ChamferedBox), findsOneWidget);
    });

    testWidgets('renders with each supported corner', (tester) async {
      for (final corner in ChamferCorner.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: ChamferedBox(
              corner: corner,
              child: const SizedBox(width: 40, height: 40),
            ),
          ),
        );

        expect(find.byType(ChamferedBox), findsOneWidget);
      }
    });
  });
}
