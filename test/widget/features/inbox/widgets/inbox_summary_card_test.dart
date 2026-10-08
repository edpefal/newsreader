import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/domain/entities/summary_source_block.dart';
import 'package:newsreader/features/inbox/presentation/widgets/inbox_summary_card.dart';
import 'package:newsreader/presentation/theme/app_theme.dart';

import '../../../../support/pump_localized_app.dart';

DailySummary _summary({int sources = 5, bool withBlocks = true}) =>
    DailySummary(
      id: 'summary-1',
      date: DateTime(2026, 10, 7).toUtc(),
      content: 'contenido',
      articleCount: 12,
      createdAt: DateTime(2026, 10, 7).toUtc(),
      sourceBlocks: withBlocks
          ? [
              for (var i = 0; i < sources; i++)
                SummarySourceBlock(
                  sourceId: 's$i',
                  sourceName: '${String.fromCharCode(65 + i)}-fuente',
                  articleIds: ['a$i'],
                ),
            ]
          : null,
    );

Widget _wrap(
  Widget child, {
  ThemeData? theme,
}) =>
    MaterialApp(
      theme: theme ?? AppTheme.light,
      locale: testLocale,
      localizationsDelegates: testLocalizationsDelegates,
      supportedLocales: testSupportedLocales,
      home: Scaffold(body: child),
    );

InboxSummaryCard _card({
  DailySummary? summary,
  bool isSelected = false,
  VoidCallback? onTap,
  VoidCallback? onDismissed,
}) =>
    InboxSummaryCard(
      summary: summary ?? _summary(),
      isSelected: isSelected,
      onTap: onTap ?? () {},
      onDismissed: onDismissed ?? () {},
    );

void main() {
  testWidgets(
      'muestra título, conteo de artículos y fuentes, 3 avatares y +N',
      (tester) async {
    await tester.pumpWidget(_wrap(_card()));

    expect(find.text('Resumen de hoy'), findsOneWidget);
    expect(find.text('12 artículos · 5 fuentes'), findsOneWidget);
    expect(find.text('Leer'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsNothing);
    expect(find.text('+2'), findsOneWidget);
  });

  testWidgets('con 3 fuentes o menos no muestra el indicador +N',
      (tester) async {
    await tester.pumpWidget(_wrap(_card(summary: _summary(sources: 2))));

    expect(find.textContaining('+'), findsNothing);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets(
      'sin sourceBlocks muestra solo título y conteo, sin avatares ni fuentes',
      (tester) async {
    await tester.pumpWidget(_wrap(_card(summary: _summary(withBlocks: false))));

    expect(find.text('Resumen de hoy'), findsOneWidget);
    expect(find.text('12 artículos'), findsOneWidget);
    expect(find.textContaining('fuentes'), findsNothing);
    expect(find.textContaining('+'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el relleno es el acento óxido del tema, en claro y en oscuro',
      (tester) async {
    for (final (theme, accent) in [
      (AppTheme.light, ReevoAccent.light),
      (AppTheme.dark, ReevoAccent.dark),
    ]) {
      await tester.pumpWidget(_wrap(_card(), theme: theme));
      // El cambio de tema de MaterialApp se anima.
      await tester.pumpAndSettle();
      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(InboxSummaryCard),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, accent.unreadFavoriteAccent);
    }
  });

  testWidgets('estado seleccionado: CTA "Abierto" y borde de 2px', (tester) async {
    await tester.pumpWidget(_wrap(_card(isSelected: true)));

    expect(find.text('Abierto'), findsOneWidget);
    expect(find.text('Leer'), findsNothing);
    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(InboxSummaryCard),
            matching: find.byType(Material),
          )
          .first,
    );
    final shape = material.shape! as RoundedRectangleBorder;
    expect(shape.side.width, 2);
    expect(shape.side.color, AppTheme.light.colorScheme.onSurface);
  });

  testWidgets('sin seleccionar no tiene borde', (tester) async {
    await tester.pumpWidget(_wrap(_card()));

    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(InboxSummaryCard),
            matching: find.byType(Material),
          )
          .first,
    );
    expect((material.shape! as RoundedRectangleBorder).side, BorderSide.none);
  });

  testWidgets('tocar la tarjeta invoca onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(_card(onTap: () => taps++)));

    await tester.tap(find.text('Resumen de hoy'));

    expect(taps, 1);
  });

  testWidgets('swipe de derecha a izquierda descarta', (tester) async {
    var dismissed = 0;
    late StateSetter setOuter;
    var visible = true;
    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) {
            setOuter = setState;
            return visible
                ? _card(
                    onDismissed: () {
                      dismissed++;
                      setOuter(() => visible = false);
                    },
                  )
                : const SizedBox();
          },
        ),
      ),
    );

    await tester.drag(find.byType(InboxSummaryCard), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(dismissed, 1);
    expect(find.byType(InboxSummaryCard), findsNothing);
  });

  testWidgets('swipe de izquierda a derecha no descarta', (tester) async {
    var dismissed = 0;
    await tester.pumpWidget(_wrap(_card(onDismissed: () => dismissed++)));

    await tester.drag(find.byType(InboxSummaryCard), const Offset(600, 0));
    await tester.pumpAndSettle();

    expect(dismissed, 0);
    expect(find.byType(InboxSummaryCard), findsOneWidget);
  });

  testWidgets(
      'accesibilidad: un único nodo con etiqueta, acción "Descartar" y estado seleccionado',
      (tester) async {
    final handle = tester.ensureSemantics();
    var dismissed = 0;
    await tester.pumpWidget(
      _wrap(_card(isSelected: true, onDismissed: () => dismissed++)),
    );

    final node = tester.getSemantics(find.byType(InboxSummaryCard));
    final data = node.getSemanticsData();
    expect(data.label, 'Resumen de hoy, 12 artículos · 5 fuentes, Abierto');
    expect(
      node,
      isSemantics(isSelected: true, isButton: true, hasTapAction: true),
    );
    expect(data.hasAction(SemanticsAction.customAction), isTrue);

    final actionId = data.customSemanticsActionIds!.single;
    final action = CustomSemanticsAction.getAction(actionId)!;
    expect(action.label, 'Descartar');

    // `rootPipelineOwner` no es el dueño de la semántica del árbol de test.
    // ignore: deprecated_member_use
    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      node.id,
      SemanticsAction.customAction,
      actionId,
    );
    expect(dismissed, 1);
    handle.dispose();
  });
}
