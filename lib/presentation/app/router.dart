import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/di/injection.dart';
import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/core/domain/repositories/article_repository.dart';
import 'package:newsreader/core/domain/repositories/source_repository.dart';
import 'package:newsreader/core/domain/repositories/summary_repository.dart';
import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/feed/feed_sync_trigger.dart';
import 'package:newsreader/core/navigation/route_extra_resolver.dart';
import 'package:newsreader/features/account/domain/usecases/delete_account.dart';
import 'package:newsreader/features/account/domain/usecases/export_user_data.dart';
import 'package:newsreader/features/account/presentation/widgets/delete_account_dialog.dart';
import 'package:newsreader/features/auth/presentation/cubit/login_cubit.dart';
import 'package:newsreader/features/auth/presentation/screens/login_screen.dart';
import 'package:newsreader/features/sync/domain/usecases/clear_local_user_data.dart';
import 'package:newsreader/features/sync/domain/usecases/sync_user_data.dart';
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

/// Convierte el stream de cambios de sesión de [AuthClient] en un
/// [Listenable], que es lo que espera `refreshListenable` de go_router para
/// reevaluar `redirect` cada vez que cambia el estado de auth (login,
/// logout, expiración de sesión) sin necesitar navegación manual.
class _AuthChangeNotifier extends ChangeNotifier {
  late final StreamSubscription<bool> _subscription;

  _AuthChangeNotifier(AuthClient authClient) {
    _subscription = authClient.authStateChanges.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: _AuthChangeNotifier(getIt<AuthClient>()),
  redirect: (context, state) {
    final isSignedIn = getIt<AuthClient>().isSignedIn;
    final isOnLoginScreen = state.matchedLocation == '/login';

    if (!isSignedIn && !isOnLoginScreen) return '/login';
    if (isSignedIn && isOnLoginScreen) return '/';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<LoginCubit>(),
        child: const LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/article/:id',
      builder: (context, state) => RouteExtraResolver<Article>(
        extra: state.extra,
        resolve: () =>
            getIt<ArticleRepository>().getArticleById(state.pathParameters['id']!),
        onNotFound: (context) => context.go('/'),
        builder: (context, article) => ReaderScreen(
          article: article,
          markAsRead: getIt<MarkArticleAsRead>(),
          toggleFavorite: getIt<ToggleFavorite>(),
        ),
      ),
      routes: [
        GoRoute(
          path: 'web',
          builder: (context, state) => RouteExtraResolver<Article>(
            extra: state.extra,
            resolve: () => getIt<ArticleRepository>()
                .getArticleById(state.pathParameters['id']!),
            onNotFound: (context) => context.go('/'),
            builder: (context, article) =>
                WebviewFlutterArticleWebView(url: article.articleUrl),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/sources/add',
      builder: (context, state) => const AddSourceScreen(),
    ),
    GoRoute(
      path: '/sources/import-opml',
      builder: (context, state) {
        final xmlContent = state.extra as String;
        return BlocProvider(
          create: (_) => ImportOpmlCubit(getIt<ImportOpml>()),
          child: ImportOpmlScreen(xmlContent: xmlContent),
        );
      },
    ),
    GoRoute(
      path: '/sources/:id',
      builder: (context, state) => RouteExtraResolver<NewsSource>(
        extra: state.extra,
        resolve: () =>
            getIt<SourceRepository>().getSourceById(state.pathParameters['id']!),
        onNotFound: (context) => context.go('/'),
        builder: (context, source) => SourceDetailScreen(
          source: source,
          getSourceArticles: getIt<GetSourceArticles>(),
          feedSyncTrigger: getIt<FeedSyncTrigger>(),
          syncUserData: getIt<SyncUserData>(),
          syncOnOpen: state.uri.queryParameters['justAdded'] == 'true',
        ),
      ),
    ),
    GoRoute(
      path: '/summaries/:date',
      builder: (context, state) => RouteExtraResolver<DailySummary>(
        extra: state.extra,
        resolve: () =>
            getIt<SummaryRepository>().getById(state.pathParameters['date']!),
        onNotFound: (context) => context.go('/'),
        builder: (context, summary) => SummaryDetailScreen(summary: summary),
      ),
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
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/summaries',
              builder: (context, state) => const SummariesScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

/// Índices de tabs cuyo contenido soporta búsqueda (Inbox, Favoritos,
/// Leídos), ver capability `article-search`. Fuentes y Resúmenes quedan
/// fuera de alcance.
const _searchableTabIndices = {0, 1, 2};

class _ScaffoldWithNavBar extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const _ScaffoldWithNavBar({required this.navigationShell});

  @override
  State<_ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<_ScaffoldWithNavBar> {
  static const _titles = ['Inbox', 'Favoritos', 'Leídos', 'Fuentes', 'Resúmenes'];

  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(BuildContext context, String query) {
    switch (widget.navigationShell.currentIndex) {
      case 0:
        context.read<InboxCubit>().search(query);
      case 1:
        context.read<FavoritesCubit>().search(query);
      case 2:
        context.read<ArchiveCubit>().search(query);
    }
  }

  void _toggleSearch(BuildContext context) {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _search(context, '');
      }
    });
  }

  void _onDestinationSelected(BuildContext context, int index) {
    if (_isSearching) _toggleSearch(context);
    if (index == 1) context.read<FavoritesCubit>().loadFavorites();
    if (index == 2) context.read<ArchiveCubit>().loadArchive();
    if (index == 3) context.read<SourcesCubit>().loadSources();
    if (index == 4) context.read<SummariesCubit>().loadSummaries();
    Navigator.pop(context);
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    final isSearchable = _searchableTabIndices.contains(currentIndex);
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar por título, fuente o autor...',
                  border: InputBorder.none,
                ),
                onChanged: (query) => _search(context, query),
              )
            : Text(_titles[currentIndex]),
        actions: [
          if (isSearchable)
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () => _toggleSearch(context),
            ),
        ],
      ),
      body: widget.navigationShell,
      drawer: NavigationDrawer(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _onDestinationSelected(context, index),
        children: [
          const DrawerHeader(
            child: Text(
              'Reevo',
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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: const Text('Exportar mis datos'),
            onTap: () => _exportUserData(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () async {
              // Se limpian los datos locales antes de cerrar sesión para
              // que la próxima cuenta que inicie sesión en este
              // dispositivo arranque sin datos de la cuenta anterior (evita
              // colisiones de `id` entre cuentas al sincronizar).
              await getIt<ClearLocalUserData>().execute();
              await getIt<AuthClient>().signOut();
            },
          ),
          ListTile(
            leading: Icon(
              Icons.delete_forever,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Eliminar cuenta',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _confirmDeleteAccount(context),
          ),
        ],
      ),
    );
  }

  Future<void> _exportUserData(BuildContext context) async {
    try {
      await getIt<ExportUserData>().execute();
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => DeleteAccountDialog(
        onConfirm: () => _deleteAccount(context),
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    try {
      await getIt<DeleteAccount>().execute();
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}
