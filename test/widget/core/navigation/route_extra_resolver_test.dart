import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:newsreader/core/navigation/route_extra_resolver.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('con extra del tipo esperado, construye directo sin loading',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        RouteExtraResolver<String>(
          extra: 'hola',
          resolve: () async {
            fail('no debería llamarse resolve si extra ya viene tipado');
          },
          onNotFound: (_) {},
          builder: (context, value) => Text(value),
        ),
      ),
    );

    expect(find.text('hola'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
      'con extra nulo, muestra loading y luego el contenido resuelto',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        RouteExtraResolver<String>(
          extra: null,
          resolve: () async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            return 'resuelto';
          },
          onNotFound: (_) {},
          builder: (context, value) => Text(value),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('resuelto'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('si resolve() devuelve null, invoca onNotFound', (tester) async {
    var notFoundCalled = false;

    await tester.pumpWidget(
      wrap(
        RouteExtraResolver<String>(
          extra: null,
          resolve: () async => null,
          onNotFound: (_) => notFoundCalled = true,
          builder: (context, value) => Text(value),
        ),
      ),
    );

    // No se usa pumpAndSettle: el estado "no encontrado" se queda mostrando
    // un CircularProgressIndicator (animación indefinida) mientras espera la
    // navegación de onNotFound, así que nunca "settlea".
    await tester.pump();
    await tester.pump();

    expect(notFoundCalled, isTrue);
  });
}
