import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/core/widgets/chamfered_box.dart';
import 'package:newsreader/core/widgets/no_search_results_state.dart';
import 'package:newsreader/core/widgets/paper_texture.dart';
import 'package:newsreader/features/sources/presentation/cubit/sources_cubit.dart';
import 'package:newsreader/features/sources/presentation/widgets/delete_source_dialog.dart';
import 'package:newsreader/features/sources/presentation/widgets/edit_source_name_dialog.dart';
import 'package:newsreader/features/sources/presentation/widgets/source_icon.dart';
import 'package:newsreader/l10n/app_localizations.dart';

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
      body: PaperBackground(
        child: BlocBuilder<SourcesCubit, SourcesState>(
          builder: (context, state) {
            if (state is SourcesLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final loaded = state as SourcesLoaded;
            final sources = loaded.visibleSources;
            if (sources.isEmpty) {
              return loaded.searchQuery.isNotEmpty
                  ? const NoSearchResultsState()
                  : const _EmptySourcesState();
            }
            return ListView.builder(
              itemCount: sources.length,
              itemBuilder: (context, index) =>
                  _SourceTile(source: sources[index]),
            );
          },
        ),
      ),
      floatingActionButton: ChamferedBox(
        chamferSize: 14,
        child: FloatingActionButton(
          onPressed: () async {
            final addedSource = await context.push<NewsSource>(
              '/sources/add',
            );
            if (addedSource != null && context.mounted) {
              context.read<SourcesCubit>().loadSources();
              context.push(
                '/sources/${addedSource.id}?justAdded=true',
                extra: addedSource,
              );
            }
          },
          tooltip: AppLocalizations.of(context).sourcesAddSourceTooltip,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _EmptySourcesState extends StatelessWidget {
  const _EmptySourcesState();

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
              Icons.rss_feed,
              size: 64,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.sourcesEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.sourcesEmptySubtitle,
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
              label: Text(l10n.sourcesAddFirstSourceButton),
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
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _SourceAction.edit,
            child: Text(AppLocalizations.of(context).sourcesEditNameMenuItem),
          ),
          PopupMenuItem(
            value: _SourceAction.delete,
            child: Text(AppLocalizations.of(context).commonDelete),
          ),
        ],
      ),
    );
  }
}
