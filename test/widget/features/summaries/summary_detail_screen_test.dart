import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/features/summaries/presentation/screens/summary_detail_screen.dart';

void main() {
  final tSummary = DailySummary(
    id: '2026-07-09',
    date: DateTime(2026, 7, 9),
    content: 'Este es el texto completo del resumen de hoy.',
    articleCount: 5,
    createdAt: DateTime(2026, 7, 9),
  );

  testWidgets('muestra el texto completo, fecha y cantidad de artículos',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: SummaryDetailScreen(summary: tSummary)),
    );

    expect(
      find.text('Este es el texto completo del resumen de hoy.'),
      findsOneWidget,
    );
    expect(find.text('5 artículos resumidos'), findsOneWidget);
    expect(find.textContaining('9 jul. 2026'), findsOneWidget);
  });
}
