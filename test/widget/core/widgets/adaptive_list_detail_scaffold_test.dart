import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:newsreader/core/widgets/adaptive_list_detail_scaffold.dart';

void main() {
  testWidgets('muestra la lista y el detalle simultáneamente', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdaptiveListDetailScaffold(
            list: Text('Lista'),
            detail: Text('Detalle'),
          ),
        ),
      ),
    );

    expect(find.text('Lista'), findsOneWidget);
    expect(find.text('Detalle'), findsOneWidget);
  });

  testWidgets('el panel de lista respeta el ancho fijo configurado', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdaptiveListDetailScaffold(
            listWidth: 300,
            list: ColoredBox(key: Key('list'), color: Colors.red),
            detail: ColoredBox(key: Key('detail'), color: Colors.blue),
          ),
        ),
      ),
    );

    final listSize = tester.getSize(find.byKey(const Key('list')));
    expect(listSize.width, 300);
  });
}
