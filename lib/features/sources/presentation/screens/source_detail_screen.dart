import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/core/widgets/date_separator.dart';
import 'package:newsreader/features/inbox/presentation/widgets/article_inbox_tile.dart';
import 'package:newsreader/features/sources/domain/usecases/get_source_articles.dart';
import 'package:newsreader/features/sources/presentation/cubit/source_detail_cubit.dart';

class SourceDetailScreen extends StatelessWidget {
  final NewsSource source;
  final GetSourceArticles getSourceArticles;

  const SourceDetailScreen({
    super.key,
    required this.source,
    required this.getSourceArticles,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          SourceDetailCubit(getSourceArticles)..loadArticles(source.id),
      child: SourceDetailView(sourceName: source.name),
    );
  }
}

class SourceDetailView extends StatelessWidget {
  final String sourceName;

  const SourceDetailView({super.key, required this.sourceName});

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
      appBar: AppBar(title: Text(sourceName)),
      body: BlocBuilder<SourceDetailCubit, SourceDetailState>(
        builder: (context, state) {
          if (state is SourceDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final loaded = state as SourceDetailLoaded;
          if (loaded.articles.isEmpty) {
            return const _EmptySourceDetailState();
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
                onTap: () => context.push(
                  '/article/${article.id}',
                  extra: article,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptySourceDetailState extends StatelessWidget {
  const _EmptySourceDetailState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin publicaciones',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Aún no hay artículos de esta fuente.',
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
