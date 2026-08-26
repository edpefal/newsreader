import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/core/utils/window_size_class.dart';
import 'package:newsreader/core/widgets/date_separator.dart';
import 'package:newsreader/core/widgets/no_search_results_state.dart';
import 'package:newsreader/core/widgets/paper_texture.dart';
import 'package:newsreader/features/inbox/presentation/cubit/inbox_cubit.dart';
import 'package:newsreader/features/inbox/presentation/widgets/article_inbox_tile.dart';
import 'package:newsreader/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Modelo interno de la lista plana (artículos + separadores de fecha)
// ---------------------------------------------------------------------------

sealed class _InboxListItem {}

final class _DateHeaderItem extends _InboxListItem {
  final DateTime day; // normalizado a medianoche
  _DateHeaderItem(this.day);
}

final class _ArticleListItem extends _InboxListItem {
  final Article article;
  _ArticleListItem(this.article);
}

// ---------------------------------------------------------------------------
// Screen / View
// ---------------------------------------------------------------------------

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const InboxView();
  }
}

class InboxView extends StatefulWidget {
  const InboxView({super.key});

  @override
  State<InboxView> createState() => _InboxViewState();
}

class _InboxViewState extends State<InboxView> {
  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<_InboxListItem> _flatItems = [];
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final state = context.read<InboxCubit>().state;
      // `readArticleId` es una señal transitoria para animar la salida de
      // un artículo recién leído en una instancia de `InboxView` que ya
      // estaba montada -- no significa que `visibleArticles` esté
      // desactualizada (`_reload` ya vuelve a consultar el repositorio, que
      // excluye el artículo leído). Si se ignora acá, una instancia nueva
      // (por ejemplo, tras remontarse tras un cambio de ancho/rotación
      // mientras ese flag seguía seteado del último artículo leído en modo
      // split) arranca con la lista vacía en vez de la lista real.
      if (state is InboxLoaded) {
        _flatItems = _buildFlatItems(state.visibleArticles);
      }
    }
  }

  // Construye la lista plana intercalando separadores de fecha.
  static List<_InboxListItem> _buildFlatItems(List<Article> articles) {
    final result = <_InboxListItem>[];
    DateTime? lastDay;
    for (final article in articles) {
      final localPublishedAt = article.publishedAt.toLocal();
      final day = DateTime(
        localPublishedAt.year,
        localPublishedAt.month,
        localPublishedAt.day,
      );
      if (lastDay == null || day != lastDay) {
        result.add(_DateHeaderItem(day));
        lastDay = day;
      }
      result.add(_ArticleListItem(article));
    }
    return result;
  }

  /// Compara los IDs de artículo actualmente en `_flatItems` contra
  /// [newArticles], en el mismo orden. Usado por el listener para distinguir
  /// una recarga que sí cambió el contenido de la lista (requiere
  /// reconstruir `_flatItems`/`_listKey`) de una que solo actualizó
  /// `openArticleId` (resaltado).
  bool _articleIdsChanged(List<Article> newArticles) {
    final currentIds = _flatItems
        .whereType<_ArticleListItem>()
        .map((item) => item.article.id)
        .toList();
    final newIds = newArticles.map((a) => a.id).toList();
    if (currentIds.length != newIds.length) return true;
    for (var i = 0; i < currentIds.length; i++) {
      if (currentIds[i] != newIds[i]) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: Column(
          children: [
            const _BackgroundSyncIndicator(),
            Expanded(child: _buildInboxBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildInboxBody(BuildContext context) {
    return BlocConsumer<InboxCubit, InboxState>(
      listenWhen: (_, curr) => curr is InboxLoaded,
      listener: (context, state) {
        final loaded = state as InboxLoaded;
        if (loaded.readArticleId != null) {
          _animateDismiss(loaded.readArticleId!);
        } else if (_articleIdsChanged(loaded.visibleArticles)) {
          // Solo se reconstruye `_flatItems`/`_listKey` cuando cambió el
          // contenido real de la lista. Si lo único que cambió fue
          // `openArticleId` (resaltar la selección abierta), no hace falta
          // -- el `builder` de abajo ya se vuelve a ejecutar con el estado
          // nuevo (ver `buildWhen`) y refleja el resaltado sin perder la
          // posición de scroll con un `_listKey` nuevo.
          setState(() {
            _flatItems = _buildFlatItems(loaded.visibleArticles);
            _listKey = GlobalKey<AnimatedListState>();
          });
        }
      },
      buildWhen: (prev, curr) {
        if (curr is InboxLoading) return true;
        if (curr is! InboxLoaded) return false;
        if (curr.readArticleId == null) return true;
        // Al cerrar/reemplazar la selección abierta (`readArticleId` seteado
        // por `selectArticle`/`closeOpenArticle`), igual hace falta
        // reconstruir si `openArticleId` cambió: si no, la fila del
        // artículo recién seleccionado no se resalta hasta el próximo
        // rebuild ajeno a este cambio.
        final prevOpenArticleId = prev is InboxLoaded ? prev.openArticleId : null;
        return prevOpenArticleId != curr.openArticleId;
      },
      builder: (context, state) {
        if (state is InboxLoading) {
          final l10n = AppLocalizations.of(context);
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                if (state.isSyncing) ...[
                  const SizedBox(height: 16),
                  Text(l10n.inboxSyncingSources),
                ],
              ],
            ),
          );
        }
        final loaded = state as InboxLoaded;

        if (_flatItems.isEmpty) {
          final emptyWidget = loaded.searchQuery.isNotEmpty
              ? const NoSearchResultsState()
              : loaded.hasSources
                  ? const _UpToDateState()
                  : const _OnboardingState();
          return RefreshIndicator(
            onRefresh: () => _onRefresh(context),
            child: LayoutBuilder(
              builder: (_, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: emptyWidget,
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _onRefresh(context),
          child: AnimatedList(
            key: _listKey,
            initialItemCount: _flatItems.length,
            itemBuilder: (context, index, animation) {
              final item = _flatItems[index];
              if (item is _DateHeaderItem) {
                return DateSeparator(day: item.day);
              }
              final article = (item as _ArticleListItem).article;
              return Dismissible(
                key: ValueKey(article.id),
                direction: DismissDirection.endToStart,
                background: const _SwipeReadBackground(),
                onDismissed: (_) => _onSwipeDismiss(context, article),
                child: ArticleInboxTile(
                  article: article,
                  isOpen: article.id == loaded.openArticleId,
                  onTap: () {
                    final cubit = context.read<InboxCubit>();
                    if (context.windowSizeClass == WindowSizeClass.expanded) {
                      // En modo split la lista sigue visible: el artículo
                      // se resalta como selección abierta en vez de
                      // desaparecer; solo se archiva cuando el usuario lo
                      // cierra explícitamente (chevron de volver o al
                      // seleccionar otro artículo, ver `selectArticle`).
                      context.go('/article/${article.id}', extra: article);
                      cubit.selectArticle(article.id);
                      return;
                    }
                    context.push('/article/${article.id}', extra: article).then((_) {
                      if (context.mounted) {
                        cubit.loadArticlesAfterReading(article.id);
                      }
                    });
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _onSwipeDismiss(BuildContext context, Article article) {
    final articleIdx = _flatItems.indexWhere(
      (item) => item is _ArticleListItem && item.article.id == article.id,
    );
    if (articleIdx == -1) return;

    int? headerIdx;
    if (articleIdx > 0 && _flatItems[articleIdx - 1] is _DateHeaderItem) {
      final nextIsArticleInSameGroup =
          articleIdx + 1 < _flatItems.length &&
          _flatItems[articleIdx + 1] is _ArticleListItem;
      if (!nextIsArticleInSameGroup) {
        headerIdx = articleIdx - 1;
      }
    }

    _flatItems.removeAt(articleIdx);
    if (headerIdx != null) _flatItems.removeAt(headerIdx);

    // Dismissible ya animó la salida horizontal; solo sincronizamos el conteo
    // del AnimatedList sin animación visible.
    _listKey.currentState?.removeItem(
      articleIdx,
      (_, __) => const SizedBox.shrink(),
      duration: Duration.zero,
    );
    if (headerIdx != null) {
      _listKey.currentState?.removeItem(
        headerIdx,
        (_, __) => const SizedBox.shrink(),
        duration: Duration.zero,
      );
    }

    if (_flatItems.isEmpty) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() {});
      });
    }

    context.read<InboxCubit>().markAsRead(article.id);
  }

  void _animateDismiss(String articleId) {
    // Buscar el artículo en la lista plana.
    final articleIdx = _flatItems.indexWhere(
      (item) => item is _ArticleListItem && item.article.id == articleId,
    );
    if (articleIdx == -1) return;

    final removedArticle = (_flatItems[articleIdx] as _ArticleListItem).article;

    // El header precede al artículo: si no hay otro artículo en el mismo
    // grupo después de este, el header queda huérfano y también se elimina.
    int? headerIdx;
    if (articleIdx > 0 && _flatItems[articleIdx - 1] is _DateHeaderItem) {
      final nextIsArticleInSameGroup =
          articleIdx + 1 < _flatItems.length &&
          _flatItems[articleIdx + 1] is _ArticleListItem;
      if (!nextIsArticleInSameGroup) {
        headerIdx = articleIdx - 1;
      }
    }

    // Actualizar la lista plana primero (índice mayor → menor para no desplazar).
    _flatItems.removeAt(articleIdx);
    if (headerIdx != null) _flatItems.removeAt(headerIdx);

    // Animar la salida del artículo (deslizamiento lateral).
    _listKey.currentState?.removeItem(
      articleIdx,
      (ctx, anim) => _buildSlidingTile(removedArticle, anim),
      duration: const Duration(milliseconds: 350),
    );

    // Eliminar el header sin animación (si quedó huérfano).
    if (headerIdx != null) {
      _listKey.currentState?.removeItem(
        headerIdx,
        (_, __) => const SizedBox.shrink(),
        duration: Duration.zero,
      );
    }

    // Si ya no quedan artículos, disparar rebuild para mostrar estado vacío.
    if (_flatItems.isEmpty) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() {});
      });
    }
  }

  Widget _buildSlidingTile(Article article, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeIn)),
      child: FadeTransition(
        opacity: animation,
        child: ArticleInboxTile(article: article),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<void> _onRefresh(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final result = await context.read<InboxCubit>().syncAndReload();
  if (!context.mounted) return;
  if (result.isNetworkError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.inboxOfflineSyncMessage)),
    );
  } else if (result.failedSourceIds.isNotEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.inboxSourcesFailedToSync(result.failedSourceIds.length),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets internos
// ---------------------------------------------------------------------------

/// Indicador no invasivo de que hay una sincronización en curso al volver
/// del background: a diferencia de `InboxLoading`, no reemplaza el
/// contenido ya cargado en pantalla.
class _BackgroundSyncIndicator extends StatelessWidget {
  const _BackgroundSyncIndicator();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InboxCubit, InboxState>(
      buildWhen: (prev, curr) =>
          (curr is InboxLoaded && curr.isSyncingInBackground) ||
          (prev is InboxLoaded && prev.isSyncingInBackground),
      builder: (context, state) {
        final isSyncing = state is InboxLoaded && state.isSyncingInBackground;
        if (!isSyncing) return const SizedBox.shrink();
        return const LinearProgressIndicator();
      },
    );
  }
}

class _OnboardingState extends StatelessWidget {
  const _OnboardingState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.inboxOnboardingTitle,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.inboxOnboardingSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                final addedSource =
                    await context.push<NewsSource>('/sources/add');
                if (context.mounted) {
                  context.read<InboxCubit>().loadArticles();
                }
                if (addedSource == null || !context.mounted) return;
                // Se espera la vuelta de la pantalla de detalle (que
                // sincroniza y trae los artículos de la fuente recién
                // agregada) para recargar el Inbox recién ahí -- si se
                // recargara antes de este await, la fuente todavía no
                // tendría artículos y el Inbox quedaría desactualizado
                // hasta el próximo pull-to-refresh.
                await context.push(
                  '/sources/${addedSource.id}?justAdded=true',
                  extra: addedSource,
                );
                if (context.mounted) {
                  context.read<InboxCubit>().loadArticles();
                }
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.inboxOnboardingAddFirstSourceButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeReadBackground extends StatelessWidget {
  const _SwipeReadBackground();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.teal,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.only(right: 20),
          child: Icon(Icons.check, color: Colors.white),
        ),
      ),
    );
  }
}

class _UpToDateState extends StatelessWidget {
  const _UpToDateState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.inboxUpToDateTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.inboxUpToDateSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
