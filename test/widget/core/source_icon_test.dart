import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:newsreader/core/widgets/chamfered_box.dart';
import 'package:newsreader/core/widgets/source_icon.dart';

void main() {
  group('SourceIcon', () {
    testWidgets('renders chamfered (not circular) with a placeholder '
        'initial when there is no iconUrl', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SourceIcon(iconUrl: null, name: 'Enfoque Global'),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ChamferedBox), findsOneWidget);
      expect(find.byType(ClipOval), findsNothing);
      expect(find.text('E'), findsOneWidget);
    });

    testWidgets('falls back to "?" when the name is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SourceIcon(iconUrl: null, name: '')),
        ),
      );
      await tester.pump();

      expect(find.text('?'), findsOneWidget);
    });
  });
}
