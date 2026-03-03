import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:newsreader/features/inbox/domain/usecases/mark_article_as_read.dart';
import 'package:newsreader/features/inbox/presentation/cubit/inbox_cubit.dart';
import 'package:newsreader/features/inbox/presentation/screens/inbox_screen.dart';
import 'package:newsreader/features/reader/presentation/screens/reader_screen.dart';
import 'package:newsreader/features/sources/presentation/screens/add_source_screen.dart';
import 'package:newsreader/features/sources/presentation/screens/sources_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/article/:id',
      builder: (context, state) {
        final article = state.extra as Article;
        return ReaderScreen(
          article: article,
          markAsRead: GetIt.instance<MarkArticleAsRead>(),
        );
      },
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
              path: '/sources',
              builder: (context, state) => const SourcesScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) => const AddSourceScreen(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) =>
            navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: BlocBuilder<InboxCubit, InboxState>(
              builder: (context, state) {
                final count =
                    state is InboxLoaded ? state.articles.length : 0;
                if (count == 0) return const Icon(Icons.inbox_outlined);
                return Badge(
                  label: Text('$count'),
                  child: const Icon(Icons.inbox_outlined),
                );
              },
            ),
            selectedIcon: BlocBuilder<InboxCubit, InboxState>(
              builder: (context, state) {
                final count =
                    state is InboxLoaded ? state.articles.length : 0;
                if (count == 0) return const Icon(Icons.inbox);
                return Badge(
                  label: Text('$count'),
                  child: const Icon(Icons.inbox),
                );
              },
            ),
            label: 'Inbox',
          ),
          const NavigationDestination(
            icon: Icon(Icons.star_outline),
            selectedIcon: Icon(Icons.star),
            label: 'Favoritos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.rss_feed_outlined),
            selectedIcon: Icon(Icons.rss_feed),
            label: 'Fuentes',
          ),
        ],
      ),
    );
  }
}
