import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:newsreader/core/ai/mention_enricher.dart';
import 'package:newsreader/features/article_summary/presentation/widgets/mention_card.dart';

Widget _buildSubject(EnrichedMention mention, {VoidCallback? onTap}) {
  return MaterialApp(
    home: Scaffold(body: MentionCard(mention: mention, onTap: onTap)),
  );
}

void main() {
  group('MentionCard', () {
    testWidgets('muestra el nombre de la mención', (tester) async {
      await tester.pumpWidget(_buildSubject(
        (type: MentionType.book, name: 'Project Hail Mary', imageUrl: null, link: null),
      ));

      expect(find.text('Project Hail Mary'), findsOneWidget);
    });

    testWidgets('mención sin imageUrl muestra un ícono placeholder, no imagen',
        (tester) async {
      await tester.pumpWidget(_buildSubject(
        (type: MentionType.podcast, name: 'Radiolab', imageUrl: null, link: null),
      ));

      expect(find.byIcon(Icons.podcasts_outlined), findsOneWidget);
    });

    testWidgets('mención sin imageUrl no es tappable (onTap null)',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(_buildSubject(
        (type: MentionType.music, name: 'Álbum', imageUrl: null, link: null),
        onTap: () => tapped = true,
      ));

      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.onTap, isNull);

      await tester.tap(find.byType(InkWell));
      expect(tapped, isFalse);
    });

    testWidgets('mención enriquecida es tappable y dispara onTap',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(_buildSubject(
        (
          type: MentionType.book,
          name: 'Project Hail Mary',
          imageUrl: 'https://books.example/cover.jpg',
          link: 'https://books.example/info',
        ),
        onTap: () => tapped = true,
      ));

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
