import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:newsreader/core/widgets/empty_detail_placeholder.dart';

void main() {
  testWidgets('muestra el icono, título y subtítulo dados', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyDetailPlaceholder(
            icon: Icons.article_outlined,
            title: 'Selecciona un artículo',
            subtitle: 'Elige un artículo de la lista para leerlo aquí.',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.article_outlined), findsOneWidget);
    expect(find.text('Selecciona un artículo'), findsOneWidget);
    expect(
      find.text('Elige un artículo de la lista para leerlo aquí.'),
      findsOneWidget,
    );
  });
}
