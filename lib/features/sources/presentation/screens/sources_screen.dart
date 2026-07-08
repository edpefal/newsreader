import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/features/sources/presentation/cubit/sources_cubit.dart';
import 'package:newsreader/features/sources/presentation/widgets/delete_source_dialog.dart';
import 'package:newsreader/features/sources/presentation/widgets/edit_source_name_dialog.dart';
import 'package:newsreader/features/sources/presentation/widgets/source_icon.dart';

class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context) => const SourcesView();
}

class SourcesView extends StatelessWidget {
  const SourcesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fuentes')),
      body: BlocBuilder<SourcesCubit, SourcesState>(
        builder: (context, state) {
          if (state is SourcesLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final sources = (state as SourcesLoaded).sources;
          if (sources.isEmpty) {
            return const _EmptySourcesState();
          }
          return ListView.builder(
            itemCount: sources.length,
            itemBuilder: (context, index) =>
                _SourceTile(source: sources[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await context.push<bool>('/sources/add');
          if (added == true && context.mounted) {
            context.read<SourcesCubit>().loadSources();
          }
        },
        tooltip: 'Agregar newsletter',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptySourcesState extends StatelessWidget {
  const _EmptySourcesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.rss_feed,
              size: 64,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Aún no tienes newsletters',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega tu primer newsletter para empezar a leer.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                final added = await context.push<bool>('/sources/add');
                if (added == true && context.mounted) {
                  context.read<SourcesCubit>().loadSources();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Agregar mi primer newsletter'),
            ),
          ],
        ),
      ),
    );
  }
}

enum _SourceAction { edit, delete }

class _SourceTile extends StatelessWidget {
  final NewsSource source;

  const _SourceTile({required this.source});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SourceIcon(iconUrl: source.iconUrl, name: source.name),
      title: Text(source.name),
      subtitle: source.author != null ? Text(source.author!) : null,
      onTap: () => context.push('/sources/${source.id}', extra: source),
      trailing: PopupMenuButton<_SourceAction>(
        onSelected: (action) {
          if (action == _SourceAction.edit) {
            showDialog(
              context: context,
              builder: (_) => EditSourceNameDialog(
                initialName: source.name,
                onSave: (name) => context
                    .read<SourcesCubit>()
                    .updateSourceName(source.id, name),
              ),
            );
          } else {
            showDialog(
              context: context,
              builder: (_) => DeleteSourceDialog(
                sourceName: source.name,
                onConfirm: () =>
                    context.read<SourcesCubit>().deleteSource(source.id),
              ),
            );
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: _SourceAction.edit,
            child: Text('Editar nombre'),
          ),
          PopupMenuItem(
            value: _SourceAction.delete,
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
