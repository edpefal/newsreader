import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/ai_usage_status.dart';
import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/repositories/ai_usage_repository.dart';
import 'package:newsreader/core/navigation/external_link_launcher.dart';
import 'package:newsreader/core/observability/telemetry_client.dart';
import 'package:newsreader/core/subscription/subscription_status_provider.dart';
import 'package:newsreader/features/article_summary/domain/usecases/generate_article_summary.dart';
import 'package:newsreader/features/article_summary/presentation/cubit/article_summary_cubit.dart';
import 'package:newsreader/features/inbox/domain/usecases/mark_article_as_read.dart';
import 'package:newsreader/features/reader/domain/usecases/toggle_favorite.dart';
import 'package:newsreader/features/reader/presentation/screens/reader_screen.dart';
import 'package:newsreader/features/reader/presentation/widgets/reading_progress_bar.dart';
import 'package:newsreader/presentation/theme/app_theme.dart';

import '../../../support/pump_localized_app.dart';

int _filledSegmentCount(WidgetTester tester) {
  final accentColor = AppTheme.light.extension<ReevoAccent>()!.unreadFavoriteAmber;
  return tester
      .widgetList<ColoredBox>(
        find.descendant(
          of: find.byType(ReadingProgressBar),
          matching: find.byType(ColoredBox),
        ),
      )
      .where((box) => box.color == accentColor)
      .length;
}

class MockMarkArticleAsRead extends Mock implements MarkArticleAsRead {}

class MockToggleFavorite extends Mock implements ToggleFavorite {}

class MockSubscriptionStatusProvider extends Mock
    implements SubscriptionStatusProvider {}

class MockExternalLinkLauncher extends Mock implements ExternalLinkLauncher {}

class MockGenerateArticleSummary extends Mock
    implements GenerateArticleSummary {}

class MockAiUsageRepository extends Mock implements AiUsageRepository {}

class MockTelemetryClient extends Mock implements TelemetryClient {}

AiUsageRepository _fakeAiUsageRepository() {
  final mock = MockAiUsageRepository();
  when(() => mock.getStatus()).thenAnswer(
    (_) async => const AiUsageStatus(summariesUsedToday: 0, dailyLimit: 25),
  );
  return mock;
}

Widget _buildSubject(
  Article article,
  MarkArticleAsRead markAsRead,
  ToggleFavorite toggleFavorite,
) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => ReaderScreen(
          article: article,
          markAsRead: markAsRead,
          toggleFavorite: toggleFavorite,
          subscriptionStatusProvider: MockSubscriptionStatusProvider(),
          createArticleSummaryCubit: () => ArticleSummaryCubit(
            MockGenerateArticleSummary(),
            _fakeAiUsageRepository(),
            MockTelemetryClient(),
          ),
          externalLinkLauncher: MockExternalLinkLauncher(),
        ),
      ),
    ],
  );
  return MaterialApp.router(
    theme: AppTheme.light,
    locale: testLocale,
    localizationsDelegates: testLocalizationsDelegates,
    supportedLocales: testSupportedLocales,
    routerConfig: router,
  );
}

void main() {
  late MockMarkArticleAsRead mockMarkAsRead;
  late MockToggleFavorite mockToggleFavorite;

  setUp(() {
    mockMarkAsRead = MockMarkArticleAsRead();
    mockToggleFavorite = MockToggleFavorite();
    when(() => mockMarkAsRead.execute(any())).thenAnswer((_) async {});
    when(() => mockToggleFavorite.execute(any())).thenAnswer((_) async {});
  });

  group('ReadingProgressBar en ReaderScreen', () {
    testWidgets(
        'no se muestra cuando el contenido cabe completamente en el viewport',
        (tester) async {
      final articleCorto = Article(
        id: 'short',
        sourceId: 's1',
        sourceName: 'Newsletter A',
        title: 'Artículo corto',
        excerpt: 'Un resumen breve.',
        publishedAt: DateTime(2024, 3, 15),
        articleUrl: 'https://example.com/article',
      );

      await tester.pumpWidget(
          _buildSubject(articleCorto, mockMarkAsRead, mockToggleFavorite));
      await tester.pumpAndSettle();

      expect(find.byType(ReadingProgressBar), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ReadingProgressBar),
          matching: find.byType(ColoredBox),
        ),
        findsNothing,
      );
    });

    testWidgets(
        'se muestra y avanza el progreso al hacer scroll en contenido largo',
        (tester) async {
      final articleLargo = Article(
        id: 'long',
        sourceId: 's1',
        sourceName: 'Newsletter A',
        title: 'Artículo largo',
        excerpt: 'Párrafo de contenido. ' * 300,
        publishedAt: DateTime(2024, 3, 15),
        articleUrl: 'https://example.com/article',
      );

      await tester.pumpWidget(
          _buildSubject(articleLargo, mockMarkAsRead, mockToggleFavorite));
      await tester.pumpAndSettle();

      expect(find.byType(ReadingProgressBar), findsOneWidget);
      expect(_filledSegmentCount(tester), 0);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -2000),
      );
      await tester.pump();

      expect(_filledSegmentCount(tester), greaterThan(0));
    });
  });
}
