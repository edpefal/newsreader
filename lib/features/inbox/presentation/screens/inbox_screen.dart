import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:newsreader/features/inbox/presentation/cubit/inbox_cubit.dart';
import 'package:newsreader/features/inbox/presentation/widgets/article_inbox_tile.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const InboxView();
  }
}

class InboxView extends StatelessWidget {
  const InboxView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: BlocBuilder<InboxCubit, InboxState>(
        builder: (context, state) {
          if (state is InboxLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final loaded = state as InboxLoaded;
          if (loaded.articles.isEmpty) {
            return loaded.hasSources
                ? const _UpToDateState()
                : const _OnboardingState();
          }
          return ListView.builder(
            itemCount: loaded.articles.length,
            itemBuilder: (context, index) =>
                ArticleInboxTile(article: loaded.articles[index]),
          );
        },
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
