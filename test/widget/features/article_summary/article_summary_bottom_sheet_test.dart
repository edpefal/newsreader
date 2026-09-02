import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/ai/mention_enricher.dart';
import 'package:newsreader/core/domain/entities/article_summary.dart';
import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/navigation/external_link_launcher.dart';
import 'package:newsreader/features/article_summary/presentation/cubit/article_summary_cubit.dart';
import 'package:newsreader/features/article_summary/presentation/widgets/article_summary_bottom_sheet.dart';
import 'package:newsreader/features/article_summary/presentation/widgets/mention_card.dart';

import '../../../support/pump_localized_app.dart';

class MockArticleSummaryCubit extends MockCubit<ArticleSummaryState>
    implements ArticleSummaryCubit {}

class MockExternalLinkLauncher extends Mock implements ExternalLinkLauncher {}

Widget _buildSubject(
  ArticleSummaryCubit cubit,
  ExternalLinkLauncher launcher,
) {
  return MaterialApp(
    locale: testLocale,
    localizationsDelegates: testLocalizationsDelegates,
    supportedLocales: testSupportedLocales,
    home: Scaffold(
      body: BlocProvider<ArticleSummaryCubit>.value(
        value: cubit,
        child: ArticleSummarySheetContent(externalLinkLauncher: launcher),
      ),
    ),
  );
}

void main() {
  late MockArticleSummaryCubit cubit;
  late MockExternalLinkLauncher launcher;

  setUpAll(() {
    registerFallbackValue(const ArticleSummaryLoading());
  });

  setUp(() {
    cubit = MockArticleSummaryCubit();
    launcher = MockExternalLinkLauncher();
    when(() => launcher.open(any())).thenAnswer((_) async {});
  });

  group('ArticleSummarySheetContent', () {
    testWidgets('estado Loading muestra un progress indicator', (tester) async {
      whenListen(cubit, const Stream<ArticleSummaryState>.empty(),
          initialState: const ArticleSummaryLoading());

      await tester.pumpWidget(_buildSubject(cubit, launcher));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('estado Error muestra el texto localizado del error',
        (tester) async {
      whenListen(cubit, const Stream<ArticleSummaryState>.empty(),
          initialState: const ArticleSummaryError(AppErrorCode.generationFailed));

      await tester.pumpWidget(_buildSubject(cubit, launcher));

      expect(find.text('Algo salió mal. Intenta de nuevo.'), findsOneWidget);
    });

    testWidgets('estado Loaded muestra el texto del resumen', (tester) async {
      final summary = ArticleSummary(
        articleId: 'a1',
        summary: 'Este artículo trata sobre IA.',
        mentions: const [],
        createdAt: DateTime(2024, 3, 15),
      );
      whenListen(cubit, const Stream<ArticleSummaryState>.empty(),
          initialState: ArticleSummaryLoaded(summary));

      await tester.pumpWidget(_buildSubject(cubit, launcher));

      expect(find.text('Este artículo trata sobre IA.'), findsOneWidget);
      expect(find.byType(MentionCard), findsNothing);
    });

    testWidgets('estado Loaded con menciones muestra una MentionCard por cada una',
        (tester) async {
      final summary = ArticleSummary(
        articleId: 'a1',
        summary: 'Resumen',
        mentions: const [
          (
            type: MentionType.book,
            name: 'Project Hail Mary',
            imageUrl: 'https://books.example/cover.jpg',
            link: 'https://books.example/info',
          ),
          (type: MentionType.podcast, name: 'Radiolab', imageUrl: null, link: null),
        ],
        createdAt: DateTime(2024, 3, 15),
      );
      whenListen(cubit, const Stream<ArticleSummaryState>.empty(),
          initialState: ArticleSummaryLoaded(summary));

      await tester.pumpWidget(_buildSubject(cubit, launcher));

      expect(find.byType(MentionCard), findsNWidgets(2));
    });

    testWidgets('tocar una mención enriquecida abre el link con el launcher',
        (tester) async {
      final summary = ArticleSummary(
        articleId: 'a1',
        summary: 'Resumen',
        mentions: const [
          (
            type: MentionType.book,
            name: 'Project Hail Mary',
            imageUrl: 'https://books.example/cover.jpg',
            link: 'https://books.example/info',
          ),
        ],
        createdAt: DateTime(2024, 3, 15),
      );
      whenListen(cubit, const Stream<ArticleSummaryState>.empty(),
          initialState: ArticleSummaryLoaded(summary));

      await tester.pumpWidget(_buildSubject(cubit, launcher));
      await tester.tap(find.byType(MentionCard));
      await tester.pump();

      verify(() => launcher.open('https://books.example/info')).called(1);
    });

    testWidgets(
        'estado Loaded con muchos restantes igual muestra el indicador de uso',
        (tester) async {
      final summary = ArticleSummary(
        articleId: 'a1',
        summary: 'Resumen',
        mentions: const [],
        createdAt: DateTime(2024, 3, 15),
      );
      whenListen(
        cubit,
        const Stream<ArticleSummaryState>.empty(),
        initialState: ArticleSummaryLoaded(summary, remainingToday: 24),
      );

      await tester.pumpWidget(_buildSubject(cubit, launcher));

      expect(find.text('Quedan 24 hoy'), findsOneWidget);
    });

    testWidgets(
        'estado Loaded con pocos restantes muestra el indicador de uso',
        (tester) async {
      final summary = ArticleSummary(
        articleId: 'a1',
        summary: 'Resumen',
        mentions: const [],
        createdAt: DateTime(2024, 3, 15),
      );
      whenListen(
        cubit,
        const Stream<ArticleSummaryState>.empty(),
        initialState: ArticleSummaryLoaded(summary, remainingToday: 3),
      );

      await tester.pumpWidget(_buildSubject(cubit, launcher));

      expect(find.text('Quedan 3 hoy'), findsOneWidget);
    });

    testWidgets(
        'estado LimitReached muestra un estado neutro, sin color de error',
        (tester) async {
      whenListen(
        cubit,
        const Stream<ArticleSummaryState>.empty(),
        initialState: const ArticleSummaryLimitReached(),
      );

      await tester.pumpWidget(_buildSubject(cubit, launcher));

      expect(
        find.text('Ya usaste tus 25 resúmenes de hoy'),
        findsOneWidget,
      );
      expect(find.text('Vuelven mañana a las 00:00.'), findsOneWidget);
    });
  });
}
