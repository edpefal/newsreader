import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:newsreader/features/archive/domain/usecases/get_archive.dart';
import 'package:newsreader/features/archive/presentation/cubit/archive_cubit.dart';
import 'package:newsreader/features/inbox/presentation/widgets/article_inbox_tile.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ArchiveCubit(GetIt.instance<GetArchive>())..loadArchive(),
      child: const ArchiveView(),
    );
  }
}

class ArchiveView extends StatelessWidget {
  const ArchiveView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archivados')),
      body: BlocBuilder<ArchiveCubit, ArchiveState>(
        builder: (context, state) {
          if (state is ArchiveLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final loaded = state as ArchiveLoaded;
          if (loaded.articles.isEmpty) {
            return const _EmptyArchiveState();
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
              'Sin artículos archivados',
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
