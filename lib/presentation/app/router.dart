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
import 'package:newsreader/core/utils/window_size_class.dart';
import 'package:newsreader/core/widgets/adaptive_list_detail_scaffold.dart';
import 'package:newsreader/core/widgets/empty_detail_placeholder.dart';
import 'package:newsreader/core/widgets/webview_flutter_article_web_view.dart';
import 'package:newsreader/features/account/domain/usecases/delete_account.dart';
import 'package:newsreader/features/account/domain/usecases/export_user_data.dart';
import 'package:newsreader/features/archive/presentation/screens/archive_screen.dart';
import 'package:newsreader/features/auth/presentation/cubit/login_cubit.dart';
import 'package:newsreader/features/auth/presentation/screens/login_screen.dart';
import 'package:newsreader/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:newsreader/features/inbox/domain/usecases/mark_article_as_read.dart';
import 'package:newsreader/features/inbox/presentation/screens/inbox_screen.dart';
import 'package:newsreader/features/reader/domain/usecases/toggle_favorite.dart';
import 'package:newsreader/features/reader/presentation/screens/reader_screen.dart';
import 'package:newsreader/features/settings/presentation/screens/settings_screen.dart';
import 'package:newsreader/features/sources/domain/usecases/get_source_articles.dart';
import 'package:newsreader/features/sources/domain/usecases/import_opml.dart';
import 'package:newsreader/features/sources/presentation/cubit/import_opml_cubit.dart';
import 'package:newsreader/features/sources/presentation/screens/add_source_screen.dart';
import 'package:newsreader/features/sources/presentation/screens/import_opml_screen.dart';
import 'package:newsreader/features/sources/presentation/screens/source_detail_screen.dart';
import 'package:newsreader/features/sources/presentation/screens/sources_screen.dart';
import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/features/summaries/domain/usecases/resolve_summary_articles.dart';
import 'package:newsreader/features/summaries/presentation/screens/summaries_screen.dart';
import 'package:newsreader/features/summaries/presentation/screens/summary_detail_screen.dart';
import 'package:newsreader/features/sync/domain/usecases/clear_local_user_data.dart';
import 'package:newsreader/features/sync/domain/usecases/sync_user_data.dart';
import 'package:newsreader/l10n/app_localizations.dart';
import 'package:newsreader/presentation/app/adaptive_shell.dart';

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

/// Builder de la ruta raíz de una branch de artículos (Inbox/Favoritos/
/// Archivo): en modo compact reproduce la lista a pantalla completa, en
/// modo expanded es el estado vacío del panel derecho del
/// `AdaptiveListDetailScaffold` (ver core `ShellRoute` de la branch).
Widget _articleListRoot(BuildContext context, Widget listScreen) {
  if (context.windowSizeClass == WindowSizeClass.compact) return listScreen;
  final l10n = AppLocalizations.of(context);
  return EmptyDetailPlaceholder(
    icon: Icons.article_outlined,
    title: l10n.commonSelectArticleTitle,
    subtitle: l10n.commonSelectArticleSubtitle,
  );
}

/// Builder del `ShellRoute` de una branch: en modo compact devuelve `child`
/// directamente (reproduce el push a pantalla completa existente); en modo
/// expanded arma el layout de dos paneles con [listScreen] siempre visible
/// a la izquierda. Ver design.md "Decisión 4" del change `optimize-ipad-ux`.
Widget _adaptiveBranchShell(
  BuildContext context,
  Widget listScreen,
  Widget child,
) {
  if (context.windowSizeClass == WindowSizeClass.compact) return child;
  return AdaptiveListDetailScaffold(list: listScreen, detail: child);
}

/// Ruta anidada del lector de artículo (más su sub-ruta `web`), reusada por
/// las 5 branches. [paramName] es el nombre del path parameter (`id` para
/// Inbox/Favoritos/Archivo, donde el artículo es la raíz del detalle;
/// `articleId` para Fuentes/Resúmenes, donde ya existe un `:id`/`:date`
/// propio en el path padre).
GoRoute _articleRoute({required String paramName}) {
  return GoRoute(
    path: 'article/:$paramName',
    builder: (context, state) => RouteExtraResolver<Article>(
      extra: state.extra,
      resolve: () => getIt<ArticleRepository>()
          .getArticleById(state.pathParameters[paramName]!),
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
              .getArticleById(state.pathParameters[paramName]!),
          onNotFound: (context) => context.go('/'),
          builder: (context, article) =>
              WebviewFlutterArticleWebView(url: article.articleUrl),
        ),
      ),
    ],
  );
}

/// Rama de tab cuyo detalle es directamente el lector de un artículo
/// (Inbox, Favoritos, Archivo): usa un `ShellRoute` propio para que el
/// `Navigator` interno de la branch pueda mostrarse a pantalla completa
/// (compact) o como panel derecho (expanded) sin perder su estado al
/// cruzar el breakpoint.
StatefulShellBranch articleListBranch({
  required String rootPath,
  required Widget Function() listScreenBuilder,
}) {
  return StatefulShellBranch(
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            _adaptiveBranchShell(context, listScreenBuilder(), child),
        routes: [
          GoRoute(
            path: rootPath,
            builder: (context, state) =>
                _articleListRoot(context, listScreenBuilder()),
            routes: [_articleRoute(paramName: 'id')],
          ),
        ],
      ),
    ],
  );
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
      path: '/settings',
      builder: (context, state) => SettingsScreen(
        exportUserData: getIt<ExportUserData>(),
        deleteAccount: getIt<DeleteAccount>(),
        clearLocalUserData: getIt<ClearLocalUserData>(),
        authClient: getIt<AuthClient>(),
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
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AdaptiveShell(navigationShell: navigationShell),
      branches: [
        articleListBranch(
          rootPath: '/',
          listScreenBuilder: () => const InboxScreen(),
        ),
        articleListBranch(
          rootPath: '/favorites',
          listScreenBuilder: () => const FavoritesScreen(),
        ),
        articleListBranch(
          rootPath: '/archive',
          listScreenBuilder: () => const ArchiveScreen(),
        ),
        StatefulShellBranch(
          routes: [
            ShellRoute(
              builder: (context, state, child) =>
                  _adaptiveBranchShell(context, const SourcesScreen(), child),
              routes: [
                GoRoute(
                  path: '/sources',
                  builder: (context, state) {
                    if (context.windowSizeClass == WindowSizeClass.compact) {
                      return const SourcesScreen();
                    }
                    final l10n = AppLocalizations.of(context);
                    return EmptyDetailPlaceholder(
                      icon: Icons.rss_feed_outlined,
                      title: l10n.sourcesSelectSourceTitle,
                      subtitle: l10n.sourcesSelectSourceSubtitle,
                    );
                  },
                  routes: [
                    GoRoute(
                      path: ':id',
                      builder: (context, state) => RouteExtraResolver<NewsSource>(
                        extra: state.extra,
                        resolve: () => getIt<SourceRepository>()
                            .getSourceById(state.pathParameters['id']!),
                        onNotFound: (context) => context.go('/'),
                        builder: (context, source) => SourceDetailScreen(
                          source: source,
                          getSourceArticles: getIt<GetSourceArticles>(),
                          feedSyncTrigger: getIt<FeedSyncTrigger>(),
                          syncUserData: getIt<SyncUserData>(),
                          observabilityClient: getIt<ObservabilityClient>(),
                          syncOnOpen:
                              state.uri.queryParameters['justAdded'] == 'true',
                        ),
                      ),
                      routes: [_articleRoute(paramName: 'articleId')],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            ShellRoute(
              builder: (context, state, child) => _adaptiveBranchShell(
                context,
                const SummariesScreen(),
                child,
              ),
              routes: [
                GoRoute(
                  path: '/summaries',
                  builder: (context, state) {
                    if (context.windowSizeClass == WindowSizeClass.compact) {
                      return const SummariesScreen();
                    }
                    final l10n = AppLocalizations.of(context);
                    return EmptyDetailPlaceholder(
                      icon: Icons.auto_awesome_outlined,
                      title: l10n.summariesSelectSummaryTitle,
                      subtitle: l10n.summariesSelectSummarySubtitle,
                    );
                  },
                  routes: [
                    GoRoute(
                      path: ':date',
                      builder: (context, state) => RouteExtraResolver<DailySummary>(
                        extra: state.extra,
                        resolve: () => getIt<SummaryRepository>()
                            .getById(state.pathParameters['date']!),
                        onNotFound: (context) => context.go('/'),
                        builder: (context, summary) => SummaryDetailScreen(
                          summary: summary,
                          resolveSummaryArticles: getIt<ResolveSummaryArticles>(),
                        ),
                      ),
                      routes: [_articleRoute(paramName: 'articleId')],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
