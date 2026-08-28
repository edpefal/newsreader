import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/di/injection.dart';
import 'package:newsreader/core/utils/window_size_class.dart';
import 'package:newsreader/features/archive/presentation/cubit/archive_cubit.dart';
import 'package:newsreader/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:newsreader/features/inbox/presentation/cubit/inbox_cubit.dart';
import 'package:newsreader/features/sources/presentation/cubit/sources_cubit.dart';
import 'package:newsreader/features/summaries/presentation/cubit/summaries_cubit.dart';
import 'package:newsreader/l10n/app_localizations.dart';
import 'package:newsreader/presentation/app/branch_root_paths.dart';

/// Índices de tabs cuyo contenido soporta búsqueda: Inbox, Favoritos y
/// Leídos (capability `article-search`), y Fuentes (capability
/// `source-search`). Resúmenes queda fuera de alcance.
const _searchableTabIndices = {0, 1, 2, 3};

/// Shell de navegación de la app: `NavigationRail` permanente en anchos
/// expanded (≥840dp, ver `WindowSizeClass`), `NavigationDrawer` modal en
/// anchos compact, igual que el comportamiento previo a este cambio.
class AdaptiveShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AdaptiveShell({super.key, required this.navigationShell});

  @override
  State<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends State<AdaptiveShell> {
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
    final appBar = AppBar(
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
                Image.asset('assets/reevo_logo.png', width: 20, height: 20),
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
    );

    if (context.windowSizeClass == WindowSizeClass.expanded) {
      return Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            _AdaptiveNavigationRail(
              currentIndex: currentIndex,
              onDestinationSelected: (index) =>
                  _onDestinationSelected(context, index),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: widget.navigationShell),
          ],
        ),
      );
    }

    // En compact, una pantalla de detalle (artículo, fuente o resumen) se
    // empuja a pantalla completa reemplazando la lista de la tab (ver
    // `_adaptiveBranchShell` en router.dart). En ese caso el chrome del
    // shell principal (AppBar con logo/búsqueda + drawer) debe ocultarse
    // para que solo se vea el AppBar propio de esa pantalla de detalle.
    final isAtBranchRoot = branchRootPaths.contains(
      GoRouterState.of(context).uri.path,
    );

    return Scaffold(
      appBar: isAtBranchRoot ? appBar : null,
      body: widget.navigationShell,
      drawer: isAtBranchRoot
          ? _AppNavigationDrawer(
              currentIndex: currentIndex,
              onDestinationSelected: (index) =>
                  _onDestinationSelected(context, index),
            )
          : null,
    );
  }
}

class _AdaptiveNavigationRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const _AdaptiveNavigationRail({
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Las 5 destinations + el ícono de Ajustes no siempre entran en el alto
    // disponible (ej. un iPhone grande en landscape, mucho más bajo que un
    // iPad): `NavigationRail` no hace scroll interno por su cuenta, así que
    // se envuelve en un `SingleChildScrollView` con una altura mínima igual
    // a la disponible -- si entra, se ve idéntico (el `trailing` sigue
    // pegado abajo gracias al `Expanded` interno); si no entra, se puede
    // scrollear en vez de desbordar.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: l10n.navSettings,
                      onPressed: () => context.push('/settings'),
                    ),
                  ),
                ),
              ),
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.inbox_outlined),
                  selectedIcon: const Icon(Icons.inbox),
                  label: BlocBuilder<InboxCubit, InboxState>(
                    builder: (context, state) {
                      final count = state is InboxLoaded
                          ? state.articles.length
                          : 0;
                      if (count == 0) return Text(l10n.navInbox);
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(l10n.navInbox),
                          const SizedBox(width: 4),
                          Badge.count(count: count),
                        ],
                      );
                    },
                  ),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.star_outline),
                  selectedIcon: const Icon(Icons.star),
                  label: Text(l10n.navFavorites),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.mark_email_read_outlined),
                  selectedIcon: const Icon(Icons.mark_email_read),
                  label: Text(l10n.navArchive),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.rss_feed_outlined),
                  selectedIcon: const Icon(Icons.rss_feed),
                  label: Text(l10n.navSources),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.auto_awesome_outlined),
                  selectedIcon: const Icon(Icons.auto_awesome),
                  label: Text(l10n.navSummaries),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppNavigationDrawer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const _AppNavigationDrawer({
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return NavigationDrawer(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        Navigator.pop(context);
        onDestinationSelected(index);
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.appTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
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
      ],
    );
  }
}
