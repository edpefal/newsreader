import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:newsreader/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:newsreader/features/inbox/presentation/widgets/article_inbox_tile.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) => const FavoritesView();
}

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: BlocBuilder<FavoritesCubit, FavoritesState>(
        builder: (context, state) {
          if (state is FavoritesLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final loaded = state as FavoritesLoaded;
          if (loaded.articles.isEmpty) {
            return const _EmptyFavoritesState();
          }
          return ListView.builder(
            itemCount: loaded.articles.length,
            itemBuilder: (context, index) {
              final article = loaded.articles[index];
              return ArticleInboxTile(
                article: article,
                onTap: () async {
                  await context.push(
                    '/article/${article.id}',
                    extra: article,
                  );
                  if (context.mounted) {
                    context.read<FavoritesCubit>().loadFavorites();
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyFavoritesState extends StatelessWidget {
  const _EmptyFavoritesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin favoritos aún',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Abre un artículo y toca la estrella para guardarlo aquí.',
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
