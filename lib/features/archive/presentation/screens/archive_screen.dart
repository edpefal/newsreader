import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/widgets/date_separator.dart';
import 'package:newsreader/features/archive/presentation/cubit/archive_cubit.dart';
import 'package:newsreader/features/inbox/presentation/widgets/article_inbox_tile.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) => const ArchiveView();
}

class ArchiveView extends StatelessWidget {
  const ArchiveView({super.key});

  static List<Object> _buildGroupedItems(List<Article> articles) {
    final result = <Object>[];
    DateTime? lastDay;
    for (final article in articles) {
      final day = DateTime(
        article.publishedAt.year,
        article.publishedAt.month,
        article.publishedAt.day,
      );
      if (lastDay == null || day != lastDay) {
        result.add(day);
        lastDay = day;
      }
      result.add(article);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leídos')),
      body: BlocBuilder<ArchiveCubit, ArchiveState>(
        builder: (context, state) {
          if (state is ArchiveLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final loaded = state as ArchiveLoaded;
          if (loaded.articles.isEmpty) {
            return const _EmptyArchiveState();
          }
          final items = _buildGroupedItems(loaded.articles);
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              if (item is DateTime) {
                return DateSeparator(day: item);
              }
              final article = item as Article;
              return ArticleInboxTile(
                article: article,
                onTap: () async {
                  await context.push(
                    '/article/${article.id}',
                    extra: article,
                  );
                  if (context.mounted) {
                    context.read<ArchiveCubit>().loadArchive();
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

class _EmptyArchiveState extends StatelessWidget {
  const _EmptyArchiveState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.archive_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin artículos leídos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Los artículos leídos y no leídos se archivarán automáticamente.',
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
