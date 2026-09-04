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
  ExternalLinkLauncher launcher, {
  double? maxHeight,
}) {
  final content = BlocProvider<ArticleSummaryCubit>.value(
    value: cubit,
    child: ArticleSummarySheetContent(externalLinkLauncher: launcher),
  );
  return MaterialApp(
    locale: testLocale,
    localizationsDelegates: testLocalizationsDelegates,
    supportedLocales: testSupportedLocales,
    home: Scaffold(
      body: maxHeight == null
          ? content
          : Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(height: maxHeight, child: content),
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

    testWidgets(
        'estado Loaded con resumen largo en un alto acotado scrollea en vez '
        'de desbordar (regresión REEVO-PROD-8)', (tester) async {
      final summary = ArticleSummary(
        articleId: 'a1',
        summary: 'Párrafo largo. ' * 200,
        mentions: const [
          (type: MentionType.book, name: 'Libro A', imageUrl: null, link: 'https://a.example'),
          (type: MentionType.podcast, name: 'Podcast B', imageUrl: null, link: null),
        ],
        createdAt: DateTime(2024, 3, 15),
      );
      whenListen(cubit, const Stream<ArticleSummaryState>.empty(),
          initialState: ArticleSummaryLoaded(summary));

      // Mismo alto acotado que tendría un bottom sheet real -- antes del
      // fix, esto disparaba "A RenderFlex overflowed" (ver REEVO-PROD-8).
      await tester.pumpWidget(_buildSubject(cubit, launcher, maxHeight: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
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
        initialState: const ArticleSummaryLimitReached(dailyLimit: 25),
      );

      await tester.pumpWidget(_buildSubject(cubit, launcher));

      expect(
        find.text('Ya usaste tus 25 resúmenes de hoy'),
        findsOneWidget,
      );
      expect(find.text('Vuelven mañana a las 00:00.'), findsOneWidget);
    });

    testWidgets(
        'estado LimitReached sin suscripción muestra el límite gratis (2), no 25',
        (tester) async {
      whenListen(
        cubit,
        const Stream<ArticleSummaryState>.empty(),
        initialState: const ArticleSummaryLimitReached(dailyLimit: 2),
      );

      await tester.pumpWidget(_buildSubject(cubit, launcher));

      expect(
        find.text('Ya usaste tus 2 resúmenes de hoy'),
        findsOneWidget,
      );
    });
  });
}
