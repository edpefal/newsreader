import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:newsreader/core/di/injection.dart';
import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/core/widgets/webview_flutter_article_web_view.dart';
import 'package:newsreader/features/archive/presentation/screens/archive_screen.dart';
import 'package:newsreader/features/archive/presentation/cubit/archive_cubit.dart';
import 'package:newsreader/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:newsreader/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:newsreader/features/inbox/domain/usecases/mark_article_as_read.dart';
import 'package:newsreader/features/inbox/presentation/cubit/inbox_cubit.dart';
import 'package:newsreader/features/inbox/presentation/screens/inbox_screen.dart';
import 'package:newsreader/features/reader/domain/usecases/toggle_favorite.dart';
import 'package:newsreader/features/reader/presentation/screens/reader_screen.dart';
import 'package:newsreader/features/sources/domain/usecases/get_source_articles.dart';
import 'package:newsreader/features/sources/domain/usecases/import_opml.dart';
import 'package:newsreader/features/sources/presentation/cubit/import_opml_cubit.dart';
import 'package:newsreader/features/sources/presentation/cubit/sources_cubit.dart';
import 'package:newsreader/features/sources/presentation/screens/add_source_screen.dart';
import 'package:newsreader/features/sources/presentation/screens/import_opml_screen.dart';
import 'package:newsreader/features/sources/presentation/screens/source_detail_screen.dart';
import 'package:newsreader/features/sources/presentation/screens/sources_screen.dart';
import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/features/summaries/presentation/cubit/summaries_cubit.dart';
import 'package:newsreader/features/summaries/presentation/screens/summaries_screen.dart';
import 'package:newsreader/features/summaries/presentation/screens/summary_detail_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/article/:id',
      builder: (context, state) {
        final article = state.extra as Article;
        return ReaderScreen(
          article: article,
          markAsRead: getIt<MarkArticleAsRead>(),
          toggleFavorite: getIt<ToggleFavorite>(),
        );
      },
      routes: [
        GoRoute(
          path: 'web',
          builder: (context, state) {
            final article = state.extra as Article;
            return WebviewFlutterArticleWebView(url: article.articleUrl);
          },
        ),
      ],
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _ScaffoldWithNavBar(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const InboxScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/favorites',
              builder: (context, state) => const FavoritesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/archive',
              builder: (context, state) => const ArchiveScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/sources',
              builder: (context, state) => const SourcesScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) => const AddSourceScreen(),
                ),
                GoRoute(
                  path: 'import-opml',
                  builder: (context, state) {
                    final xmlContent = state.extra as String;
                    return BlocProvider(
                      create: (_) => ImportOpmlCubit(getIt<ImportOpml>()),
                      child: ImportOpmlScreen(xmlContent: xmlContent),
                    );
                  },
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) {
                    final source = state.extra as NewsSource;
                    return SourceDetailScreen(
                      source: source,
                      getSourceArticles: getIt<GetSourceArticles>(),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/summaries',
              builder: (context, state) => const SummariesScreen(),
              routes: [
                GoRoute(
                  path: ':date',
                  builder: (context, state) {
                    final summary = state.extra as DailySummary;
                    return SummaryDetailScreen(summary: summary);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

class _ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _ScaffoldWithNavBar({required this.navigationShell});

  static const _titles = ['Inbox', 'Favoritos', 'Leídos', 'Fuentes', 'Resúmenes'];

  void _onDestinationSelected(BuildContext context, int index) {
    if (index == 1) context.read<FavoritesCubit>().loadFavorites();
    if (index == 2) context.read<ArchiveCubit>().loadArchive();
    if (index == 3) context.read<SourcesCubit>().loadSources();
    if (index == 4) context.read<SummariesCubit>().loadSummaries();
    Navigator.pop(context);
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[navigationShell.currentIndex])),
      body: navigationShell,
      drawer: NavigationDrawer(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => _onDestinationSelected(context, index),
        children: [
          const DrawerHeader(
            child: Text(
              'Newsletter Hub',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          NavigationDrawerDestination(
            icon: BlocBuilder<InboxCubit, InboxState>(
              builder: (context, state) {
                final count = state is InboxLoaded ? state.articles.length : 0;
                if (count == 0) return const Icon(Icons.inbox_outlined);
                return Badge(
                  label: Text('$count'),
                  child: const Icon(Icons.inbox_outlined),
                );
              },
            ),
            selectedIcon: BlocBuilder<InboxCubit, InboxState>(
              builder: (context, state) {
                final count = state is InboxLoaded ? state.articles.length : 0;
                if (count == 0) return const Icon(Icons.inbox);
                return Badge(
                  label: Text('$count'),
                  child: const Icon(Icons.inbox),
                );
              },
            ),
            label: const Text('Inbox'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.star_outline),
            selectedIcon: Icon(Icons.star),
            label: Text('Favoritos'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.archive_outlined),
            selectedIcon: Icon(Icons.archive),
            label: Text('Leídos'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.rss_feed_outlined),
            selectedIcon: Icon(Icons.rss_feed),
            label: Text('Fuentes'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: Text('Resúmenes'),
          ),
        ],
      ),
    );
  }
}
