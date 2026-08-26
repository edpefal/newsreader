import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/core/feed/feed_sync_trigger.dart';
import 'package:newsreader/core/navigation/route_path.dart';
import 'package:newsreader/core/observability/observability_client.dart';
import 'package:newsreader/core/widgets/date_separator.dart';
import 'package:newsreader/features/inbox/presentation/widgets/article_inbox_tile.dart';
import 'package:newsreader/features/sources/domain/usecases/get_source_articles.dart';
import 'package:newsreader/features/sources/presentation/cubit/source_detail_cubit.dart';
import 'package:newsreader/features/sync/domain/usecases/sync_user_data.dart';
import 'package:newsreader/l10n/app_localizations.dart';

class SourceDetailScreen extends StatelessWidget {
  final NewsSource source;
  final GetSourceArticles getSourceArticles;
  final FeedSyncTrigger feedSyncTrigger;
  final SyncUserData syncUserData;
  final ObservabilityClient observabilityClient;

  /// `true` cuando se llega a esta pantalla inmediatamente después de
  /// agregar la fuente: dispara una sincronización antes de mostrar los
  /// artículos, en vez de solo leer lo que ya haya localmente.
  final bool syncOnOpen;

  const SourceDetailScreen({
    super.key,
    required this.source,
    required this.getSourceArticles,
    required this.feedSyncTrigger,
    required this.syncUserData,
    required this.observabilityClient,
    this.syncOnOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = SourceDetailCubit(
          getSourceArticles,
          feedSyncTrigger,
          syncUserData,
          observabilityClient,
        );
        if (syncOnOpen) {
          cubit.syncAndLoadArticles(source.id);
        } else {
          cubit.loadArticles(source.id);
        }
        return cubit;
      },
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
      final localPublishedAt = article.publishedAt.toLocal();
      final day = DateTime(
        localPublishedAt.year,
        localPublishedAt.month,
        localPublishedAt.day,
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
                onTap: () {
                  final basePath = GoRouterState.of(context).uri.path;
                  openDetailRoute(
                    context: context,
                    path: joinRoutePath(basePath, 'article/${article.id}'),
                    extra: article,
                    onOpened: () {},
                  );
                },
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
    final l10n = AppLocalizations.of(context);
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
              l10n.sourceDetailEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.sourceDetailEmptySubtitle,
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
