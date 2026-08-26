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
import 'package:newsreader/core/feed/feed_sync_trigger.dart';
import 'package:newsreader/core/navigation/route_extra_resolver.dart';
import 'package:newsreader/core/observability/observability_client.dart';
import 'package:newsreader/features/account/domain/usecases/delete_account.dart';
import 'package:newsreader/features/account/domain/usecases/export_user_data.dart';
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
import 'package:newsreader/features/settings/presentation/screens/settings_screen.dart';
import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/features/summaries/domain/usecases/resolve_summary_articles.dart';
import 'package:newsreader/features/summaries/presentation/cubit/summaries_cubit.dart';
import 'package:newsreader/features/summaries/presentation/screens/summaries_screen.dart';
import 'package:newsreader/features/summaries/presentation/screens/summary_detail_screen.dart';
import 'package:newsreader/l10n/app_localizations.dart';

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
      path: '/settings',
      builder: (context, state) => SettingsScreen(
        exportUserData: getIt<ExportUserData>(),
        deleteAccount: getIt<DeleteAccount>(),
      ),
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
          create: (_) => ImportOpmlCubit(
            getIt<ImportOpml>(),
            getIt<ObservabilityClient>(),
          ),
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
          observabilityClient: getIt<ObservabilityClient>(),
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
        builder: (context, summary) => SummaryDetailScreen(
          summary: summary,
          resolveSummaryArticles: getIt<ResolveSummaryArticles>(),
        ),
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

/// Índices de tabs cuyo contenido soporta búsqueda: Inbox, Favoritos y
/// Leídos (capability `article-search`), y Fuentes (capability
/// `source-search`). Resúmenes queda fuera de alcance.
const _searchableTabIndices = {0, 1, 2, 3};

class _ScaffoldWithNavBar extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const _ScaffoldWithNavBar({required this.navigationShell});

  @override
  State<_ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<_ScaffoldWithNavBar> {
  List<String> _titles(AppLocalizations l10n) => [
        l10n.navInbox,
        l10n.navFavorites,
        l10n.navArchive,
        l10n.navSources,
        l10n.navSummaries,
      ];

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
      case 3:
        context.read<SourcesCubit>().search(query);
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
    if (index == 0) context.read<InboxCubit>().loadArticles();
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: currentIndex == 3
                      ? l10n.navSearchHintSources
                      : l10n.navSearchHintArticles,
                  border: InputBorder.none,
                ),
                onChanged: (query) => _search(context, query),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/reevo_logo.png',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(_titles(l10n)[currentIndex]),
                ],
              ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.appTitle,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (getIt<AuthClient>().currentUserEmail case final email?) ...[
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.inbox_outlined),
            selectedIcon: const Icon(Icons.inbox),
            label: BlocBuilder<InboxCubit, InboxState>(
              builder: (context, state) {
                final count = state is InboxLoaded ? state.articles.length : 0;
                if (count == 0) return Text(l10n.navInbox);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.navInbox),
                    const SizedBox(width: 8),
                    Badge.count(count: count),
                  ],
                );
              },
            ),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.star_outline),
            selectedIcon: const Icon(Icons.star),
            label: Text(l10n.navFavorites),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.mark_email_read_outlined),
            selectedIcon: const Icon(Icons.mark_email_read),
            label: Text(l10n.navArchive),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.rss_feed_outlined),
            selectedIcon: const Icon(Icons.rss_feed),
            label: Text(l10n.navSources),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.auto_awesome_outlined),
            selectedIcon: const Icon(Icons.auto_awesome),
            label: Text(l10n.navSummaries),
          ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(l10n.navSettings),
            onTap: () => context.push('/settings'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.navSignOut),
            onTap: () async {
              // Se limpian los datos locales antes de cerrar sesión para
              // que la próxima cuenta que inicie sesión en este
              // dispositivo arranque sin datos de la cuenta anterior (evita
              // colisiones de `id` entre cuentas al sincronizar).
              await getIt<ClearLocalUserData>().execute();
              await getIt<AuthClient>().signOut();
            },
          ),
        ],
      ),
    );
  }
}
