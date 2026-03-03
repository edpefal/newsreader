import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/features/inbox/presentation/cubit/inbox_cubit.dart';
import 'package:newsreader/features/inbox/presentation/widgets/article_inbox_tile.dart';

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
  List<Article> _items = [];
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final state = context.read<InboxCubit>().state;
      if (state is InboxLoaded && state.readArticleId == null) {
        _items = List.of(state.articles);
      }
    }
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
            final index = _items.indexWhere((a) => a.id == loaded.readArticleId);
            if (index != -1) {
              final removed = _items.removeAt(index);
              _listKey.currentState?.removeItem(
                index,
                (ctx, animation) => _buildSlidingTile(removed, animation),
                duration: const Duration(milliseconds: 350),
              );
              if (_items.isEmpty) {
                Future.delayed(const Duration(milliseconds: 400), () {
                  if (mounted) setState(() {});
                });
              }
            }
          } else {
            setState(() {
              _items = List.of(loaded.articles);
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

          if (_items.isEmpty) {
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
              initialItemCount: _items.length,
              itemBuilder: (context, index, animation) {
                final article = _items[index];
                return ArticleInboxTile(
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
                );
              },
            ),
          );
        },
      ),
    );
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
