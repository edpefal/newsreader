import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/widgets/date_separator.dart';
import 'package:newsreader/features/inbox/presentation/cubit/inbox_cubit.dart';
import 'package:newsreader/features/inbox/presentation/widgets/article_inbox_tile.dart';

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
      if (state is InboxLoaded && state.readArticleId == null) {
        _flatItems = _buildFlatItems(state.articles);
      }
    }
  }

  // Construye la lista plana intercalando separadores de fecha.
  static List<_InboxListItem> _buildFlatItems(List<Article> articles) {
    final result = <_InboxListItem>[];
    DateTime? lastDay;
    for (final article in articles) {
      final day = DateTime(
        article.publishedAt.year,
        article.publishedAt.month,
        article.publishedAt.day,
      );
      if (lastDay == null || day != lastDay) {
        result.add(_DateHeaderItem(day));
        lastDay = day;
      }
      result.add(_ArticleListItem(article));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: BlocConsumer<InboxCubit, InboxState>(
        listenWhen: (_, curr) => curr is InboxLoaded,
        listener: (context, state) {
          final loaded = state as InboxLoaded;
          if (loaded.readArticleId != null) {
            _animateDismiss(loaded.readArticleId!);
          } else {
            setState(() {
              _flatItems = _buildFlatItems(loaded.articles);
              _listKey = GlobalKey<AnimatedListState>();
            });
          }
        },
        buildWhen: (_, curr) =>
            curr is InboxLoading ||
            (curr is InboxLoaded && curr.readArticleId == null),
        builder: (context, state) {
          if (state is InboxLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final loaded = state as InboxLoaded;

          if (_flatItems.isEmpty) {
            final emptyWidget = loaded.hasSources
                ? const _UpToDateState()
                : const _OnboardingState();
            return RefreshIndicator(
              onRefresh: () => _onRefresh(context),
              child: LayoutBuilder(
                builder: (_, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(height: constraints.maxHeight, child: emptyWidget),
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
                    onTap: () async {
                      await context.push(
                        '/article/${article.id}',
                        extra: article,
                      );
                      if (context.mounted) {
                        context.read<InboxCubit>().loadArticlesAfterReading(article.id);
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _onSwipeDismiss(BuildContext context, Article article) {
    final articleIdx = _flatItems.indexWhere(
      (item) => item is _ArticleListItem && item.article.id == article.id,
    );
    if (articleIdx == -1) return;

    int? headerIdx;
    if (articleIdx > 0 && _flatItems[articleIdx - 1] is _DateHeaderItem) {
      final nextIsArticleInSameGroup = articleIdx + 1 < _flatItems.length &&
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
      final nextIsArticleInSameGroup = articleIdx + 1 < _flatItems.length &&
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
  final result = await context.read<InboxCubit>().syncAndReload();
  if (!context.mounted) return;
  if (result.isNetworkError) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sin conexión. Los artículos descargados siguen disponibles.'),
      ),
    );
  } else if (result.failedSourceIds.isNotEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${result.failedSourceIds.length} fuente(s) no pudieron sincronizarse.',
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets internos
// ---------------------------------------------------------------------------

class _OnboardingState extends StatelessWidget {
  const _OnboardingState();

  @override
  Widget build(BuildContext context) {
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
              'Bienvenido a Newsletter Hub',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tu espacio para leer newsletters fuera del email.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                await context.push('/sources/add');
                if (context.mounted) {
                  context.read<InboxCubit>().loadArticles();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Agregar tu primer newsletter'),
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
              'Estás al día',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Desliza para actualizar.',
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
